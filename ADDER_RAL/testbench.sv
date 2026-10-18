`timescale 1ns/1ps
`include "uvm_macros.svh"
`include "adder_if.sv"
`include "reg_if.sv"                                  // [REG]
`include "adder_pkg.sv"

module tb_top;
  import uvm_pkg::*;
  import adder_pkg::*;

  logic clk   = 0;
  logic rst_n = 0;

  always #5 clk = ~clk;

  initial begin
    rst_n = 0;
    #25 rst_n = 1;
  end

  adder_if #(.N(N)) vif (.clk(clk), .rst_n(rst_n));
  reg_if            rvif (.clk(clk), .rst_n(rst_n));   // [REG]

  adder #(.N(N)) dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .A        (vif.A),
    .B        (vif.B),
    .C        (vif.C),
    .in_valid (vif.in_valid),
    .sum      (vif.sum),
    .carry    (vif.carry),
    .out_valid(vif.out_valid),
    .reg_valid(rvif.reg_valid),                         // [REG]
    .reg_wr   (rvif.reg_wr),
    .reg_addr (rvif.reg_addr),
    .reg_wdata(rvif.reg_wdata),
    .reg_ready(rvif.reg_ready),
    .reg_rdata(rvif.reg_rdata)
  );

  assign vif.en = dut.en;                               // [REG] let the interface's assertion see CTRL.EN

  initial begin
    uvm_config_db#(virtual adder_if #(N))::set(null, "uvm_test_top.env.ag.*", "adder_if", vif);
    uvm_config_db#(virtual reg_if)::set(null, "uvm_test_top.env.reg_ag.*", "reg_if", rvif);   // [REG]
    run_test("adder_ral_test");                        // [RAL]
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end
endmodule
