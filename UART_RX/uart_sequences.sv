class uart_sequences extends uvm_sequence #(uart_item);
  `uvm_object_utils(uart_sequences)
  int num_items = 30;
  function new (string name = "uart_sequences");
    super.new(name);
  endfunction

  //run time
  task body;
    repeat (num_items) begin
      req=uart_item::type_id::create("req");
      start_item(req);
      if(!req.randomize()) `uvm_fatal("SEQ","Randomization failed");
      finish_item(req);

      end
  endtask
endclass
