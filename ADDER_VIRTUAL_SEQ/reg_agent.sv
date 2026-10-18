// [REG] new: the register-bus agent (same shape as adder_agent)
class reg_agent extends uvm_agent;
  `uvm_component_utils(reg_agent)

  uvm_analysis_port #(reg_item) ap;

  reg_monitor   mon;
  reg_driver    drv;
  reg_sequencer sqr;
  adder_agent_cfg cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(adder_agent_cfg)::get(this, "", "cfg", cfg))
      cfg = adder_agent_cfg::type_id::create("cfg");
    ap = new("ap", this);
    is_active = cfg.is_active;
    mon = reg_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv = reg_driver   ::type_id::create("drv", this);
      sqr = reg_sequencer::type_id::create("sqr", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon.ap.connect(ap);
    if (is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
