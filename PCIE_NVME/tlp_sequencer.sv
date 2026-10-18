class tlp_sequencer extends uvm_sequencer #(tlp_item);
  `uvm_component_utils(tlp_sequencer)
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
endclass
