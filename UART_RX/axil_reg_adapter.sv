// adapter = translator between the register model and the bus agent
// reg2bus: CTRL.write()/read() -> axil_item for the axil sequencer; bus2reg: axil_item -> result for the register model
class axil_reg_adapter extends uvm_reg_adapter;
  `uvm_object_utils(axil_reg_adapter)

  function new(string name = "axil_reg_adapter");
    super.new(name);
    supports_byte_enable = 0;
    provides_responses   = 0;   // driver writes data/resp back into the same item, no separate response item
  endfunction

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    axil_item t = axil_item::type_id::create("t");
    t.wr   = (rw.kind == UVM_WRITE);
    t.addr = rw.addr;
    t.data = rw.data;
    return t;
  endfunction

  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    axil_item t;
    if (!$cast(t, bus_item)) `uvm_fatal("ADAPTER", "bus item is not axil_item")
    rw.kind   = t.wr ? UVM_WRITE : UVM_READ;
    rw.addr   = t.addr;
    rw.data   = t.data;
    rw.status = (t.resp == 2'b00) ? UVM_IS_OK : UVM_NOT_OK;
  endfunction
endclass
