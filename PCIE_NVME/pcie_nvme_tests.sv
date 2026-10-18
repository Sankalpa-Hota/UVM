class pcie_nvme_tests extends uvm_test;
  `uvm_component_utils(pcie_nvme_tests)

  pcie_nvme_env env;
  pcie_nvme_agent_cfg cfg;

  function new ( string name , uvm_component parent);
    super.new(name , parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = pcie_nvme_agent_cfg::type_id::create("cfg");
    uvm_config_db#(pcie_nvme_agent_cfg)::set(this, "env*", "cfg", cfg);
    env = pcie_nvme_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

  task run_phase ( uvm_phase phase);
    pcie_nvme_vseq vseq;
    phase.raise_objection(this);
    vseq = pcie_nvme_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    phase.phase_done.set_drain_time(this, 500ns);
    phase.drop_objection(this);
  endtask
endclass

// same env and virtual sequence; every TLP has exactly one problem (bad length, bad type or unmapped address)
class pcie_nvme_err_test extends pcie_nvme_tests;
  `uvm_component_utils(pcie_nvme_err_test)
  function new ( string name , uvm_component parent);
    super.new(name , parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tlp_item::type_id::set_type_override(tlp_err_item::get_type());
  endfunction
endclass
