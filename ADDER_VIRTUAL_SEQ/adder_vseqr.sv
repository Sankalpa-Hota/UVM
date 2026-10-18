// [VSEQ] new: the virtual sequencer — drives nothing, only holds the two real sequencers
class adder_vseqr extends uvm_sequencer;
  `uvm_component_utils(adder_vseqr)
  adder_sequencer adder_sqr;
  reg_sequencer   reg_sqr;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
