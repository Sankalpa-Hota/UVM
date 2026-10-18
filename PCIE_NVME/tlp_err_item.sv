// error TLP: exactly one problem; the test swaps it in with a factory override
class tlp_err_item extends tlp_item;
  `uvm_object_utils(tlp_err_item)

  // same name as the parent -> REPLACES c_good (still constraint 9)
  constraint c_good { $countones({bad_len, bad_type, bad_addr}) == 1; }

  function new ( string name = "tlp_err_item");
   super.new(name);
 endfunction
 endclass
