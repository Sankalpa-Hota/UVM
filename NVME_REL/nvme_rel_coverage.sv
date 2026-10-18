class nvme_rel_coverage extends uvm_subscriber #(nvme_rel_item);
  `uvm_component_utils(nvme_rel_coverage)

  covergroup cg with function sample(nvme_rel_item t);
    cp_mode  : coverpoint t.mode { bins write = {0}; bins read = {1}; }
    cp_err   : coverpoint {t.g16_err, t.g32_err, t.ref_err, t.par_err} {
                 bins none = {4'b0000}; bins guard16 = {4'b1000}; bins guard32 = {4'b0100};
                 bins reftag = {4'b0010}; bins parity = {4'b0001}; }
    cp_esc   : coverpoint (t.app_tag == 16'hFFFF) { bins normal = {0}; bins escape = {1}; }
    x_mode_err : cross cp_mode, cp_err { ignore_bins wr_err = binsof(cp_mode.write) && !binsof(cp_err.none); }
  endgroup

  function new (string name, uvm_component parent);
    super.new(name,parent);
    cg = new();
  endfunction

  function void write ( nvme_rel_item t);
    cg.sample(t);
  endfunction

  function void report_phase (uvm_phase phase);
    `uvm_info("COV",$sformatf("Coverage = %0.2f%%", cg.get_inst_coverage()), UVM_LOW)
  endfunction
endclass
