class uart_rx_tests extends uvm_test;
  `uvm_component_utils(uart_rx_tests)

  uart_rx_env env;
  uart_rx_agent_cfg cfg;

  function new ( string name , uvm_component parent);
    super.new(name , parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    cfg = uart_rx_agent_cfg::type_id::create("cfg");
    cfg.coverage_en = 1'b1;
    cfg.is_active = UVM_ACTIVE;
    cfg.baud_div = 16;
    cfg.parity_odd = 1'b1;
    uvm_config_db#(uart_rx_agent_cfg)::set(this, "env*", "cfg", cfg);

    env = uart_rx_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

  // the test only starts the virtual sequence on the virtual sequencer; it never touches the agents directly
  task run_phase ( uvm_phase phase);
    uart_rx_vseq vseq;
    phase.raise_objection(this);
    vseq = uart_rx_vseq::type_id::create("vseq");
    vseq.num_frames = 30;
    vseq.start(env.vseqr);
    phase.phase_done.set_drain_time(this, 100ns);
    phase.drop_objection(this);


  endtask
endclass


// same env, same virtual sequence; only the frame type changes
class uart_rx_err_test extends uart_rx_tests;
  `uvm_component_utils(uart_rx_err_test)

  function new ( string name , uvm_component parent);
    super.new(name , parent);
  endfunction

  // factory override: every uart_item::type_id::create() from now on returns a uart_err_item
  // must be set before the items are created (build_phase is enough)
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uart_item::type_id::set_type_override(uart_err_item::get_type());
  endfunction
endclass
