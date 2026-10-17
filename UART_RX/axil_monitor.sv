class axil_monitor extends uvm_monitor;
  `uvm_component_utils(axil_monitor)

  virtual axil_if vif;

  uvm_analysis_port #(axil_item) ap;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (virtual axil_if)::get(this,"","axil_if",vif)) `uvm_fatal("MON","Virtual interface not available");
    ap =new("ap",this);
  endfunction

  // one transaction per completed write (B handshake) or read (R handshake); address/data are captured at their own handshakes
  task run_phase(uvm_phase phase);
    axil_item txn;
    bit [7:0]  wr_addr, rd_addr;
    bit [31:0] wr_data;
    wait (vif.rst_n === 1'b1);
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.awvalid === 1'b1 && vif.mon_cb.awready === 1'b1) wr_addr = vif.mon_cb.awaddr;
      if (vif.mon_cb.wvalid  === 1'b1 && vif.mon_cb.wready  === 1'b1) wr_data = vif.mon_cb.wdata;
      if (vif.mon_cb.arvalid === 1'b1 && vif.mon_cb.arready === 1'b1) rd_addr = vif.mon_cb.araddr;

      if (vif.mon_cb.bvalid === 1'b1 && vif.mon_cb.bready === 1'b1) begin
        txn = axil_item::type_id::create("txn_wr");
        txn.wr   = 1'b1;
        txn.addr = wr_addr;
        txn.data = wr_data;
        txn.resp = vif.mon_cb.bresp;
        ap.write(txn);
      end

      if (vif.mon_cb.rvalid === 1'b1 && vif.mon_cb.rready === 1'b1) begin
        txn = axil_item::type_id::create("txn_rd");
        txn.wr   = 1'b0;
        txn.addr = rd_addr;
        txn.data = vif.mon_cb.rdata;
        txn.resp = vif.mon_cb.rresp;
        ap.write(txn);
      end
    end
  endtask
endclass
