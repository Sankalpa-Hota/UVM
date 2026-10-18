class tlp_driver extends uvm_driver #(tlp_item);
  `uvm_component_utils(tlp_driver)

  virtual tlp_if vif;

  function new (string name , uvm_component parent);
    super.new(name , parent);
  endfunction

  function void build_phase ( uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (virtual tlp_if)::get(this,"","tlp_if",vif)) `uvm_fatal("DRV","virtual interface missing");
  endfunction

  task run_phase (uvm_phase phase);
    vif.driver_cb.tlp_valid <= 0;  vif.driver_cb.tlp_sop <= 0;  vif.driver_cb.tlp_eop <= 0;
    wait (vif.rst_n === 1'b1);
    @(vif.driver_cb);
    forever begin
      seq_item_port.get_next_item(req);
      drive(req);
      seq_item_port.item_done();
    end
  endtask

  // header DWs then payload DWs, one per beat; each beat is done only when valid && ready are seen at one edge
  task drive (tlp_item item);
    bit [31:0] beats[$];
    item.header(beats);
    foreach (item.payload[k]) beats.push_back(item.payload[k]);
    repeat (item.idle_cycles) @(vif.driver_cb);
    foreach (beats[k]) begin
      vif.driver_cb.tlp_valid <= 1;
      vif.driver_cb.tlp_sop   <= (k == 0);
      vif.driver_cb.tlp_eop   <= (k == beats.size() - 1);
      vif.driver_cb.tlp_data  <= beats[k];
      do @(vif.driver_cb); while (!(vif.mon_cb.tlp_valid === 1'b1 && vif.mon_cb.tlp_ready === 1'b1 &&
                                    vif.mon_cb.tlp_data === beats[k]));
    end
    vif.driver_cb.tlp_valid <= 0;  vif.driver_cb.tlp_sop <= 0;  vif.driver_cb.tlp_eop <= 0;
  endtask
endclass
