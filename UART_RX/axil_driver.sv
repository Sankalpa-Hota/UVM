class axil_driver extends uvm_driver #(axil_item);
  `uvm_component_utils(axil_driver)

  virtual axil_if vif;

  function new (string name , uvm_component parent);
    super.new(name , parent);
  endfunction

  function void build_phase ( uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (virtual axil_if)::get(this,"","axil_if",vif)) `uvm_fatal("DRV","virtual interface missing");
    endfunction

  task run_phase (uvm_phase phase);
    vif.driver_cb.awvalid <= 1'b0;
    vif.driver_cb.wvalid  <= 1'b0;
    vif.driver_cb.bready  <= 1'b0;
    vif.driver_cb.arvalid <= 1'b0;
    vif.driver_cb.rready  <= 1'b0;
    wait (vif.rst_n === 1'b1);
    @(vif.driver_cb);
    forever begin
      seq_item_port.get_next_item(req);
      drive(req);
      seq_item_port.item_done();
    end
  endtask

  // a handshake happens only on a clock edge where valid && ready are both 1 on the wire
  // resp/data are written back into req: the RAL adapter reads them from this same object (provides_responses = 0)
  task drive (axil_item item);
    if (item.wr) begin
      vif.driver_cb.awaddr  <= item.addr;
      vif.driver_cb.awvalid <= 1'b1;
      vif.driver_cb.wdata   <= item.data;
      vif.driver_cb.wvalid  <= 1'b1;
      do @(vif.driver_cb); while (!(vif.driver_cb.awready === 1'b1 && vif.driver_cb.wready === 1'b1));
      vif.driver_cb.awvalid <= 1'b0;
      vif.driver_cb.wvalid  <= 1'b0;
      vif.driver_cb.bready  <= 1'b1;
      do @(vif.driver_cb); while (vif.driver_cb.bvalid !== 1'b1);
      item.resp = vif.driver_cb.bresp;
      vif.driver_cb.bready  <= 1'b0;
    end
    else begin
      vif.driver_cb.araddr  <= item.addr;
      vif.driver_cb.arvalid <= 1'b1;
      do @(vif.driver_cb); while (vif.driver_cb.arready !== 1'b1);
      vif.driver_cb.arvalid <= 1'b0;
      vif.driver_cb.rready  <= 1'b1;
      do @(vif.driver_cb); while (vif.driver_cb.rvalid !== 1'b1);
      item.data = vif.driver_cb.rdata;
      item.resp = vif.driver_cb.rresp;
      vif.driver_cb.rready  <= 1'b0;
    end
  endtask
endclass
