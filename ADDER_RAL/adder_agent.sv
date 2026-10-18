class adder_agent extends uvm_agent;
  `uvm_component_utils(adder_agent)

  // agent-level ports: the monitor's ports are re-exported here so the env connects to the agent, not its insides
  uvm_analysis_port #(adder_item) ap_in;
  uvm_analysis_port #(adder_item) ap_out;

  adder_monitor   mon;
  adder_driver    drv;
  adder_sequencer sqr;
  adder_agent_cfg cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // build_phase is top-down: the agent exists and reads its cfg first, then decides which children to create
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // set side is set(context, path, key, value); this get reads the cfg the env set for path "ag"
    if (!uvm_config_db#(adder_agent_cfg)::get(this, "", "cfg", cfg)) begin
      `uvm_info("CFG", "CFG not found, using defaults", UVM_LOW)
      cfg = adder_agent_cfg::type_id::create("cfg");
    end

    ap_in  = new("ap_in",  this);
    ap_out = new("ap_out", this);

    // ACTIVE = driver + sequencer + monitor; PASSIVE = monitor only (reuse at chip level)
    is_active = cfg.is_active;

    // type_id::create instead of new: goes through the factory so a test can override the type
    mon = adder_monitor::type_id::create("mon", this);
    if (is_active == UVM_ACTIVE) begin
      drv = adder_driver   ::type_id::create("drv", this);
      sqr = adder_sequencer::type_id::create("sqr", this);
    end
  endfunction

  // connect_phase is bottom-up: runs after every build_phase, so both ends of each connection exist
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // child port -> parent port: monitor (sender) forwards through the agent to whoever the env connects
    mon.ap_in .connect(ap_in);
    mon.ap_out.connect(ap_out);

    // driver's seq_item_port PULLS items from the sequencer's seq_item_export
    if (is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
