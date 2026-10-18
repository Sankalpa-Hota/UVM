// [REG] new: one item per completed access
class reg_monitor extends uvm_monitor;
  `uvm_component_utils(reg_monitor)

  virtual reg_if vif;
  uvm_analysis_port #(reg_item) ap;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (virtual reg_if)::get(this,"","reg_if",vif)) `uvm_fatal("MON","Virtual interface not available");
    ap = new("ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    reg_item t;
    wait (vif.rst_n === 1'b1);
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.reg_valid === 1'b1 && vif.mon_cb.reg_ready === 1'b1) begin
        t = reg_item::type_id::create("t");
        t.wr   = vif.mon_cb.reg_wr;
        t.addr = vif.mon_cb.reg_addr;
        t.data = vif.mon_cb.reg_wr ? vif.mon_cb.reg_wdata : vif.mon_cb.reg_rdata;
        ap.write(t);
      end
    end
  endtask
endclass
