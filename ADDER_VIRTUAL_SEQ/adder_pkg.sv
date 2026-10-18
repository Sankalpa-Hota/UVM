`include "uvm_macros.svh"

package adder_pkg;
  import uvm_pkg::*;

  localparam int N = 4;

  `include "adder_item.sv"
  `include "adder_sequences.sv"
  `include "adder_sequencer.sv"
  `include "adder_driver.sv"
  `include "adder_monitor.sv"
  `include "adder_agent_cfg.sv"
  `include "adder_agent.sv"
  `include "reg_item.sv"                 // [REG]
  `include "reg_sequences.sv"            // [VSEQ]
  `include "reg_sequencer.sv"            // [REG]
  `include "reg_driver.sv"               // [REG]
  `include "reg_monitor.sv"              // [REG]
  `include "reg_agent.sv"                // [REG]
  `include "adder_scoreboard.sv"
  `include "adder_coverage.sv"
  `include "adder_vseqr.sv"              // [VSEQ]
  `include "adder_vseq.sv"               // [VSEQ]
  `include "adder_env.sv"
  `include "adder_tests.sv"
endpackage
