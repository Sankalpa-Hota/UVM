`timescale 1ns/1ps
`include "uvm_macros.svh"
`include "async_fifo_if.sv"
`include "async_fifo_sva.sv"
`include "async_fifo_pkg.sv"

module tb_top;
  import uvm_pkg::*;
  import async_fifo_pkg::*;

  logic wclk   = 0;
  logic rclk   = 0;
  logic wrst_n = 0;
  logic rrst_n = 0;

  always #5 wclk = ~wclk;
  always #7 rclk = ~rclk;

  initial begin
    wrst_n = 0;
    rrst_n = 0;
    #25 wrst_n = 1;
        rrst_n = 1;
  end

  async_fifo_if #(.DATA_W(DATA_W)) vif (.wclk(wclk), .wrst_n(wrst_n), .rclk(rclk), .rrst_n(rrst_n));

  async_fifo #(.DATA_W(DATA_W), .ADDR_W(ADDR_W)) dut (
    .wclk   (wclk),
    .wrst_n (wrst_n),
    .winc   (vif.winc),
    .wdata  (vif.wdata),
    .wfull  (vif.wfull),
    .rclk   (rclk),
    .rrst_n (rrst_n),
    .rinc   (vif.rinc),
    .rdata  (vif.rdata),
    .rempty (vif.rempty)
  );

  initial begin
    uvm_config_db#(virtual async_fifo_if #(DATA_W))::set(null, "uvm_test_top.env.ag.*", "async_fifo_if", vif);
    run_test("async_fifo_tests");
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end
endmodule
