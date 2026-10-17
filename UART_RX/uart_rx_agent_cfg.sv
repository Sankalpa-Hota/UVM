class uart_rx_agent_cfg extends uvm_object;
  `uvm_object_utils(uart_rx_agent_cfg)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  bit coverage_en = 1;
  int baud_div    = 16;
  bit parity_odd  = 1;

  function new(string name = "uart_rx_agent_cfg");
    super.new(name);
  endfunction
endclass
