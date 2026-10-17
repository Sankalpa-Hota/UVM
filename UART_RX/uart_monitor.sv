class uart_monitor extends uvm_monitor;
  `uvm_component_utils(uart_monitor)

  virtual uart_if vif;
  uart_rx_agent_cfg cfg;

  uvm_analysis_port #(uart_item) ap_in;
  uvm_analysis_port #(uart_item) ap_out;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (virtual uart_if)::get(this,"","uart_if",vif)) `uvm_fatal("MON","Virtual interfaces not available");
    if(!uvm_config_db# (uart_rx_agent_cfg)::get(this,"","cfg",cfg)) `uvm_fatal("MON","cfg missing");
    ap_in =new("ap_in",this);
    ap_out =new("ap_out",this);
  endfunction

  // frame decoding takes many clocks, so line decode and DUT output run as two parallel loops
  task run_phase(uvm_phase phase);
    wait (vif.rst_n === 1'b1);
    fork
      mon_line();
      mon_out();
    join
  endtask

  // falling edge = start bit; wait half a bit to reach the middle, then sample once per bit
  // sends raw data/parity/stop; the scoreboard decides good / parity error / frame error
  task mon_line();
    uart_item txn_in;
    forever begin
      do @(vif.mon_cb); while (vif.mon_cb.rx !== 1'b0);
      repeat (cfg.baud_div / 2) @(vif.mon_cb);
      if (vif.mon_cb.rx !== 1'b0) continue;
      txn_in = uart_item::type_id::create("txn_in");
      for (int i = 0; i < 8; i++) begin
        repeat (cfg.baud_div) @(vif.mon_cb);
        txn_in.data[i] = vif.mon_cb.rx;
      end
      repeat (cfg.baud_div) @(vif.mon_cb);
      txn_in.parity = vif.mon_cb.rx;
      repeat (cfg.baud_div) @(vif.mon_cb);
      txn_in.stop = vif.mon_cb.rx;
      ap_in.write(txn_in);
      while (vif.mon_cb.rx !== 1'b1) @(vif.mon_cb);
    end
  endtask

  task mon_out();
    uart_item txn_out;
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.rx_valid === 1'b1) begin
        txn_out = uart_item::type_id::create("txn_out");
        txn_out.data = vif.mon_cb.rx_byte;
        ap_out.write(txn_out);
      end
    end
  endtask
endclass
