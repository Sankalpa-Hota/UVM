class adder_vseq_test extends uvm_test;               // [VSEQ] renamed: a new test
  `uvm_component_utils(adder_vseq_test)

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
    adder_vseq vseq;                                     // [VSEQ]
    phase.raise_objection(this);
    vseq = adder_vseq::type_id::create("vseq");          // [VSEQ] the test only starts the virtual sequence
    vseq.start(env.vseqr);                               // [VSEQ] ... on the virtual sequencer
    phase.phase_done.set_drain_time(this, 50ns);
    phase.drop_objection(this);
  endtask
endclass
