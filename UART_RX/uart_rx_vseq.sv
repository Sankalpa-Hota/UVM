// virtual sequence: the whole test scenario across both interfaces (registers on AXI-Lite + frames on UART)
class uart_rx_vseq extends uvm_sequence;
  `uvm_object_utils(uart_rx_vseq)
  // creates p_sequencer = this sequence's sequencer cast to uart_rx_vseqr, so we can reach its handles
  `uvm_declare_p_sequencer(uart_rx_vseqr)

  int num_frames = 30;

  function new (string name = "uart_rx_vseq");
    super.new(name);
  endfunction

  task body;
    uvm_status_e         status;
    uvm_reg_data_t       rx_cnt, err_cnt, rx_data;
    uvm_reg_hw_reset_seq rst_seq;
    uart_sequences       useq;
    uart_rx_reg_block    rm;
    rm = p_sequencer.regmodel;

    // 1. built-in RAL sequence: reads every register and checks it against its reset value in the model
    rst_seq = uvm_reg_hw_reset_seq::type_id::create("rst_seq");
    rst_seq.model = rm;
    rst_seq.start(null);    // null: register sequences go out through the map's sequencer (axil_sqr), not this one

    // 2. program the DUT. write() = one front-door bus write of the whole register
    rm.BAUD_DIV.write(status, p_sequencer.cfg.baud_div, .parent(this));
    // set() only changes the model's desired value; update() writes the register only if desired != mirrored
    rm.CTRL.EN.set(1'b1);
    rm.CTRL.PARITY_ODD.set(p_sequencer.cfg.parity_odd);
    rm.CTRL.update(status, .parent(this));
    // mirror(UVM_CHECK) = read the register and error if it differs from the model's value
    rm.CTRL.mirror(status, UVM_CHECK, .parent(this));

    // 3. traffic on the UART agent and a register read on the AXI agent at the same time
    useq = uart_sequences::type_id::create("useq");
    useq.num_items = num_frames;
    fork
      useq.start(p_sequencer.uart_sqr);
      rm.ID.mirror(status, UVM_CHECK, .parent(this));
    join

    // 4. read status; the scoreboard compares each read with its own expected counts
    rm.RX_CNT .read(status, rx_cnt,  .parent(this));
    rm.ERR_CNT.read(status, err_cnt, .parent(this));
    rm.RX_DATA.read(status, rx_data, .parent(this));
    `uvm_info("VSEQ", $sformatf("RX_CNT=%0d PARITY_ERR=%0d FRAME_ERR=%0d RX_DATA=%0h",
              rx_cnt, err_cnt[7:0], err_cnt[15:8], rx_data), UVM_LOW)
  endtask
endclass
