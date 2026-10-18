`include "uvm_macros.svh"

package pcie_nvme_pkg;
  import uvm_pkg::*;

  localparam bit [31:0] BAR      = 32'h8000_0000;       // device BAR0
  localparam bit [31:0] DB_BASE  = BAR + 32'h1000;      // NVMe doorbells (SQ0 tail, CQ0 head, SQ1 tail, ...)
  localparam bit [31:0] WIN_BASE = BAR + 32'h2000;      // 4 KB data window

  `include "pcie_nvme_agent_cfg.sv"
  `include "tlp_item.sv"
  `include "tlp_err_item.sv"
  `include "tlp_sequences.sv"
  `include "tlp_sequencer.sv"
  `include "tlp_driver.sv"
  `include "tlp_monitor.sv"
  `include "tlp_agent.sv"
  `include "nvme_item.sv"
  `include "nvme_evt.sv"
  `include "nvme_sequences.sv"
  `include "nvme_sequencer.sv"
  `include "nvme_driver.sv"
  `include "nvme_monitor.sv"
  `include "nvme_agent.sv"
  `include "pcie_nvme_scoreboard.sv"
  `include "pcie_nvme_coverage.sv"
  `include "pcie_nvme_vseqr.sv"
  `include "pcie_nvme_vseq.sv"
  `include "pcie_nvme_env.sv"
  `include "pcie_nvme_tests.sv"
endpackage
