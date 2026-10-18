class pcie_nvme_agent_cfg extends uvm_object;
  `uvm_object_utils(pcie_nvme_agent_cfg)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  bit coverage_en = 1;

  function new(string name = "pcie_nvme_agent_cfg");
    super.new(name);
  endfunction
endclass
