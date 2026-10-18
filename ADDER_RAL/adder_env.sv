class adder_env extends uvm_env;
  `uvm_component_utils(adder_env)

  adder_agent ag;
  adder_scoreboard sb;
  adder_agent_cfg cfg;
  adder_coverage cov;
  reg_agent reg_ag;                                  // [REG]
  adder_reg_block regmodel;                          // [RAL]
  reg_adapter adapter;                               // [RAL]
  uvm_reg_predictor #(reg_item) predictor;           // [RAL]

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
    regmodel.default_map.set_sequencer(reg_ag.sqr, adapter);             // [RAL] register ops go out on reg_ag
    regmodel.default_map.set_auto_predict(0);                            // [RAL] mirror follows the bus monitor
    predictor.map     = regmodel.default_map;                            // [RAL]
    predictor.adapter = adapter;                                         // [RAL]
    reg_ag.ap.connect(predictor.bus_in);                                 // [RAL]

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
    regmodel = adder_reg_block::type_id::create("regmodel");            // [RAL] an object: create, then build()
    regmodel.build();                                                    // [RAL]
    adapter   = reg_adapter::type_id::create("adapter");                // [RAL]
    predictor = uvm_reg_predictor #(reg_item)::type_id::create("predictor", this);   // [RAL]

    if (cfg.coverage_en == 1'b1) begin
      cov=adder_coverage::type_id::create("cov",this);
    end

  endfunction
endclass
