class async_fifo_agent extends uvm_agent;
  `uvm_component_utils(async_fifo_agent)

  // still analysis PORTS here: the sender side doesn't change, only the scoreboard's receiver side becomes a TLM fifo
  uvm_analysis_port #(async_fifo_item) ap_wr;
  uvm_analysis_port #(async_fifo_item) ap_rd;

  async_fifo_monitor   mon;
  async_fifo_driver    drv;
  async_fifo_sequencer sqr;
  async_fifo_agent_cfg cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(async_fifo_agent_cfg)::get(this, "", "cfg", cfg)) begin
      `uvm_info("CFG", "CFG not found, using defaults", UVM_LOW)
      cfg = async_fifo_agent_cfg::type_id::create("cfg");
    end

    ap_wr = new("ap_wr", this);
    ap_rd = new("ap_rd", this);

    is_active = cfg.is_active;

    mon = async_fifo_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv = async_fifo_driver   ::type_id::create("drv", this);
      sqr = async_fifo_sequencer::type_id::create("sqr", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    mon.ap_wr.connect(ap_wr);
    mon.ap_rd.connect(ap_rd);

    if (is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
