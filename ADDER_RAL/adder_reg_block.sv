// [RAL] new: the register model — a description of the DUT's 4 registers (no pins, no bus code)
class ctrl_reg extends uvm_reg;
  `uvm_object_utils(ctrl_reg)
  rand uvm_reg_field EN;
  function new(string name = "ctrl_reg"); super.new(name, 32, UVM_NO_COVERAGE); endfunction
  virtual function void build();
    EN = uvm_reg_field::type_id::create("EN");
    EN.configure(this, 1, 0, "RW", 0, 1'b0, 1, 1, 0);         // 1 bit at bit 0, read/write, reset 0
  endfunction
endclass

class add_cnt_reg extends uvm_reg;
  `uvm_object_utils(add_cnt_reg)
  uvm_reg_field CNT;
  function new(string name = "add_cnt_reg"); super.new(name, 32, UVM_NO_COVERAGE); endfunction
  virtual function void build();
    CNT = uvm_reg_field::type_id::create("CNT");
    CNT.configure(this, 16, 0, "RO", 1, 16'h0, 1, 0, 0);      // volatile: hardware counts by itself
  endfunction
endclass

class last_sum_reg extends uvm_reg;
  `uvm_object_utils(last_sum_reg)
  uvm_reg_field SUM;
  function new(string name = "last_sum_reg"); super.new(name, 32, UVM_NO_COVERAGE); endfunction
  virtual function void build();
    SUM = uvm_reg_field::type_id::create("SUM");
    SUM.configure(this, N + 1, 0, "RO", 1, '0, 1, 0, 0);       // volatile
  endfunction
endclass

class id_reg extends uvm_reg;
  `uvm_object_utils(id_reg)
  uvm_reg_field ID;
  function new(string name = "id_reg"); super.new(name, 32, UVM_NO_COVERAGE); endfunction
  virtual function void build();
    ID = uvm_reg_field::type_id::create("ID");
    ID.configure(this, 32, 0, "RO", 0, 32'h0000_ADD0, 1, 0, 0);
  endfunction
endclass

class adder_reg_block extends uvm_reg_block;
  `uvm_object_utils(adder_reg_block)
  rand ctrl_reg     CTRL;
       add_cnt_reg  ADD_CNT;
       last_sum_reg LAST_SUM;
       id_reg       ID;

  function new(string name = "adder_reg_block"); super.new(name, UVM_NO_COVERAGE); endfunction

  virtual function void build();
    default_map = create_map("default_map", 'h0, 4, UVM_LITTLE_ENDIAN);   // base 0, 4-byte registers
    CTRL     = ctrl_reg    ::type_id::create("CTRL");     CTRL    .configure(this); CTRL    .build();
    ADD_CNT  = add_cnt_reg ::type_id::create("ADD_CNT");  ADD_CNT .configure(this); ADD_CNT .build();
    LAST_SUM = last_sum_reg::type_id::create("LAST_SUM"); LAST_SUM.configure(this); LAST_SUM.build();
    ID       = id_reg      ::type_id::create("ID");       ID      .configure(this); ID      .build();
    default_map.add_reg(CTRL,     'h0, "RW");
    default_map.add_reg(ADD_CNT,  'h4, "RO");
    default_map.add_reg(LAST_SUM, 'h8, "RO");
    default_map.add_reg(ID,       'hC, "RO");
    lock_model();
  endfunction
endclass
