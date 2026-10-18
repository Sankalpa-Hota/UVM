class adder_env extends uvm_env;
  `uvm_component_utils(adder_env)

  adder_agent ag;
  adder_scoreboard sb;
  adder_agent_cfg cfg;
  adder_coverage cov;
  reg_agent reg_ag;                                  // [REG]
  adder_vseqr vseqr;                                 // [VSEQ]

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ag.ap_in.connect(sb.imp_in);
    ag.ap_out.connect(sb.imp_out);
    if (cfg.coverage_en == 1'b1) begin
      ag.ap_in.connect(cov.analysis_export);
    end
    reg_ag.ap.connect(sb.imp_reg);                                       // [REG]
    vseqr.adder_sqr = ag.sqr;                                            // [VSEQ] give the virtual sequencer
    vseqr.reg_sqr   = reg_ag.sqr;                                        // [VSEQ] its two real sequencers

  endfunction



  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (adder_agent_cfg)::get(this,"","cfg",cfg)) begin
      `uvm_info("CFG","CFG not found",UVM_LOW);
       cfg = adder_agent_cfg::type_id::create("cfg");
    end

    uvm_config_db# (adder_agent_cfg)::set(this,"*","cfg",cfg);          // [REG] "ag" -> "*": reg_ag needs it too
    ag=adder_agent::type_id::create("ag",this);
    sb=adder_scoreboard::type_id::create("sb",this);
    reg_ag=reg_agent::type_id::create("reg_ag",this);                   // [REG]
    vseqr=adder_vseqr::type_id::create("vseqr",this);                   // [VSEQ]

    if (cfg.coverage_en == 1'b1) begin
      cov=adder_coverage::type_id::create("cov",this);
    end

  endfunction
endclass
