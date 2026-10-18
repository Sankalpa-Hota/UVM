`timescale 1ns/1ps
`include "uvm_macros.svh"
`include "tlp_if.sv"
`include "nvme_if.sv"
`include "pcie_nvme_pkg.sv"

module tb_top;
  import uvm_pkg::*;
  import pcie_nvme_pkg::*;

  logic clk   = 0;
  logic rst_n = 0;
  always #5 clk = ~clk;
  initial #25 rst_n = 1;

  tlp_if  tvif (.clk(clk), .rst_n(rst_n));
  nvme_if nvif (.clk(clk), .rst_n(rst_n));

  pcie_nvme dut (
    .clk(clk), .rst_n(rst_n),
    .tlp_valid(tvif.tlp_valid), .tlp_ready(tvif.tlp_ready), .tlp_sop(tvif.tlp_sop), .tlp_eop(tvif.tlp_eop), .tlp_data(tvif.tlp_data),
    .nvme_valid(nvif.nvme_valid), .nvme_ready(nvif.nvme_ready), .nvme_addr(nvif.nvme_addr), .nvme_data(nvif.nvme_data),
    .nvme_be(nvif.nvme_be), .nvme_last(nvif.nvme_last),
    .db_valid(nvif.db_valid), .db_cq(nvif.db_cq), .db_qid(nvif.db_qid), .db_value(nvif.db_value),
    .err_valid(nvif.err_valid), .err_code(nvif.err_code));

  initial begin
    uvm_config_db#(virtual tlp_if)::set(null, "uvm_test_top.env.tlp_ag.*", "tlp_if", tvif);
    uvm_config_db#(virtual nvme_if)::set(null, "uvm_test_top.env.nvme_ag.*", "nvme_if", nvif);
    run_test("pcie_nvme_tests");
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end
endmodule
