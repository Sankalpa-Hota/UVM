class nvme_sequencer extends uvm_sequencer #(nvme_item);
  `uvm_component_utils(nvme_sequencer)
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
endclass
