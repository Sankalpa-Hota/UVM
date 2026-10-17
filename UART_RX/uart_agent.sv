class uart_agent extends uvm_agent;
  `uvm_component_utils(uart_agent)

  uvm_analysis_port #(uart_item) ap_in;
  uvm_analysis_port #(uart_item) ap_out;

  uart_monitor   mon;
  uart_driver    drv;
  uart_sequencer sqr;
  uart_rx_agent_cfg cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(uart_rx_agent_cfg)::get(this, "", "cfg", cfg)) begin
      `uvm_info("CFG", "CFG not found, using defaults", UVM_LOW)
      cfg = uart_rx_agent_cfg::type_id::create("cfg");
    end

    ap_in  = new("ap_in",  this);
    ap_out = new("ap_out", this);

    is_active = cfg.is_active;

    mon = uart_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv = uart_driver   ::type_id::create("drv", this);
      sqr = uart_sequencer::type_id::create("sqr", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    mon.ap_in .connect(ap_in);
    mon.ap_out.connect(ap_out);

    if (is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
