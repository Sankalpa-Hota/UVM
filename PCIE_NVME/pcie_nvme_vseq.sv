// virtual sequence: back-pressure on the NVMe side (forever, in the background) + TLP traffic on the PCIe side
class pcie_nvme_vseq extends uvm_sequence;
  `uvm_object_utils(pcie_nvme_vseq)
  `uvm_declare_p_sequencer(pcie_nvme_vseqr)
  int num_tlps = 150;

  function new (string name = "pcie_nvme_vseq");
    super.new(name);
  endfunction

  task body;
    nvme_sequences bp  = nvme_sequences::type_id::create("bp");
    tlp_sequences  tlp = tlp_sequences::type_id::create("tlp");
    tlp.num_items = num_tlps;
    fork
      bp.start(p_sequencer.nvme_sqr);          // never ends: random ready
    join_none
    tlp.start(p_sequencer.tlp_sqr);            // returns when every TLP was sent
  endtask
endclass
