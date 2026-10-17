class async_fifo_monitor extends uvm_monitor;
  `uvm_component_utils(async_fifo_monitor)

  virtual async_fifo_if #(DATA_W) vif;

  uvm_analysis_port #(async_fifo_item) ap_wr;
  uvm_analysis_port #(async_fifo_item) ap_rd;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (virtual async_fifo_if #(DATA_W))::get(this,"","async_fifo_if",vif)) `uvm_fatal("MON","Virtual interface not available");
    ap_wr =new("ap_wr",this);
    ap_rd =new("ap_rd",this);
  endfunction

  task run_phase(uvm_phase phase);
    wait (vif.wrst_n === 1'b1 && vif.rrst_n === 1'b1);
    // two clocks -> two independent sampling loops running in parallel
    fork
      mon_write();
      mon_read();
    join
  endtask

  // only an accepted write (winc && !wfull) is a real transaction
  task mon_write();
    async_fifo_item txn_wr;
    forever begin
      @(vif.wmon_cb);
      if (vif.wmon_cb.winc === 1'b1 && vif.wmon_cb.wfull === 1'b0) begin
        txn_wr = async_fifo_item::type_id::create("txn_wr");
        txn_wr.wr   = 1'b1;
        txn_wr.data = vif.wmon_cb.wdata;
        ap_wr.write(txn_wr);
      end
    end
  endtask

  // only an accepted read (rinc && !rempty); rdata is the word being popped at this edge
  task mon_read();
    async_fifo_item txn_rd;
    forever begin
      @(vif.rmon_cb);
      if (vif.rmon_cb.rinc === 1'b1 && vif.rmon_cb.rempty === 1'b0) begin
        txn_rd = async_fifo_item::type_id::create("txn_rd");
        txn_rd.wr   = 1'b0;
        txn_rd.data = vif.rmon_cb.rdata;
        ap_rd.write(txn_rd);
      end
    end
  endtask
endclass
