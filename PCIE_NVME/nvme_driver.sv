// reactive side: the DUT is the master here, the testbench only decides WHEN the NVMe side is ready
class nvme_driver extends uvm_driver #(nvme_item);
  `uvm_component_utils(nvme_driver)

  virtual nvme_if vif;

  function new (string name , uvm_component parent);
    super.new(name , parent);
  endfunction

  function void build_phase ( uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (virtual nvme_if)::get(this,"","nvme_if",vif)) `uvm_fatal("DRV","virtual interface missing");
  endfunction

  task run_phase (uvm_phase phase);
    vif.driver_cb.nvme_ready <= 1;
    wait (vif.rst_n === 1'b1);
    forever begin
      seq_item_port.get_next_item(req);
      vif.driver_cb.nvme_ready <= req.ready;
      repeat (req.cycles) @(vif.driver_cb);
      seq_item_port.item_done();
    end
  endtask
endclass
