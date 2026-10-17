`uvm_analysis_imp_decl(_in)
`uvm_analysis_imp_decl(_out)
`uvm_analysis_imp_decl(_axil)

class uart_rx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uart_rx_scoreboard)

  // _in: frames seen on the rx line, _out: bytes the DUT produced, _axil: register writes/reads on the bus
  uvm_analysis_imp_in   #(uart_item, uart_rx_scoreboard) imp_in;
  uvm_analysis_imp_out  #(uart_item, uart_rx_scoreboard) imp_out;
  uvm_analysis_imp_axil #(axil_item, uart_rx_scoreboard) imp_axil;

  bit [7:0]    exp[$];
  bit          en, parity_odd;
  bit [15:0]   n_good;
  bit [7:0]    n_parity, n_frame, last_byte;
  int unsigned n_fail, n_pass, n_reg_chk;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp_in   = new("imp_in",   this);
    imp_out  = new("imp_out",  this);
    imp_axil = new("imp_axil", this);
  endfunction

  // same decision as the DUT: stop=0 -> frame error, else wrong parity -> parity error, else good byte
  function void write_in(uart_item txn);
    if (!en) return;
    if (txn.stop == 1'b0)
      n_frame++;
    else if ((^txn.data ^ txn.parity) != parity_odd)
      n_parity++;
    else begin
      n_good++;
      last_byte = txn.data;
      exp.push_back(txn.data);
    end
  endfunction

  function void write_out(uart_item txn);
    bit [7:0] expected;
    if (exp.size() == 0) begin
      n_fail++;
      `uvm_error("SB", $sformatf("DUT output %0h with no good frame on the line", txn.data))
      return;
    end
    expected = exp.pop_front();
    if (txn.data !== expected) begin
      n_fail++;
      `uvm_error("SB", $sformatf("exp byte=%0h | act byte=%0h", expected, txn.data))
    end
    else begin
      n_pass++;
    end
  endfunction

  // writes to CTRL tell the scoreboard the mode; reads of status registers are checked against its own counts
  function void write_axil(axil_item txn);
    if (txn.resp != 2'b00) begin
      n_fail++;
      `uvm_error("SB", $sformatf("bus error resp=%0d at addr %0h", txn.resp, txn.addr))
      return;
    end
    if (txn.wr) begin
      if (txn.addr == CTRL_ADDR) begin
        en         = txn.data[0];
        parity_odd = txn.data[1];
      end
      return;
    end
    case (txn.addr)
      RX_CNT_ADDR : check_reg("RX_CNT",  txn.data, {16'b0, n_good});
      ERR_CNT_ADDR: check_reg("ERR_CNT", txn.data, {16'b0, n_frame, n_parity});
      RX_DATA_ADDR: check_reg("RX_DATA", txn.data, {24'b0, last_byte});
      ID_ADDR     : check_reg("ID",      txn.data, 32'h0000_C0DE);
      default     : ;
    endcase
  endfunction

  function void check_reg(string name, bit [31:0] act, bit [31:0] expected);
    n_reg_chk++;
    if (act !== expected) begin
      n_fail++;
      `uvm_error("SB", $sformatf("%s read %0h, expected %0h", name, act, expected))
    end
    else
      `uvm_info("SB", $sformatf("%s read %0h OK", name, act), UVM_LOW)
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (exp.size() != 0)
      `uvm_error("SB", $sformatf("%0d good frame(s) never produced an output", exp.size()))
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SB", $sformatf("good=%0d parity_err=%0d frame_err=%0d byte_pass=%0d reg_checks=%0d fail=%0d",
                              n_good, n_parity, n_frame, n_pass, n_reg_chk, n_fail), UVM_LOW)
    if (n_reg_chk > 0 && n_fail == 0 && exp.size() == 0)
      `uvm_info("SB", "Test PASS", UVM_LOW)
    else
      `uvm_error("SB", "Test FAIL")
  endfunction
endclass
