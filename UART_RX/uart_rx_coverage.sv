class uart_rx_coverage extends uvm_subscriber #(uart_item);
  `uvm_component_utils(uart_rx_coverage)

  covergroup cg with function sample(uart_item t);
    cp_data  : coverpoint t.data   { bins zero = {0};
                                     bins low  = {[1:127]};
                                     bins high = {[128:254]};
                                     bins max  = {255};}
    cp_parity: coverpoint t.parity { bins zero = {0};
                                     bins one  = {1};}
    cp_stop  : coverpoint t.stop   { bins frame_err = {0};
                                     bins ok        = {1};}
  endgroup

  function new (string name, uvm_component parent);
    super.new(name,parent);
    cg = new();
  endfunction

  function void write ( uart_item t);
    cg.sample(t);
   endfunction

  function void report_phase (uvm_phase phase);
    `uvm_info("COV",$sformatf("Coverage = %0.2f%%", cg.get_inst_coverage()), UVM_LOW)

   endfunction
   endclass
