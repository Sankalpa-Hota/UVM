class pcie_nvme_coverage extends uvm_subscriber #(tlp_item);
  `uvm_component_utils(pcie_nvme_coverage)

  covergroup cg with function sample(tlp_item t);
    cp_fmt    : coverpoint t.fmt { bins mwr3 = {3'b010}; bins mwr4 = {3'b011}; bins no_data = {3'b000}; }
    cp_target : coverpoint (t.addr >= WIN_BASE && t.addr < WIN_BASE + 4096 ? 0 :
                            t.addr >= DB_BASE  && t.addr < DB_BASE + 32 ? 1 : 2) {
                  bins window = {0}; bins doorbell = {1}; bins unmapped = {2}; }
    cp_len    : coverpoint t.length { bins one = {1}; bins few = {[2:7]}; bins many = {[8:31]}; bins max = {32}; }
    cp_first  : coverpoint t.first_be { bins full = {4'hF}; bins partial = {4'hE, 4'hC, 4'h8}; bins other = default; }
    x_len_tgt : cross cp_len, cp_target { ignore_bins db_long = binsof(cp_target.doorbell) && !binsof(cp_len.one); }
  endgroup

  function new (string name, uvm_component parent);
    super.new(name,parent);
    cg = new();
  endfunction

  function void write ( tlp_item t);
    cg.sample(t);
  endfunction

  function void report_phase (uvm_phase phase);
    `uvm_info("COV",$sformatf("Coverage = %0.2f%%", cg.get_inst_coverage()), UVM_LOW)
  endfunction
endclass
