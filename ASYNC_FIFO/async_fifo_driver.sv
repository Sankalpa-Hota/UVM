class async_fifo_driver extends uvm_driver #(async_fifo_item);
  `uvm_component_utils(async_fifo_driver)

  virtual async_fifo_if #(DATA_W) vif;

  function new (string name , uvm_component parent);
    super.new(name , parent);
  endfunction

  function void build_phase ( uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (virtual async_fifo_if #(DATA_W))::get(this,"","async_fifo_if",vif)) `uvm_fatal("DRV","virtual interface missing");
    endfunction

  task run_phase (uvm_phase phase);
    vif.wdrv_cb.winc  <= 1'b0;
    vif.wdrv_cb.wdata <= '0;
    vif.rdrv_cb.rinc  <= 1'b0;
    wait (vif.wrst_n === 1'b1 && vif.rrst_n === 1'b1);
    @(vif.wdrv_cb);
    forever begin
      seq_item_port.get_next_item(req);
      drive(req);
      seq_item_port.item_done();
    end
  endtask

  // write uses the wclk clocking block, read uses the rclk one: each side is driven in its own clock domain
  // winc/rinc is driven even when full/empty on purpose; the DUT must drop it (checked by a_no_overflow / a_no_underflow)
  task drive (async_fifo_item item);
    if (item.wr) begin
      repeat (item.idle_cycles) @(vif.wdrv_cb);
      vif.wdrv_cb.winc  <= 1'b1;
      vif.wdrv_cb.wdata <= item.data;
      @(vif.wdrv_cb);
      vif.wdrv_cb.winc  <= 1'b0;
    end
    else begin
      repeat (item.idle_cycles) @(vif.rdrv_cb);
      vif.rdrv_cb.rinc  <= 1'b1;
      @(vif.rdrv_cb);
      vif.rdrv_cb.rinc  <= 1'b0;
    end
  endtask
endclass
