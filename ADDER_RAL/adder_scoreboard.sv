// _decl creates a second imp type: a class can have only one write(), so _in calls write_in(), _out calls write_out()
`uvm_analysis_imp_decl(_in)
`uvm_analysis_imp_decl(_out)
`uvm_analysis_imp_decl(_reg)                     // [REG] third input: register accesses

class adder_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(adder_scoreboard)

  // analysis IMP = the RECEIVER side: #(item type, class that implements write_in/write_out)
  uvm_analysis_imp_in  #(adder_item, adder_scoreboard) imp_in;
  uvm_analysis_imp_out #(adder_item, adder_scoreboard) imp_out;
  uvm_analysis_imp_reg #(reg_item,   adder_scoreboard) imp_reg;   // [REG]

  bit          en;                // [REG] mirror of CTRL.EN as seen on the register bus
  bit [N:0]    last_sum;          // [REG] for LAST_SUM reads
  int unsigned n_ignored, n_reg_chk;

  adder_item   exp[$];
  int unsigned n_fail, n_pass, n_in, n_out;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp_in  = new("imp_in",  this);
    imp_out = new("imp_out", this);
    imp_reg = new("imp_reg", this);                                       // [REG]
  endfunction

  function adder_item predict(adder_item txn);
    adder_item txn_ex = adder_item::type_id::create("txn_ex");
    txn_ex.A = txn.A;  txn_ex.B = txn.B;  txn_ex.C = txn.C;
    txn_ex.sum   = txn.A + txn.B + txn.C;
    txn_ex.carry = txn_ex.sum[N];
    return txn_ex;
  endfunction

  function void write_in(adder_item txn);
    if (!en) begin n_ignored++; return; end                               // [REG] disabled: no result expected
    n_in++;
    exp.push_back(predict(txn));
  endfunction

  function void write_out(adder_item txn);
    adder_item expected;
    n_out++;
    if (exp.size() == 0) begin
      n_fail++;
      `uvm_error("SB", "output with no matching input")
      return;
    end
    expected = exp.pop_front();
    if (txn.sum !== expected.sum || txn.carry !== expected.carry) begin
      n_fail++;
      `uvm_error("SB", $sformatf("A=%0d B=%0d C=%0d | exp sum=%0d carry=%0d | act sum=%0d carry=%0d",
                                 expected.A, expected.B, expected.C,
                                 expected.sum, expected.carry, txn.sum, txn.carry))
    end
    else begin
      n_pass++;
    end
    last_sum = txn.sum;                                                   // [REG]
  endfunction

  // [REG] writes to CTRL change the mode; reads of the status registers are checked against our own counts
  function void write_reg(reg_item t);
    if (t.wr) begin
      if (t.addr == 4'h0) en = t.data[0];
      return;
    end
    case (t.addr)
      4'h4: check_reg("ADD_CNT",  t.data, n_out);
      4'h8: check_reg("LAST_SUM", t.data, last_sum);
      4'hC: check_reg("ID",       t.data, 32'h0000_ADD0);
      default: ;
    endcase
  endfunction

  function void check_reg(string name, bit [31:0] act, bit [31:0] expected);
    n_reg_chk++;
    if (act !== expected) begin
      n_fail++;
      `uvm_error("SB", $sformatf("%s read %0h, expected %0h", name, act, expected))
    end else
      `uvm_info("SB", $sformatf("%s read %0h OK", name, act), UVM_LOW)
  endfunction

  // check_phase: runs after run_phase; anything left in exp = an input whose output never came
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (exp.size() != 0)
      `uvm_error("SB", $sformatf("%0d input(s) never produced an output", exp.size()))
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SB", $sformatf("inputs=%0d outputs=%0d pass=%0d fail=%0d ignored(EN=0)=%0d register checks=%0d",
                              n_in, n_out, n_pass, n_fail, n_ignored, n_reg_chk), UVM_LOW)
    if (n_out > 0 && n_fail == 0 && exp.size() == 0)
      `uvm_info("SB", "Test PASS", UVM_LOW)
    else
      `uvm_error("SB", "Test FAIL")
  endfunction
endclass
