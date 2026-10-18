`timescale 1ns/1ps
module adder #(parameter N = 4) (
   input  logic         clk,
   input  logic         rst_n,
   input  logic [N-1:0] A,
   input  logic [N-1:0] B,
   input  logic         C,
   input  logic         in_valid,
   output logic [N:0]   sum,
   output logic         carry,
   output logic         out_valid,
   // [REG] simple register bus: request held until reg_ready (1-cycle answer)
   input  logic         reg_valid,
   input  logic         reg_wr,
   input  logic [3:0]   reg_addr,
   input  logic [31:0]  reg_wdata,
   output logic         reg_ready,
   output logic [31:0]  reg_rdata);

  logic [N:0] sum_next;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sum       <= '0;
      carry     <= 1'b0;
      out_valid <= 1'b0;
    end else begin
      out_valid <= in_valid && en;                          // [REG] adds only when CTRL.EN = 1
      if (in_valid && en) begin
        sum   <= sum_next;
        carry <= sum_next[N];
      end
    end
  end

  always_comb sum_next = A + B + C;

  // [REG] registers: 0x0 CTRL (bit0 EN, RW), 0x4 ADD_CNT (RO), 0x8 LAST_SUM (RO), 0xC ID = 0xADD0 (RO)
  logic        en;
  logic [15:0] add_cnt;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      en        <= 1'b0;
      add_cnt   <= '0;
      reg_ready <= 1'b0;
      reg_rdata <= '0;
    end else begin
      reg_ready <= reg_valid && !reg_ready;
      if (reg_valid && !reg_ready) begin
        if (reg_wr && reg_addr == 4'h0) en <= reg_wdata[0];
        case (reg_addr)
          4'h0:    reg_rdata <= {31'b0, en};
          4'h4:    reg_rdata <= {16'b0, add_cnt};
          4'h8:    reg_rdata <= 32'(sum);
          4'hC:    reg_rdata <= 32'h0000_ADD0;
          default: reg_rdata <= '0;
        endcase
      end
      if (out_valid) add_cnt <= add_cnt + 1;
    end
  end

endmodule
