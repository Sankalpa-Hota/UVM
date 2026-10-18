class adder_ral_test extends uvm_test;                // [RAL] renamed: a new test
  `uvm_component_utils(adder_ral_test)

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
    uvm_status_e         status;                         // [RAL]
    uvm_reg_data_t       val;                            // [RAL]
    uvm_reg_hw_reset_seq rst_seq;                        // [RAL]
    phase.raise_objection(this);

    // [RAL] 1. every register's reset value, read and compared by a built-in UVM sequence
    rst_seq = uvm_reg_hw_reset_seq::type_id::create("rst_seq");
    rst_seq.model = env.regmodel;
    rst_seq.start(null);

    // [RAL] 2. enable the adder: one call = one bus write to 0x0; then read back and compare with the model
    env.regmodel.CTRL.write(status, 1);
    env.regmodel.CTRL.mirror(status, UVM_CHECK);

    // 3. the ORIGINAL adder traffic, unchanged
    seq = adder_sequences::type_id::create("seq");
    seq.num_items = 100;
    seq.start(env.ag.sqr);
    #50ns;

    // [RAL] 4. status registers: the scoreboard checks each read against its own counts
    env.regmodel.ADD_CNT.read(status, val);
    `uvm_info("TEST", $sformatf("ADD_CNT read through RAL = %0d", val), UVM_LOW)
    env.regmodel.LAST_SUM.read(status, val);

    phase.phase_done.set_drain_time(this, 50ns);
    phase.drop_objection(this);
  endtask
endclass
