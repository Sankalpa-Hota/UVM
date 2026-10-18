class adder_coverage extends uvm_subscriber #(adder_item);
  `uvm_component_utils(adder_coverage)

  function new (string name, uvm_component parent);
    super.new(name,parent);
    cg = new();
  endfunction

  covergroup cg with function sample(adder_item t);
    cp_A: coverpoint t.A { bins zero = {0};
                           bins low  = {[1:7]};
                           bins high = {[8:15]};}
    cp_B: coverpoint t.B { bins zero = {0};
                           bins low  = {[1:7]};
                           bins high = {[8:15]};}
    cp_C: coverpoint t.C { bins zero = {0};
                           bins one  = {1};}
    x_AB : cross cp_A,cp_B;
  endgroup

  function void write ( adder_item txn);
    cg.sample(txn);
   endfunction

  function void report_phase (uvm_phase phase);
    `uvm_info("COV",$sformatf("Coverage = %0.2f%%", cg.get_inst_coverage()), UVM_LOW)

   endfunction
   endclass
