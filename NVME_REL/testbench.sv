`timescale 1ns/1ps
`include "uvm_macros.svh"
`include "nvme_rel_if.sv"
`include "nvme_rel_pkg.sv"

module tb_top;
  import uvm_pkg::*;
  import nvme_rel_pkg::*;

  logic clk   = 0;
  logic rst_n = 0;
  always #5 clk = ~clk;
  initial #25 rst_n = 1;

  nvme_rel_if vif (.clk(clk), .rst_n(rst_n));

  nvme_rel dut (
    .clk(clk), .rst_n(rst_n),
    .in_valid(vif.in_valid), .in_ready(vif.in_ready), .in_mode(vif.in_mode),
    .in_data(vif.in_data), .in_key(vif.in_key), .in_lba(vif.in_lba), .in_app_tag(vif.in_app_tag),
    .in_guard16(vif.in_guard16), .in_guard32(vif.in_guard32), .in_ref_tag(vif.in_ref_tag), .in_parity(vif.in_parity),
    .out_valid(vif.out_valid), .out_mode(vif.out_mode), .out_cipher(vif.out_cipher),
    .out_guard16(vif.out_guard16), .out_app_tag(vif.out_app_tag), .out_ref_tag(vif.out_ref_tag),
    .out_guard32(vif.out_guard32), .out_parity(vif.out_parity),
    .out_guard16_err(vif.out_guard16_err), .out_guard32_err(vif.out_guard32_err),
    .out_reftag_err(vif.out_reftag_err), .out_parity_err(vif.out_parity_err));

  initial begin
    uvm_config_db#(virtual nvme_rel_if)::set(null, "uvm_test_top.env.ag.*", "nvme_rel_if", vif);
    run_test("nvme_rel_tests");
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end
endmodule
