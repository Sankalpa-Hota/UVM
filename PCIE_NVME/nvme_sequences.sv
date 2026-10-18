// background back-pressure: runs forever, started with fork...join_none by the virtual sequence
class nvme_sequences extends uvm_sequence #(nvme_item);
  `uvm_object_utils(nvme_sequences)
  function new (string name = "nvme_sequences");
    super.new(name);
  endfunction

  task body;
    forever begin
      req=nvme_item::type_id::create("req");
      start_item(req);
      if(!req.randomize()) `uvm_fatal("SEQ","Randomization failed");
      finish_item(req);
    end
  endtask
endclass
