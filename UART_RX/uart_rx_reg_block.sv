// register model (RAL): one uvm_reg class per DUT register, fields inside, all placed in a block + address map
// field.configure(parent, size, lsb, access, volatile, reset, has_reset, is_rand, individually_accessible)
// volatile = 1 -> hardware changes it by itself (counters), so the model can't predict it from writes

class uart_rx_ctrl_reg extends uvm_reg;
  `uvm_object_utils(uart_rx_ctrl_reg)
  rand uvm_reg_field EN;
  rand uvm_reg_field PARITY_ODD;

  // new(name, register width in bits, coverage model)
  function new(string name = "uart_rx_ctrl_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    EN         = uvm_reg_field::type_id::create("EN");
    PARITY_ODD = uvm_reg_field::type_id::create("PARITY_ODD");
    EN        .configure(this, 1, 0, "RW", 0, 1'b0, 1, 1, 0);
    PARITY_ODD.configure(this, 1, 1, "RW", 0, 1'b0, 1, 1, 0);
  endfunction
endclass

class uart_rx_baud_reg extends uvm_reg;
  `uvm_object_utils(uart_rx_baud_reg)
  rand uvm_reg_field DIV;

  function new(string name = "uart_rx_baud_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    DIV = uvm_reg_field::type_id::create("DIV");
    DIV.configure(this, 16, 0, "RW", 0, 16'd16, 1, 1, 0);
  endfunction
endclass

class uart_rx_rx_cnt_reg extends uvm_reg;
  `uvm_object_utils(uart_rx_rx_cnt_reg)
  uvm_reg_field CNT;

  function new(string name = "uart_rx_rx_cnt_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    CNT = uvm_reg_field::type_id::create("CNT");
    CNT.configure(this, 16, 0, "RO", 1, 16'd0, 1, 0, 0);
  endfunction
endclass

class uart_rx_err_cnt_reg extends uvm_reg;
  `uvm_object_utils(uart_rx_err_cnt_reg)
  uvm_reg_field PARITY_ERR;
  uvm_reg_field FRAME_ERR;

  function new(string name = "uart_rx_err_cnt_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    PARITY_ERR = uvm_reg_field::type_id::create("PARITY_ERR");
    FRAME_ERR  = uvm_reg_field::type_id::create("FRAME_ERR");
    PARITY_ERR.configure(this, 8, 0, "RO", 1, 8'd0, 1, 0, 0);
    FRAME_ERR .configure(this, 8, 8, "RO", 1, 8'd0, 1, 0, 0);
  endfunction
endclass

class uart_rx_rx_data_reg extends uvm_reg;
  `uvm_object_utils(uart_rx_rx_data_reg)
  uvm_reg_field DATA;

  function new(string name = "uart_rx_rx_data_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    DATA = uvm_reg_field::type_id::create("DATA");
    DATA.configure(this, 8, 0, "RO", 1, 8'd0, 1, 0, 0);
  endfunction
endclass

class uart_rx_id_reg extends uvm_reg;
  `uvm_object_utils(uart_rx_id_reg)
  uvm_reg_field ID;

  function new(string name = "uart_rx_id_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    ID = uvm_reg_field::type_id::create("ID");
    ID.configure(this, 32, 0, "RO", 0, 32'h0000_C0DE, 1, 0, 0);
  endfunction
endclass

class uart_rx_reg_block extends uvm_reg_block;
  `uvm_object_utils(uart_rx_reg_block)

  rand uart_rx_ctrl_reg    CTRL;
  rand uart_rx_baud_reg    BAUD_DIV;
       uart_rx_rx_cnt_reg  RX_CNT;
       uart_rx_err_cnt_reg ERR_CNT;
       uart_rx_rx_data_reg RX_DATA;
       uart_rx_id_reg      ID;

  function new(string name = "uart_rx_reg_block");
    super.new(name, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    // create_map(name, base address, bus width in bytes, endianness)
    default_map = create_map("default_map", 'h0, 4, UVM_LITTLE_ENDIAN);

    CTRL     = uart_rx_ctrl_reg   ::type_id::create("CTRL");
    BAUD_DIV = uart_rx_baud_reg   ::type_id::create("BAUD_DIV");
    RX_CNT   = uart_rx_rx_cnt_reg ::type_id::create("RX_CNT");
    ERR_CNT  = uart_rx_err_cnt_reg::type_id::create("ERR_CNT");
    RX_DATA  = uart_rx_rx_data_reg::type_id::create("RX_DATA");
    ID       = uart_rx_id_reg     ::type_id::create("ID");

    // configure(parent block, register file, hdl path) then build() creates the fields
    CTRL    .configure(this, null, ""); CTRL    .build();
    BAUD_DIV.configure(this, null, ""); BAUD_DIV.build();
    RX_CNT  .configure(this, null, ""); RX_CNT  .build();
    ERR_CNT .configure(this, null, ""); ERR_CNT .build();
    RX_DATA .configure(this, null, ""); RX_DATA .build();
    ID      .configure(this, null, ""); ID      .build();

    // add_reg(register, offset, access through this map)
    default_map.add_reg(CTRL,     CTRL_ADDR,    "RW");
    default_map.add_reg(BAUD_DIV, BAUD_ADDR,    "RW");
    default_map.add_reg(RX_CNT,   RX_CNT_ADDR,  "RO");
    default_map.add_reg(ERR_CNT,  ERR_CNT_ADDR, "RO");
    default_map.add_reg(RX_DATA,  RX_DATA_ADDR, "RO");
    default_map.add_reg(ID,       ID_ADDR,      "RO");

    // lock: no more registers can be added; addresses are final
    lock_model();
  endfunction
endclass
