class uart_item extends uvm_sequence_item;
  `uvm_object_utils(uart_item)
  rand bit [7:0] data;
  rand bit parity_err;            // 1 = driver sends the wrong parity bit
  rand bit frame_err;             // 1 = driver sends stop bit = 0
  rand int idle_bits;

  bit parity; //to be observed by monitor
  bit stop;


  constraint c_good { parity_err == 0; frame_err == 0; }

  constraint c_idle { idle_bits inside {[1:4]}; }


  function new ( string name = "uart_item");
   super.new(name);
 endfunction


  function void do_copy (uvm_object rhs);
    uart_item r;
    if (!$cast(r, rhs)) `uvm_fatal ("Txn","Unable to cast ");
    super.do_copy(rhs);
    data = r.data; parity_err = r.parity_err; frame_err = r.frame_err; idle_bits = r.idle_bits; parity = r.parity; stop = r.stop;
  endfunction


  function bit do_compare ( uvm_object rhs , uvm_comparer comparer);
    uart_item r;
    if (!$cast(r, rhs)) return 0;
    return super.do_compare(rhs,comparer) && data == r.data;
  endfunction

 endclass
