// error block: exactly one PI/parity field is wrong; the test swaps it in with a factory override
class nvme_rel_err_item extends nvme_rel_item;
  `uvm_object_utils(nvme_rel_err_item)

  // same name as the parent -> REPLACES c_good (constraint 9); c_err_mode then forces the read path
  constraint c_good { $countones({bad_guard16, bad_guard32, bad_reftag, bad_parity}) == 1; }

  // error blocks are read-path blocks (constraint 6): replaces the parent's 50/50 mode distribution
  constraint c_mode { mode == 1; }

  function new ( string name = "nvme_rel_err_item");
   super.new(name);
 endfunction
 endclass
