// what the NVMe side does with its ready signal for a while (back-pressure)
class nvme_item extends uvm_sequence_item;
  `uvm_object_utils(nvme_item)
  rand bit ready;
  rand int cycles;

  constraint c_ready { ready dist {1 := 70, 0 := 30}; cycles inside {[1:4]}; }   // 10

  function new ( string name = "nvme_item");
   super.new(name);
 endfunction
 endclass
