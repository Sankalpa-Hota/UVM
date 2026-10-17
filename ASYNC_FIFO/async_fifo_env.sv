class async_fifo_env extends uvm_env;
  `uvm_component_utils(async_fifo_env)

  async_fifo_agent ag;
  async_fifo_scoreboard sb;
  async_fifo_agent_cfg cfg;
  async_fifo_coverage cov;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // port -> TLM fifo's analysis_export: each write() from the monitor lands in that fifo's queue
    ag.ap_wr.connect(sb.wr_fifo.analysis_export);
    ag.ap_rd.connect(sb.rd_fifo.analysis_export);
    if (cfg.coverage_en == 1'b1) begin
      ag.ap_wr.connect(cov.analysis_export);
      ag.ap_rd.connect(cov.analysis_export);
    end

  endfunction



  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (async_fifo_agent_cfg)::get(this,"","cfg",cfg)) begin
      `uvm_info("CFG","CFG not found",UVM_LOW);
       cfg = async_fifo_agent_cfg::type_id::create("cfg");
    end

    uvm_config_db# (async_fifo_agent_cfg)::set(this,"ag","cfg",cfg);
    ag=async_fifo_agent::type_id::create("ag",this);
    sb=async_fifo_scoreboard::type_id::create("sb",this);

    if (cfg.coverage_en == 1'b1) begin
      cov=async_fifo_coverage::type_id::create("cov",this);
    end

  endfunction
endclass
