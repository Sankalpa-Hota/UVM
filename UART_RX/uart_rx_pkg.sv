`include "uvm_macros.svh"

package uart_rx_pkg;
  import uvm_pkg::*;

  localparam bit [7:0] CTRL_ADDR    = 8'h00;
  localparam bit [7:0] BAUD_ADDR    = 8'h04;
  localparam bit [7:0] RX_CNT_ADDR  = 8'h08;
  localparam bit [7:0] ERR_CNT_ADDR = 8'h0C;
  localparam bit [7:0] RX_DATA_ADDR = 8'h10;
  localparam bit [7:0] ID_ADDR      = 8'h14;

  `include "uart_rx_agent_cfg.sv"
  `include "axil_item.sv"
  `include "axil_sequencer.sv"
  `include "axil_driver.sv"
  `include "axil_monitor.sv"
  `include "axil_agent.sv"
  `include "uart_item.sv"
  `include "uart_err_item.sv"
  `include "uart_sequences.sv"
  `include "uart_sequencer.sv"
  `include "uart_driver.sv"
  `include "uart_monitor.sv"
  `include "uart_agent.sv"
  `include "uart_rx_reg_block.sv"
  `include "axil_reg_adapter.sv"
  `include "uart_rx_scoreboard.sv"
  `include "uart_rx_coverage.sv"
  `include "uart_rx_vseqr.sv"
  `include "uart_rx_vseq.sv"
  `include "uart_rx_env.sv"
  `include "uart_rx_tests.sv"
endpackage
