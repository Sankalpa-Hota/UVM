`timescale 1ns/1ps
interface adder_if #(parameter N = 4) ( input logic clk , rst_n);
  logic [N-1:0] A;
  logic [N-1:0] B;
  logic C;
  logic in_valid;
  logic [N:0] sum;
  logic carry;
  logic out_valid;

  clocking driver_cb @(posedge clk);
    default input #1step output #1;
    output A,B,C,in_valid;
    input carry,out_valid;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input A, B, C, in_valid, sum, carry, out_valid;
  endclocking

  modport DRIVER (clocking driver_cb,input clk , input rst_n);
  modport MONITOR (clocking mon_cb,input clk , input rst_n);

  a_latency : assert property (@(posedge clk) disable iff (!rst_n) in_valid |=> out_valid)
                else $error("out_valid did not follow in_valid");
  a_no_spur : assert property (@(posedge clk) disable iff (!rst_n) out_valid |-> $past(in_valid))
                else $error("out_valid without in_valid");

endinterface
