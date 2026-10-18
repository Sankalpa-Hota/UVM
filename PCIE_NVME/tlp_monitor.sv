class tlp_monitor extends uvm_monitor;
  `uvm_component_utils(tlp_monitor)

  virtual tlp_if vif;
  uvm_analysis_port #(tlp_item) ap;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (virtual tlp_if)::get(this,"","tlp_if",vif)) `uvm_fatal("MON","Virtual interface not available");
    ap = new("ap", this);
  endfunction

  // collect beats from sop to eop, then decode the header the way the spec defines it
  task run_phase(uvm_phase phase);
    bit [31:0] beats[$];
    tlp_item t;
    int h;
    wait (vif.rst_n === 1'b1);
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.tlp_valid === 1'b1 && vif.mon_cb.tlp_ready === 1'b1) begin
        if (vif.mon_cb.tlp_sop) beats.delete();
        beats.push_back(vif.mon_cb.tlp_data);
        if (vif.mon_cb.tlp_eop) begin
          t = tlp_item::type_id::create("tlp");
          t.fmt = beats[0][31:29];  t.typ = beats[0][28:24];  t.length = beats[0][9:0];
          t.req_id = beats[1][31:16];  t.tag = beats[1][15:8];  t.last_be = beats[1][7:4];  t.first_be = beats[1][3:0];
          h = t.fmt[0] ? 4 : 3;
          t.addr = t.fmt[0] ? {beats[2], beats[3][31:2], 2'b00} : {32'h0, beats[2][31:2], 2'b00};
          t.payload = new[beats.size() - h];
          foreach (t.payload[k]) t.payload[k] = beats[h + k];
          ap.write(t);
        end
      end
    end
  endtask
endclass
