class adder_monitor extends uvm_monitor;
  `uvm_component_utils(adder_monitor)

  virtual adder_if #(N) vif;

  // analysis PORT = the SENDER side: ap.write(t) broadcasts t to every connected receiver (0..N), never blocks
  uvm_analysis_port #(adder_item) ap_in;
  uvm_analysis_port #(adder_item) ap_out;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db# (virtual adder_if #(N))::get(this,"","adder_if",vif)) `uvm_fatal("MON","Virtual interface not available");
    ap_in =new("ap_in",this);
    ap_out =new("ap_out",this);
  endfunction

  task run_phase(uvm_phase phase);
    adder_item txn_in;
    adder_item txn_out;
    wait (vif.rst_n === 1'b1);
    forever begin
      @(vif.mon_cb);                         // sample on each clock
      if (vif.mon_cb.in_valid === 1'b1) begin
        // new object per transaction: receivers keep the handle, reusing one would overwrite their copies
        txn_in = adder_item::type_id::create("txn_in");
        txn_in.A        = vif.mon_cb.A;
        txn_in.B        = vif.mon_cb.B;
        txn_in.C        = vif.mon_cb.C;
        txn_in.in_valid = 1'b1;
        ap_in.write(txn_in);
      end

      if (vif.mon_cb.out_valid === 1'b1) begin
        txn_out = adder_item::type_id::create("txn_out");
        txn_out.sum        = vif.mon_cb.sum;
        txn_out.carry        = vif.mon_cb.carry;
        txn_out.out_valid = 1'b1;
        ap_out.write(txn_out);
      end
    end
  endtask
endclass
