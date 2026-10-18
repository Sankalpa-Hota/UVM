class nvme_rel_driver extends uvm_driver #(nvme_rel_item);
  `uvm_component_utils(nvme_rel_driver)

  virtual nvme_rel_if vif;

  function new (string name , uvm_component parent);
    super.new(name , parent);
  endfunction

  function void build_phase ( uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (virtual nvme_rel_if)::get(this,"","nvme_rel_if",vif)) `uvm_fatal("DRV","virtual interface missing");
  endfunction

  task run_phase (uvm_phase phase);
    vif.driver_cb.in_valid <= 1'b0;
    wait (vif.rst_n === 1'b1);
    @(vif.driver_cb);
    forever begin
      seq_item_port.get_next_item(req);
      drive(req);
      seq_item_port.item_done();
    end
  endtask

  // put the whole block on the pins, hold in_valid until in_valid && in_ready are seen at the same edge
  task drive (nvme_rel_item item);
    repeat (item.idle_cycles) @(vif.driver_cb);
    vif.driver_cb.in_mode    <= item.mode;
    vif.driver_cb.in_data    <= item.data;
    vif.driver_cb.in_key     <= item.key;
    vif.driver_cb.in_lba     <= item.lba;
    vif.driver_cb.in_app_tag <= item.app_tag;
    vif.driver_cb.in_guard16 <= item.guard16;
    vif.driver_cb.in_guard32 <= item.guard32;
    vif.driver_cb.in_ref_tag <= item.ref_tag;
    vif.driver_cb.in_parity  <= item.parity;
    vif.driver_cb.in_valid   <= 1'b1;
    do @(vif.driver_cb); while (!(vif.mon_cb.in_valid === 1'b1 && vif.mon_cb.in_ready === 1'b1));
    vif.driver_cb.in_valid   <= 1'b0;
  endtask
endclass
