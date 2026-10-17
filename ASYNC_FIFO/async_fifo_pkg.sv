`include "uvm_macros.svh"

package async_fifo_pkg;
  import uvm_pkg::*;

  localparam int DATA_W = 8;
  localparam int ADDR_W = 4;
  localparam int DEPTH  = 1 << ADDR_W;

  `include "async_fifo_item.sv"
  `include "async_fifo_sequences.sv"
  `include "async_fifo_sequencer.sv"
  `include "async_fifo_driver.sv"
  `include "async_fifo_monitor.sv"
  `include "async_fifo_agent_cfg.sv"
  `include "async_fifo_agent.sv"
  `include "async_fifo_scoreboard.sv"
  `include "async_fifo_coverage.sv"
  `include "async_fifo_env.sv"
  `include "async_fifo_tests.sv"
endpackage
