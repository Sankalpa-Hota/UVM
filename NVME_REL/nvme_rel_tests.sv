class nvme_rel_tests extends uvm_test;
  `uvm_component_utils(nvme_rel_tests)

  nvme_rel_env env;
  nvme_rel_agent_cfg cfg;

  function new ( string name , uvm_component parent);
    super.new(name , parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = nvme_rel_agent_cfg::type_id::create("cfg");
    uvm_config_db#(nvme_rel_agent_cfg)::set(this, "env*", "cfg", cfg);
    env = nvme_rel_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

  task run_phase ( uvm_phase phase);
    nvme_rel_kat_seq   kat;
    nvme_rel_sequences seq;
    phase.raise_objection(this);
    kat = nvme_rel_kat_seq::type_id::create("kat");
    kat.start(env.ag.sqr);                       // known answers first
    seq = nvme_rel_sequences::type_id::create("seq");
    seq.num_items = 200;
    seq.start(env.ag.sqr);                       // then random blocks
    phase.phase_done.set_drain_time(this, 200ns);
    phase.drop_objection(this);
  endtask
endclass

// same env and sequences; every random block becomes an error block (one wrong PI/parity field)
class nvme_rel_err_test extends nvme_rel_tests;
  `uvm_component_utils(nvme_rel_err_test)
  function new ( string name , uvm_component parent);
    super.new(name , parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    nvme_rel_item::type_id::set_type_override(nvme_rel_err_item::get_type());
  endfunction
endclass
