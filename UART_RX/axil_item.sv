class axil_item extends uvm_sequence_item;
  `uvm_object_utils(axil_item)
  rand bit wr;
  rand bit [7:0]  addr;
  rand bit [31:0] data;

  bit [1:0] resp; //to be observed by driver/monitor


  function new ( string name = "axil_item");
   super.new(name);
 endfunction


  function void do_copy (uvm_object rhs);
    axil_item r;
    if (!$cast(r, rhs)) `uvm_fatal ("Txn","Unable to cast ");
    super.do_copy(rhs);
    wr = r.wr; addr = r.addr; data = r.data; resp = r.resp;
  endfunction


  function bit do_compare ( uvm_object rhs , uvm_comparer comparer);
    axil_item r;
    if (!$cast(r, rhs)) return 0;
    return super.do_compare(rhs,comparer) && data == r.data && resp == r.resp;
  endfunction

 endclass
