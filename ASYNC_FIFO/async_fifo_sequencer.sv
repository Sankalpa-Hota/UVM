class async_fifo_sequencer extends uvm_sequencer #(async_fifo_item);
  `uvm_component_utils(async_fifo_sequencer)
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
endclass
