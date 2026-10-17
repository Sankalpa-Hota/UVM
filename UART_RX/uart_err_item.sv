// error packet: same item, one error forced; the test swaps it in with a factory override, no sequence/driver change
class uart_err_item extends uart_item;
  `uvm_object_utils(uart_err_item)

  // same constraint NAME as the parent -> replaces the parent's c_good instead of adding to it
  // exactly one error per frame: parity error or framing error
  constraint c_good { parity_err != frame_err; }

  function new ( string name = "uart_err_item");
   super.new(name);
 endfunction

 endclass
