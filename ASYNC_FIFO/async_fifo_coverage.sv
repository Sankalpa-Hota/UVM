class async_fifo_coverage extends uvm_subscriber #(async_fifo_item);
  `uvm_component_utils(async_fifo_coverage)

  covergroup cg with function sample(async_fifo_item t);
    cp_op  : coverpoint t.wr   { bins rd = {0};
                                 bins wr = {1};}
    cp_data: coverpoint t.data { bins zero = {0};
                                 bins low  = {[1:127]};
                                 bins high = {[128:254]};
                                 bins max  = {255};}
    x_op_data : cross cp_op, cp_data;
  endgroup

  function new (string name, uvm_component parent);
    super.new(name,parent);
    cg = new();
  endfunction

  function void write ( async_fifo_item t);
    cg.sample(t);
   endfunction

  function void report_phase (uvm_phase phase);
    `uvm_info("COV",$sformatf("Coverage = %0.2f%%", cg.get_inst_coverage()), UVM_LOW)

   endfunction
   endclass
