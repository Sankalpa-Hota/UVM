class nvme_rel_monitor extends uvm_monitor;
  `uvm_component_utils(nvme_rel_monitor)

  virtual nvme_rel_if vif;

  uvm_analysis_port #(nvme_rel_item) ap_in;     // accepted blocks
  uvm_analysis_port #(nvme_rel_item) ap_out;    // results

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (virtual nvme_rel_if)::get(this,"","nvme_rel_if",vif)) `uvm_fatal("MON","Virtual interface not available");
    ap_in  = new("ap_in", this);
    ap_out = new("ap_out", this);
  endfunction

  task run_phase(uvm_phase phase);
    nvme_rel_item t;
    wait (vif.rst_n === 1'b1);
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.in_valid === 1'b1 && vif.mon_cb.in_ready === 1'b1) begin
        t = nvme_rel_item::type_id::create("txn_in");
        t.mode = vif.mon_cb.in_mode;  t.data = vif.mon_cb.in_data;  t.key = vif.mon_cb.in_key;
        t.lba = vif.mon_cb.in_lba;  t.app_tag = vif.mon_cb.in_app_tag;
        t.guard16 = vif.mon_cb.in_guard16;  t.guard32 = vif.mon_cb.in_guard32;
        t.ref_tag = vif.mon_cb.in_ref_tag;  t.parity = vif.mon_cb.in_parity;
        ap_in.write(t);
      end
      if (vif.mon_cb.out_valid === 1'b1) begin
        t = nvme_rel_item::type_id::create("txn_out");
        t.mode = vif.mon_cb.out_mode;  t.cipher = vif.mon_cb.out_cipher;
        t.guard16 = vif.mon_cb.out_guard16;  t.guard32 = vif.mon_cb.out_guard32;
        t.app_tag = vif.mon_cb.out_app_tag;  t.ref_tag = vif.mon_cb.out_ref_tag;  t.parity = vif.mon_cb.out_parity;
        t.g16_err = vif.mon_cb.out_guard16_err;  t.g32_err = vif.mon_cb.out_guard32_err;
        t.ref_err = vif.mon_cb.out_reftag_err;   t.par_err = vif.mon_cb.out_parity_err;
        ap_out.write(t);
      end
    end
  endtask
endclass
