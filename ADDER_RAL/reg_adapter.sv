// [RAL] new: translator between register operations and reg_item (the only bus-specific RAL code)
class reg_adapter extends uvm_reg_adapter;
  `uvm_object_utils(reg_adapter)

  function new(string name = "reg_adapter");
    super.new(name);
    supports_byte_enable = 0;
    provides_responses   = 0;          // the driver writes read data back into the same item
  endfunction

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    reg_item t = reg_item::type_id::create("t");
    t.wr   = (rw.kind == UVM_WRITE);
    t.addr = rw.addr;
    t.data = rw.data;
    return t;
  endfunction

  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    reg_item t;
    if (!$cast(t, bus_item)) `uvm_fatal("ADAPTER", "not a reg_item")
    rw.kind   = t.wr ? UVM_WRITE : UVM_READ;
    rw.addr   = t.addr;
    rw.data   = t.data;
    rw.status = UVM_IS_OK;             // this simple bus has no error response
  endfunction
endclass
