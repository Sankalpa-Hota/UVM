class nvme_rel_agent extends uvm_agent;
  `uvm_component_utils(nvme_rel_agent)

  uvm_analysis_port #(nvme_rel_item) ap_in;
  uvm_analysis_port #(nvme_rel_item) ap_out;

  nvme_rel_monitor   mon;
  nvme_rel_driver    drv;
  nvme_rel_sequencer sqr;
  nvme_rel_agent_cfg cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(nvme_rel_agent_cfg)::get(this, "", "cfg", cfg))
      cfg = nvme_rel_agent_cfg::type_id::create("cfg");
    ap_in  = new("ap_in",  this);
    ap_out = new("ap_out", this);
    is_active = cfg.is_active;
    mon = nvme_rel_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv = nvme_rel_driver   ::type_id::create("drv", this);
      sqr = nvme_rel_sequencer::type_id::create("sqr", this);
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
