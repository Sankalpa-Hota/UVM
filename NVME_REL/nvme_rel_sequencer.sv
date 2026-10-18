class nvme_rel_sequencer extends uvm_sequencer #(nvme_rel_item);
  `uvm_component_utils(nvme_rel_sequencer)
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
endclass
