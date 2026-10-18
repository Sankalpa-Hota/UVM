class adder_item extends uvm_sequence_item;
  `uvm_object_utils(adder_item)
  rand bit [N-1:0] A;
  rand bit [N-1:0] B;
  rand bit C;
  bit in_valid;
  rand int idle_cycles;

  bit [N:0] sum; //to be observed by monitor
  bit carry;
  bit out_valid;


  constraint c_main { A inside {[0:15]};
                     B inside {[0:7]};
                     C dist {0:= 40 , 1 := 60};}

  constraint c_idle { idle_cycles inside {[0:3]}; }

  constraint c_no_b2b { idle_cycles != 0; }


  function new ( string name = "adder_item");
   super.new(name);
 endfunction


  function void do_copy (uvm_object rhs);
    adder_item r;
    if (!$cast(r, rhs)) `uvm_fatal ("Txn","Unable to cast ");
    super.do_copy(rhs);
    A = r.A ;B =r.B; C = r.C ; in_valid = r.in_valid; idle_cycles = r.idle_cycles ; sum = r.sum ; carry = r.carry;out_valid = r.out_valid;
  endfunction


  function bit do_compare ( uvm_object rhs , uvm_comparer comparer);
    adder_item r;
    if (!$cast(r, rhs)) return 0;
    return super.do_compare(rhs,comparer) && sum == r.sum && carry == r.carry;
  endfunction

 endclass
