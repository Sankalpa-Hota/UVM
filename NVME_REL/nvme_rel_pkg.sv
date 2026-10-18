`include "uvm_macros.svh"

package nvme_rel_pkg;
  import uvm_pkg::*;

  // FIPS-197 Appendix C.1 known answer + CRCs of that block (computed independently in Python)
  localparam bit [127:0] FIPS_KEY   = 128'h000102030405060708090a0b0c0d0e0f;
  localparam bit [127:0] FIPS_PT    = 128'h00112233445566778899aabbccddeeff;
  localparam bit [127:0] FIPS_CT    = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
  localparam bit [15:0]  FIPS_CRC16 = 16'hb1b2;
  localparam bit [31:0]  FIPS_CRC32 = 32'h48dfe982;

  `include "nvme_rel_model.sv"
  `include "nvme_rel_agent_cfg.sv"
  `include "nvme_rel_item.sv"
  `include "nvme_rel_err_item.sv"
  `include "nvme_rel_sequences.sv"
  `include "nvme_rel_sequencer.sv"
  `include "nvme_rel_driver.sv"
  `include "nvme_rel_monitor.sv"
  `include "nvme_rel_agent.sv"
  `include "nvme_rel_scoreboard.sv"
  `include "nvme_rel_coverage.sv"
  `include "nvme_rel_env.sv"
  `include "nvme_rel_tests.sv"
endpackage
