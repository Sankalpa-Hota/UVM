module adder #(parameter N = 4) (
   input  logic         clk,
   input  logic         rst_n,
   input  logic [N-1:0] A,
   input  logic [N-1:0] B,
   input  logic         C,
   input  logic         in_valid,
   output logic [N:0]   sum,
   output logic         carry,
   output logic         out_valid);

  logic [N:0] sum_next;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sum       <= '0;
      carry     <= 1'b0;
      out_valid <= 1'b0;
    end else begin
      out_valid <= in_valid;
      if (in_valid) begin
        sum   <= sum_next;
        carry <= sum_next[N];
      end
    end
  end

  always_comb sum_next = A + B + C;

endmodule
