class tlp_sequences extends uvm_sequence #(tlp_item);
  `uvm_object_utils(tlp_sequences)
  int num_items = 150;
  function new (string name = "tlp_sequences");
    super.new(name);
  endfunction

  task body;
    repeat (num_items) begin
      req=tlp_item::type_id::create("req");
      start_item(req);
      if(!req.randomize()) `uvm_fatal("SEQ","Randomization failed");
      finish_item(req);
      end
  endtask
endclass
