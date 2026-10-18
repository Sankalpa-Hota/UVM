// [REG] new: one register access (read or write)
class reg_item extends uvm_sequence_item;
  `uvm_object_utils(reg_item)
  rand bit        wr;
  rand bit [3:0]  addr;
  rand bit [31:0] data;           // write data, or read data filled in by the driver/monitor

  constraint c_addr { addr inside {4'h0, 4'h4, 4'h8, 4'hC}; }

  function new ( string name = "reg_item");
   super.new(name);
 endfunction
 endclass
