class axil_agent extends uvm_agent;
  `uvm_component_utils(axil_agent)

  uvm_analysis_port #(axil_item) ap;

  axil_monitor   mon;
  axil_driver    drv;
  axil_sequencer sqr;
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

    ap = new("ap", this);

    is_active = cfg.is_active;

    mon = axil_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv = axil_driver   ::type_id::create("drv", this);
      sqr = axil_sequencer::type_id::create("sqr", this);
    end
  endfunction

  // this sequencer is not used by our own sequences: the register model sends its bus items through it
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    mon.ap.connect(ap);

    if (is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
