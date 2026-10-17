class uart_driver extends uvm_driver #(uart_item);
  `uvm_component_utils(uart_driver)

  virtual uart_if vif;
  uart_rx_agent_cfg cfg;

  function new (string name , uvm_component parent);
    super.new(name , parent);
  endfunction

  function void build_phase ( uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (virtual uart_if)::get(this,"","uart_if",vif)) `uvm_fatal("DRV","virtual interface missing");
    if(!uvm_config_db# (uart_rx_agent_cfg)::get(this,"","cfg",cfg)) `uvm_fatal("DRV","cfg missing");
    endfunction

  task run_phase (uvm_phase phase);
    vif.driver_cb.rx <= 1'b1;
    wait (vif.rst_n === 1'b1);
    @(vif.driver_cb);
    forever begin
      seq_item_port.get_next_item(req);
      drive(req);
      seq_item_port.item_done();
    end
  endtask

  // frame: start(0), 8 data bits LSB first, parity, stop(1); each bit held for baud_div clocks
  task drive (uart_item item);
    bit p;
    p = ^item.data ^ cfg.parity_odd;
    if (item.parity_err) p = ~p;
    repeat (item.idle_bits) send_bit(1'b1);
    send_bit(1'b0);
    for (int i = 0; i < 8; i++) send_bit(item.data[i]);
    send_bit(p);
    send_bit(item.frame_err ? 1'b0 : 1'b1);
  endtask

  task send_bit (bit b);
    vif.driver_cb.rx <= b;
    repeat (cfg.baud_div) @(vif.driver_cb);
  endtask
endclass
