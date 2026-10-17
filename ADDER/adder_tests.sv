class adder_tests extends uvm_test;
  `uvm_component_utils(adder_tests)

  adder_env env;
  adder_agent_cfg cfg;

  function new ( string name , uvm_component parent);
    super.new(name , parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    cfg = adder_agent_cfg::type_id::create("cfg");
    cfg.coverage_en = 1'b1;
    cfg.is_active = UVM_ACTIVE;
    uvm_config_db#(adder_agent_cfg)::set(this, "env*", "cfg", cfg);

    env = adder_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

  task run_phase ( uvm_phase phase);
    adder_sequences seq;
    // raise: run_phase ends only when every raised objection is dropped (drivers/monitors loop forever)
    phase.raise_objection(this);
    seq = adder_sequences::type_id::create("seq");
    seq.num_items = 100;
    seq.start(env.ag.sqr);
    // drain: keep the phase alive a little after the drop so the last output reaches the scoreboard
    phase.phase_done.set_drain_time(this, 50ns);
    phase.drop_objection(this);


  endtask
endclass
