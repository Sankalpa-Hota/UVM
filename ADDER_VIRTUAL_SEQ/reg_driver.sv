// [REG] new: drives one register access, returns read data in the same item
class reg_driver extends uvm_driver #(reg_item);
  `uvm_component_utils(reg_driver)

  virtual reg_if vif;

  function new (string name , uvm_component parent);
    super.new(name , parent);
  endfunction

  function void build_phase ( uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (virtual reg_if)::get(this,"","reg_if",vif)) `uvm_fatal("DRV","virtual interface missing");
  endfunction

  task run_phase (uvm_phase phase);
    vif.driver_cb.reg_valid <= 1'b0;
    wait (vif.rst_n === 1'b1);
    @(vif.driver_cb);
    forever begin
      seq_item_port.get_next_item(req);
      vif.driver_cb.reg_valid <= 1'b1;
      vif.driver_cb.reg_wr    <= req.wr;
      vif.driver_cb.reg_addr  <= req.addr;
      vif.driver_cb.reg_wdata <= req.data;
      do @(vif.driver_cb); while (!(vif.mon_cb.reg_valid === 1'b1 && vif.mon_cb.reg_ready === 1'b1));
      if (!req.wr) req.data = vif.mon_cb.reg_rdata;          // read data goes back in the same object
      vif.driver_cb.reg_valid <= 1'b0;
      @(vif.driver_cb);                                       // one idle cycle between accesses
      seq_item_port.item_done();
    end
  endtask
endclass
