class async_fifo_sequences extends uvm_sequence #(async_fifo_item);
  `uvm_object_utils(async_fifo_sequences)
  int num_items = 200;
  function new (string name = "async_fifo_sequences");
    super.new(name);
  endfunction

  //run time
  task body;
    repeat (num_items) begin
      req=async_fifo_item::type_id::create("req");
      start_item(req);
      if(!req.randomize()) `uvm_fatal("SEQ","Randomization failed");
      finish_item(req);

      end
  endtask
endclass
