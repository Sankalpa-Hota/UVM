class uart_rx_env extends uvm_env;
  `uvm_component_utils(uart_rx_env)

  axil_agent axil_ag;
  uart_agent uart_ag;
  uart_rx_scoreboard sb;
  uart_rx_agent_cfg cfg;
  uart_rx_coverage cov;

  uart_rx_reg_block regmodel;
  axil_reg_adapter adapter;
  uvm_reg_predictor #(axil_item) predictor;
  uart_rx_vseqr vseqr;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    axil_ag.ap.connect(sb.imp_axil);
    uart_ag.ap_in.connect(sb.imp_in);
    uart_ag.ap_out.connect(sb.imp_out);
    if (cfg.coverage_en == 1'b1) begin
      uart_ag.ap_in.connect(cov.analysis_export);
    end

    // register accesses from the model go out through axil_sqr, translated by the adapter
    regmodel.default_map.set_sequencer(axil_ag.sqr, adapter);
    // explicit prediction: the model's mirror is updated only from what the monitor really saw on the bus
    regmodel.default_map.set_auto_predict(0);
    predictor.map     = regmodel.default_map;
    predictor.adapter = adapter;
    axil_ag.ap.connect(predictor.bus_in);

    vseqr.axil_sqr = axil_ag.sqr;
    vseqr.uart_sqr = uart_ag.sqr;
    vseqr.regmodel = regmodel;
    vseqr.cfg      = cfg;

  endfunction



  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (uart_rx_agent_cfg)::get(this,"","cfg",cfg)) begin
      `uvm_info("CFG","CFG not found",UVM_LOW);
       cfg = uart_rx_agent_cfg::type_id::create("cfg");
    end

    uvm_config_db# (uart_rx_agent_cfg)::set(this,"*","cfg",cfg);
    axil_ag=axil_agent::type_id::create("axil_ag",this);
    uart_ag=uart_agent::type_id::create("uart_ag",this);
    sb=uart_rx_scoreboard::type_id::create("sb",this);

    if (cfg.coverage_en == 1'b1) begin
      cov=uart_rx_coverage::type_id::create("cov",this);
    end

    // reg model is a uvm_object (not a component): create, then build() makes all registers and the map
    regmodel = uart_rx_reg_block::type_id::create("regmodel");
    regmodel.build();
    adapter   = axil_reg_adapter::type_id::create("adapter");
    predictor = uvm_reg_predictor #(axil_item)::type_id::create("predictor", this);
    vseqr     = uart_rx_vseqr::type_id::create("vseqr", this);

  endfunction
endclass
