class async_fifo_item extends uvm_sequence_item;
  `uvm_object_utils(async_fifo_item)
  rand bit wr;                    // 1 = write, 0 = read
  rand bit [DATA_W-1:0] data;     // write data, or read data observed by monitor
  rand int idle_cycles;

  constraint c_main { wr dist {1 := 60, 0 := 40}; }

  constraint c_idle { idle_cycles inside {[1:3]}; }


  function new ( string name = "async_fifo_item");
   super.new(name);
 endfunction


  function void do_copy (uvm_object rhs);
    async_fifo_item r;
    if (!$cast(r, rhs)) `uvm_fatal ("Txn","Unable to cast ");
    super.do_copy(rhs);
    wr = r.wr; data = r.data; idle_cycles = r.idle_cycles;
  endfunction


  function bit do_compare ( uvm_object rhs , uvm_comparer comparer);
    async_fifo_item r;
    if (!$cast(r, rhs)) return 0;
    return super.do_compare(rhs,comparer) && data == r.data;
  endfunction

 endclass
