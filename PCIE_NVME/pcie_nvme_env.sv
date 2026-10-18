class pcie_nvme_env extends uvm_env;
  `uvm_component_utils(pcie_nvme_env)

  tlp_agent  tlp_ag;
  nvme_agent nvme_ag;
  pcie_nvme_scoreboard sb;
  pcie_nvme_coverage cov;
  pcie_nvme_agent_cfg cfg;
  pcie_nvme_vseqr vseqr;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (pcie_nvme_agent_cfg)::get(this,"","cfg",cfg))
      cfg = pcie_nvme_agent_cfg::type_id::create("cfg");
    uvm_config_db# (pcie_nvme_agent_cfg)::set(this,"*","cfg",cfg);
    tlp_ag  = tlp_agent::type_id::create("tlp_ag",this);
    nvme_ag = nvme_agent::type_id::create("nvme_ag",this);
    sb      = pcie_nvme_scoreboard::type_id::create("sb",this);
    vseqr   = pcie_nvme_vseqr::type_id::create("vseqr",this);
    if (cfg.coverage_en) cov = pcie_nvme_coverage::type_id::create("cov",this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    tlp_ag.ap.connect(sb.imp_tlp);
    nvme_ag.ap.connect(sb.imp_nvme);
    if (cfg.coverage_en) tlp_ag.ap.connect(cov.analysis_export);
    vseqr.tlp_sqr  = tlp_ag.sqr;
    vseqr.nvme_sqr = nvme_ag.sqr;
  endfunction
endclass
