`timescale 1ns/1ps
module uart_rx (
   input  logic        clk,
   input  logic        rst_n,
   input  logic [7:0]  awaddr,
   input  logic        awvalid,
   output logic        awready,
   input  logic [31:0] wdata,
   input  logic        wvalid,
   output logic        wready,
   output logic [1:0]  bresp,
   output logic        bvalid,
   input  logic        bready,
   input  logic [7:0]  araddr,
   input  logic        arvalid,
   output logic        arready,
   output logic [31:0] rdata,
   output logic [1:0]  rresp,
   output logic        rvalid,
   input  logic        rready,
   input  logic        rx,
   output logic        rx_valid,
   output logic [7:0]  rx_byte);

  localparam logic [1:0] OKAY   = 2'b00;
  localparam logic [1:0] SLVERR = 2'b10;

  typedef enum logic [2:0] {IDLE, START, DATA, PARITY, STOP, BREAK} state_t;
  state_t state;

  logic        en, parity_odd;
  logic [15:0] baud_div;
  logic [15:0] rx_cnt;
  logic [7:0]  parity_cnt, frame_cnt;
  logic [7:0]  rx_data;

  logic        rx_q1, rx_s;
  logic [15:0] cnt;
  logic [2:0]  bit_idx;
  logic [7:0]  shreg;
  logic        par_bit;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      awready    <= 1'b0;
      wready     <= 1'b0;
      bvalid     <= 1'b0;
      bresp      <= OKAY;
      en         <= 1'b0;
      parity_odd <= 1'b0;
      baud_div   <= 16'd16;
    end else begin
      awready <= 1'b0;
      wready  <= 1'b0;
      if (bvalid && bready)
        bvalid <= 1'b0;
      if (!awready && awvalid && wvalid && !bvalid) begin
        awready <= 1'b1;
        wready  <= 1'b1;
      end
      if (awready && awvalid && wready && wvalid) begin
        bvalid <= 1'b1;
        bresp  <= OKAY;
        case (awaddr)
          8'h00: begin en <= wdata[0]; parity_odd <= wdata[1]; end
          8'h04: baud_div <= wdata[15:0];
          8'h08, 8'h0C, 8'h10, 8'h14: ;
          default: bresp <= SLVERR;
        endcase
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      arready <= 1'b0;
      rvalid  <= 1'b0;
      rdata   <= '0;
      rresp   <= OKAY;
    end else begin
      arready <= 1'b0;
      if (rvalid && rready)
        rvalid <= 1'b0;
      if (!arready && arvalid && !rvalid)
        arready <= 1'b1;
      if (arready && arvalid) begin
        rvalid <= 1'b1;
        rresp  <= OKAY;
        case (araddr)
          8'h00: rdata <= {30'b0, parity_odd, en};
          8'h04: rdata <= {16'b0, baud_div};
          8'h08: rdata <= {16'b0, rx_cnt};
          8'h0C: rdata <= {16'b0, frame_cnt, parity_cnt};
          8'h10: rdata <= {24'b0, rx_data};
          8'h14: rdata <= 32'h0000_C0DE;
          default: begin rdata <= '0; rresp <= SLVERR; end
        endcase
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_q1      <= 1'b1;
      rx_s       <= 1'b1;
      state      <= IDLE;
      cnt        <= '0;
      bit_idx    <= '0;
      shreg      <= '0;
      par_bit    <= 1'b0;
      rx_cnt     <= '0;
      parity_cnt <= '0;
      frame_cnt  <= '0;
      rx_data    <= '0;
      rx_valid   <= 1'b0;
      rx_byte    <= '0;
    end else begin
      rx_q1    <= rx;
      rx_s     <= rx_q1;
      rx_valid <= 1'b0;
      case (state)
        IDLE: begin
          if (en && !rx_s) begin
            cnt   <= (baud_div >> 1) - 1;
            state <= START;
          end
        end
        START: begin
          if (cnt == 0) begin
            if (!rx_s) begin
              cnt     <= baud_div - 1;
              bit_idx <= '0;
              state   <= DATA;
            end else
              state <= IDLE;
          end else
            cnt <= cnt - 1;
        end
        DATA: begin
          if (cnt == 0) begin
            shreg <= {rx_s, shreg[7:1]};
            cnt   <= baud_div - 1;
            if (bit_idx == 3'd7)
              state <= PARITY;
            else
              bit_idx <= bit_idx + 1;
          end else
            cnt <= cnt - 1;
        end
        PARITY: begin
          if (cnt == 0) begin
            par_bit <= rx_s;
            cnt     <= baud_div - 1;
            state   <= STOP;
          end else
            cnt <= cnt - 1;
        end
        STOP: begin
          if (cnt == 0) begin
            if (!rx_s) begin
              frame_cnt <= frame_cnt + 1;
              state     <= BREAK;
            end else if ((^shreg ^ par_bit) != parity_odd) begin
              parity_cnt <= parity_cnt + 1;
              state      <= IDLE;
            end else begin
              rx_cnt   <= rx_cnt + 1;
              rx_data  <= shreg;
              rx_byte  <= shreg;
              rx_valid <= 1'b1;
              state    <= IDLE;
            end
          end else
            cnt <= cnt - 1;
        end
        BREAK: begin
          if (rx_s)
            state <= IDLE;
        end
        default: state <= IDLE;
      endcase
    end
  end

endmodule
