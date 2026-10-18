// [VSEQ] new: plain register sequences (no RAL here) — you give the address and data yourself
class reg_write_seq extends uvm_sequence #(reg_item);
  `uvm_object_utils(reg_write_seq)
  bit [3:0]  addr;
  bit [31:0] data;
  function new (string name = "reg_write_seq"); super.new(name); endfunction
  task body;
    req = reg_item::type_id::create("req");
    start_item(req);
    if (!req.randomize() with { wr == 1; addr == local::addr; data == local::data; }) `uvm_fatal("SEQ", "randomize failed")
    finish_item(req);
  endtask
endclass

class reg_read_seq extends uvm_sequence #(reg_item);
  `uvm_object_utils(reg_read_seq)
  bit [3:0]  addr;
  bit [31:0] data;                                    // read result, filled in by the driver
  function new (string name = "reg_read_seq"); super.new(name); endfunction
  task body;
    req = reg_item::type_id::create("req");
    start_item(req);
    if (!req.randomize() with { wr == 0; addr == local::addr; }) `uvm_fatal("SEQ", "randomize failed")
    finish_item(req);
    data = req.data;
  endtask
endclass
