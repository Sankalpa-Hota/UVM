class tlp_agent extends uvm_agent;
  `uvm_component_utils(tlp_agent)

  uvm_analysis_port #(tlp_item) ap;

  tlp_monitor   mon;
  tlp_driver    drv;
  tlp_sequencer sqr;
  pcie_nvme_agent_cfg cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pcie_nvme_agent_cfg)::get(this, "", "cfg", cfg))
      cfg = pcie_nvme_agent_cfg::type_id::create("cfg");
    ap = new("ap", this);
    is_active = cfg.is_active;
    mon = tlp_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv = tlp_driver   ::type_id::create("drv", this);
      sqr = tlp_sequencer::type_id::create("sqr", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon.ap.connect(ap);
    if (is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
