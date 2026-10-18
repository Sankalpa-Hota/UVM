// virtual sequencer: only handles to the two real sequencers
class pcie_nvme_vseqr extends uvm_sequencer;
  `uvm_component_utils(pcie_nvme_vseqr)
  tlp_sequencer  tlp_sqr;
  nvme_sequencer nvme_sqr;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
