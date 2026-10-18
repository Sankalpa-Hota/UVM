class nvme_monitor extends uvm_monitor;
  `uvm_component_utils(nvme_monitor)

  virtual nvme_if vif;
  uvm_analysis_port #(nvme_evt) ap;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (virtual nvme_if)::get(this,"","nvme_if",vif)) `uvm_fatal("MON","Virtual interface not available");
    ap = new("ap", this);
  endfunction

  // one event per hand-off: a whole write (first beat .. nvme_last), a doorbell, or an error report
  task run_phase(uvm_phase phase);
    nvme_evt w, e;
    wait (vif.rst_n === 1'b1);
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.nvme_valid === 1'b1 && vif.mon_cb.nvme_ready === 1'b1) begin
        if (w == null) begin
          w = nvme_evt::type_id::create("wr");
          w.kind = EVT_WRITE;  w.addr = vif.mon_cb.nvme_addr;  w.first_be = vif.mon_cb.nvme_be;
        end
        w.data.push_back(vif.mon_cb.nvme_data);
        w.last_be = vif.mon_cb.nvme_be;
        if (vif.mon_cb.nvme_last) begin
          if (w.data.size() == 1) w.last_be = 0;       // a 1-DW write has Last BE = 0 in the TLP
          ap.write(w);
          w = null;
        end
      end
      if (vif.mon_cb.db_valid === 1'b1) begin
        e = nvme_evt::type_id::create("db");
        e.kind = EVT_DOORBELL;  e.db_cq = vif.mon_cb.db_cq;  e.db_qid = vif.mon_cb.db_qid;  e.db_value = vif.mon_cb.db_value;
        ap.write(e);
      end
      if (vif.mon_cb.err_valid === 1'b1) begin
        e = nvme_evt::type_id::create("err");
        e.kind = EVT_ERROR;  e.err_code = vif.mon_cb.err_code;
        ap.write(e);
      end
    end
  endtask
endclass
