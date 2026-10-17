class async_fifo_tests extends uvm_test;
  `uvm_component_utils(async_fifo_tests)

  async_fifo_env env;
  async_fifo_agent_cfg cfg;

  function new ( string name , uvm_component parent);
    super.new(name , parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    cfg = async_fifo_agent_cfg::type_id::create("cfg");
    cfg.coverage_en = 1'b1;
    cfg.is_active = UVM_ACTIVE;
    uvm_config_db#(async_fifo_agent_cfg)::set(this, "env*", "cfg", cfg);

    env = async_fifo_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

  task run_phase ( uvm_phase phase);
    async_fifo_sequences seq;
    phase.raise_objection(this);
    seq = async_fifo_sequences::type_id::create("seq");
    seq.num_items = 200;
    seq.start(env.ag.sqr);
    // longer drain than adder: read data needs 2 rclk synchronizer stages to cross
    phase.phase_done.set_drain_time(this, 100ns);
    phase.drop_objection(this);


  endtask
endclass
