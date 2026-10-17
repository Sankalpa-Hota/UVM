class async_fifo_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(async_fifo_scoreboard)

  // TLM analysis FIFO = receiver with a built-in unbounded queue: monitor's write() just stores the item (never blocks),
  // the scoreboard pulls items later with get() in run_phase -> no write_*() callbacks and no _imp_decl needed
  uvm_tlm_analysis_fifo #(async_fifo_item) wr_fifo;
  uvm_tlm_analysis_fifo #(async_fifo_item) rd_fifo;

  int unsigned n_fail, n_pass, n_rd;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wr_fifo = new("wr_fifo", this);
    rd_fifo = new("rd_fifo", this);
  endfunction

  // every read must return the oldest write still unread, so wr_fifo itself is the reference model
  task run_phase(uvm_phase phase);
    async_fifo_item act, expected;
    forever begin
      rd_fifo.get(act);                     // get() blocks until the monitor has sent a read
      n_rd++;
      if (!wr_fifo.try_get(expected)) begin // try_get() never blocks: returns 0 if no write is waiting
        n_fail++;
        `uvm_error("SB", $sformatf("read data=%0h but nothing was written", act.data))
      end
      else if (act.data !== expected.data) begin
        n_fail++;
        `uvm_error("SB", $sformatf("exp data=%0h | act data=%0h", expected.data, act.data))
      end
      else begin
        n_pass++;
      end
    end
  endtask

  // check_phase: writes left in wr_fifo were never read; the FIFO can hold at most DEPTH of them
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (wr_fifo.used() > DEPTH)
      `uvm_error("SB", $sformatf("%0d writes never read, more than DEPTH=%0d -> data lost", wr_fifo.used(), DEPTH))
    else
      `uvm_info("SB", $sformatf("%0d writes still inside the FIFO at end of test", wr_fifo.used()), UVM_LOW)
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SB", $sformatf("reads=%0d pass=%0d fail=%0d left_in_fifo=%0d",
                              n_rd, n_pass, n_fail, wr_fifo.used()), UVM_LOW)
    if (n_rd > 0 && n_fail == 0 && wr_fifo.used() <= DEPTH)
      `uvm_info("SB", "Test PASS", UVM_LOW)
    else
      `uvm_error("SB", "Test FAIL")
  endfunction
endclass
