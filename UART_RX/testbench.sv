`timescale 1ns/1ps
`include "uvm_macros.svh"
`include "axil_if.sv"
`include "uart_if.sv"
`include "uart_rx_pkg.sv"

module tb_top;
  import uvm_pkg::*;
  import uart_rx_pkg::*;

  logic clk   = 0;
  logic rst_n = 0;

  always #5 clk = ~clk;

  initial begin
    rst_n = 0;
    #25 rst_n = 1;
  end

  axil_if axil_vif (.clk(clk), .rst_n(rst_n));
  uart_if uart_vif (.clk(clk), .rst_n(rst_n));

  uart_rx dut (
    .clk     (clk),
    .rst_n   (rst_n),
    .awaddr  (axil_vif.awaddr),
    .awvalid (axil_vif.awvalid),
    .awready (axil_vif.awready),
    .wdata   (axil_vif.wdata),
    .wvalid  (axil_vif.wvalid),
    .wready  (axil_vif.wready),
    .bresp   (axil_vif.bresp),
    .bvalid  (axil_vif.bvalid),
    .bready  (axil_vif.bready),
    .araddr  (axil_vif.araddr),
    .arvalid (axil_vif.arvalid),
    .arready (axil_vif.arready),
    .rdata   (axil_vif.rdata),
    .rresp   (axil_vif.rresp),
    .rvalid  (axil_vif.rvalid),
    .rready  (axil_vif.rready),
    .rx      (uart_vif.rx),
    .rx_valid(uart_vif.rx_valid),
    .rx_byte (uart_vif.rx_byte)
  );

  initial begin
    uvm_config_db#(virtual axil_if)::set(null, "uvm_test_top.env.axil_ag.*", "axil_if", axil_vif);
    uvm_config_db#(virtual uart_if)::set(null, "uvm_test_top.env.uart_ag.*", "uart_if", uart_vif);
    run_test("uart_rx_tests");
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end
endmodule
