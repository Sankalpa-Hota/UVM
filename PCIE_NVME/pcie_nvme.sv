`timescale 1ns/1ps
// PCIe (Gen4) Memory Write TLP -> NVMe hand-off (simple version): store the TLP, check it, then forward it.
//  BAR0 = 0x8000_0000:  +0x1000..0x101F doorbells (SQy tail at 0x1000 + 8y, CQy head at 0x1004 + 8y, DSTRD = 0)
//                       +0x2000..0x2FFF data window (4 KB) -> NVMe write port
module pcie_nvme #(parameter logic [31:0] BAR = 32'h8000_0000) (
   input  logic        clk,
   input  logic        rst_n,
   // PCIe side: one DWORD per beat, sop on header DW0, eop on the last DW
   input  logic        tlp_valid,
   output logic        tlp_ready,
   input  logic        tlp_sop,
   input  logic        tlp_eop,
   input  logic [31:0] tlp_data,
   // NVMe side: data writes into the window
   output logic        nvme_valid,
   input  logic        nvme_ready,
   output logic [11:0] nvme_addr,        // byte offset inside the 4 KB window
   output logic [31:0] nvme_data,
   output logic [3:0]  nvme_be,
   output logic        nvme_last,
   // NVMe side: doorbell writes
   output logic        db_valid,
   output logic        db_cq,            // 0 = SQ tail doorbell, 1 = CQ head doorbell
   output logic [1:0]  db_qid,
   output logic [15:0] db_value,
   // errors the PCIe transaction layer would report
   output logic        err_valid,
   output logic [1:0]  err_code);        // 1 = malformed, 2 = unsupported request, 3 = unmapped address

  localparam int MAXDW = 4 + 32;         // biggest TLP we accept: 4 header DW + 32 payload DW (MPS = 128 bytes)
  typedef enum logic [2:0] {RECV, CHECK, SEND, DOORBELL, ERROR} state_t;
  state_t state;

  logic [31:0] buffer [MAXDW];
  logic [5:0]  count;                    // DWs received
  logic        overflow;
  logic [5:0]  i;                        // DW being forwarded

  // header fields (PCIe Base Spec: DW0 Fmt[31:29] Type[28:24] Length[9:0]; DW1 ReqID[31:16] Tag[15:8] LastBE[7:4] FirstBE[3:0])
  logic [2:0]  fmt;     assign fmt      = buffer[0][31:29];
  logic [4:0]  typ;     assign typ      = buffer[0][28:24];
  logic [9:0]  len;     assign len      = buffer[0][9:0];
  logic [3:0]  first_be;assign first_be = buffer[1][3:0];
  logic [3:0]  last_be; assign last_be  = buffer[1][7:4];
  logic [2:0]  hdr_dw;  assign hdr_dw   = fmt[0] ? 3'd4 : 3'd3;                   // Fmt[0] = 4-DW header (64-bit address)
  logic [63:0] addr;    assign addr     = fmt[0] ? {buffer[2], buffer[3][31:2], 2'b00} : {32'h0, buffer[2][31:2], 2'b00};
  logic [10:0] len_dw;  assign len_dw   = (len == 0) ? 11'd1024 : {1'b0, len};    // Length 0 means 1024 DW

  assign tlp_ready = (state == RECV);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= RECV;  count <= 0;  overflow <= 0;  i <= 0;
      nvme_valid <= 0;  db_valid <= 0;  err_valid <= 0;  err_code <= 0;
      nvme_addr <= 0;  nvme_data <= 0;  nvme_be <= 0;  nvme_last <= 0;  db_cq <= 0;  db_qid <= 0;  db_value <= 0;
    end else begin
      db_valid  <= 0;
      err_valid <= 0;
      case (state)
        RECV: if (tlp_valid) begin                                   // 1. store every DW of the TLP
          logic [5:0] idx;
          idx = tlp_sop ? 6'd0 : count;                              // a new TLP starts at buffer[0]
          if (idx < MAXDW) buffer[idx] <= tlp_data;
          overflow <= (tlp_sop ? 1'b0 : overflow) | (idx >= MAXDW);
          count <= idx + 1;
          if (tlp_eop) state <= CHECK;
        end
        CHECK: begin                                                 // 2. check it like the transaction layer
          if (!(fmt[1] && typ == 5'b00000)) begin                    // only Memory Write (Fmt 01x, Type 00000) is supported
            err_code <= 2;  state <= ERROR;
          end else if (overflow || (count - hdr_dw) != len_dw) begin // payload must match Length
            err_code <= 1;  state <= ERROR;
          end else if ({1'b0, addr[11:0]} + 4 * len_dw > 4096) begin // must not cross a 4 KB boundary
            err_code <= 1;  state <= ERROR;
          end else if (addr >= BAR + 32'h2000 && addr < BAR + 32'h3000) begin
            i <= 0;  state <= SEND;                                  // data window
          end else if (addr >= BAR + 32'h1000 && addr < BAR + 32'h1020 && len_dw == 1) begin
            state <= DOORBELL;                                       // doorbell register
          end else begin
            err_code <= 3;  state <= ERROR;                          // nothing decodes this address
          end
        end
        SEND: begin                                                  // 3a. forward payload DWs to the NVMe window
          if (!nvme_valid || nvme_ready) begin
            if (nvme_valid && nvme_last) begin
              nvme_valid <= 0;  count <= 0;  state <= RECV;
            end else begin
              nvme_valid <= 1;
              nvme_addr  <= addr[11:0] + 4 * i;
              nvme_data  <= buffer[hdr_dw + i];
              nvme_be    <= (i == 0) ? first_be : (i == len_dw - 1) ? last_be : 4'hF;
              nvme_last  <= (i == len_dw - 1);
              i <= i + 1;
            end
          end
        end
        DOORBELL: begin                                              // 3b. doorbell: which queue, which value
          db_valid <= 1;
          db_cq    <= addr[2];                                       // +0 SQ tail, +4 CQ head
          db_qid   <= addr[4:3];                                     // 8 bytes per queue pair
          db_value <= buffer[hdr_dw][15:0];
          count <= 0;  state <= RECV;
        end
        ERROR: begin                                                 // 3c. report and drop the TLP
          err_valid <= 1;
          count <= 0;  state <= RECV;
        end
        default: state <= RECV;
      endcase
    end
  end
endmodule
