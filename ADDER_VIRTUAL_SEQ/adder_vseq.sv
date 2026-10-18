// [VSEQ] new: the virtual sequence — one scenario across BOTH agents (registers + additions)
class adder_vseq extends uvm_sequence;
  `uvm_object_utils(adder_vseq)
  `uvm_declare_p_sequencer(adder_vseqr)              // p_sequencer.adder_sqr / p_sequencer.reg_sqr

  function new (string name = "adder_vseq");
    super.new(name);
  endfunction

  task body;
    reg_write_seq   wr;
    reg_read_seq    rd;
    adder_sequences add;

    // 1. registers first: enable the adder (write 1 to CTRL at 0x0)
    wr = reg_write_seq::type_id::create("wr_en");
    wr.addr = 4'h0;  wr.data = 1;
    wr.start(p_sequencer.reg_sqr);

    // 2. in PARALLEL: 50 additions on the adder agent, and ID reads on the register agent
    fork
      begin
        add = adder_sequences::type_id::create("add");
        add.num_items = 50;
        add.start(p_sequencer.adder_sqr);
      end
      repeat (5) begin
        rd = reg_read_seq::type_id::create("rd_id");
        rd.addr = 4'hC;
        rd.start(p_sequencer.reg_sqr);
        #200ns;
      end
    join
    #50ns;

    // 3. disable, then send 5 more additions: the DUT must ignore them
    wr = reg_write_seq::type_id::create("wr_dis");
    wr.addr = 4'h0;  wr.data = 0;
    wr.start(p_sequencer.reg_sqr);
    add = adder_sequences::type_id::create("add_off");
    add.num_items = 5;
    add.start(p_sequencer.adder_sqr);
    #50ns;

    // 4. read the status registers; the scoreboard checks them
    rd = reg_read_seq::type_id::create("rd_cnt");
    rd.addr = 4'h4;  rd.start(p_sequencer.reg_sqr);
    `uvm_info("VSEQ", $sformatf("ADD_CNT = %0d (50 enabled additions, 5 ignored)", rd.data), UVM_LOW)
    rd = reg_read_seq::type_id::create("rd_sum");
    rd.addr = 4'h8;  rd.start(p_sequencer.reg_sqr);
  endtask
endclass
