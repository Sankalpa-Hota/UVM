class adder_sequences extends uvm_sequence #(adder_item);
  `uvm_object_utils(adder_sequences)
  int num_items = 100;
  function new (string name = "adder_sequences");
    super.new(name);
  endfunction

  //run time
  task body;
    repeat (num_items) begin
      req=adder_item::type_id::create("req");
      start_item(req);
      if(!req.randomize()) `uvm_fatal("SEQ","Randomization failed");
      finish_item(req);

      end
  endtask
endclass
