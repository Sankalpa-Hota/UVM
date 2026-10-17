// virtual sequencer: drives no pins and has no driver; it only holds handles to the real sequencers (+ reg model)
// so one virtual sequence can run sequences on both agents; the env fills these handles in connect_phase
class uart_rx_vseqr extends uvm_sequencer;
  `uvm_component_utils(uart_rx_vseqr)

  axil_sequencer     axil_sqr;
  uart_sequencer     uart_sqr;
  uart_rx_reg_block  regmodel;
  uart_rx_agent_cfg  cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
