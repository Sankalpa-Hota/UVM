class nvme_rel_env extends uvm_env;
  `uvm_component_utils(nvme_rel_env)

  nvme_rel_agent ag;
  nvme_rel_scoreboard sb;
  nvme_rel_agent_cfg cfg;
  nvme_rel_coverage cov;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (nvme_rel_agent_cfg)::get(this,"","cfg",cfg))
      cfg = nvme_rel_agent_cfg::type_id::create("cfg");
    uvm_config_db# (nvme_rel_agent_cfg)::set(this,"ag","cfg",cfg);
    ag = nvme_rel_agent::type_id::create("ag",this);
    sb = nvme_rel_scoreboard::type_id::create("sb",this);
    if (cfg.coverage_en) cov = nvme_rel_coverage::type_id::create("cov",this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ag.ap_in.connect(sb.imp_in);
    ag.ap_out.connect(sb.imp_out);
    if (cfg.coverage_en) ag.ap_out.connect(cov.analysis_export);
  endfunction
endclass
