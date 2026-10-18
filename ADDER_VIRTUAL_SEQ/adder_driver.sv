class adder_driver extends uvm_driver #(adder_item);
  `uvm_component_utils(adder_driver)

  virtual adder_if #(N) vif;   // pointer to the real interface in tb_top (a class can't hold the interface itself)

  // constructor: (name, parent) places this component in the tree, e.g. uvm_test_top.env.ag.drv
  function new (string name , uvm_component parent);
    super.new(name , parent);
  endfunction

  function void build_phase ( uvm_phase phase);
    super.build_phase(phase);
    // get(this = start from my path, "" = exactly my path, "adder_if" = key used in set, vif = where it lands)
    if(!uvm_config_db# (virtual adder_if #(N))::get(this,"","adder_if",vif)) `uvm_fatal("DRV","virtual interface missing");
    endfunction

  task run_phase (uvm_phase phase);
    vif.driver_cb.A<= '0;
    vif.driver_cb.B<= '0;
    vif.driver_cb.C<= '0;
    vif.driver_cb.in_valid<= '0;
    wait (vif.rst_n === 1'b1);
    @(vif.driver_cb);
    forever begin
      // get_next_item: wait for the sequence's item (sequence is blocked in finish_item after start_item won the sequencer)
      seq_item_port.get_next_item(req);
      drive(req);
      // item_done: tells the sequencer this item is finished -> the sequence's finish_item returns
      seq_item_port.item_done();
    end
  endtask

  // drive through the clocking block (modport DRIVER view): driven just after the edge, so no race with the DUT
  task drive (adder_item item);
    repeat (item.idle_cycles) begin
     @(vif.driver_cb);
      vif.driver_cb.in_valid<= 1'b0;
    end
    vif.driver_cb.A<= item.A;
    vif.driver_cb.B<= item.B;
    vif.driver_cb.C<= item.C;
    vif.driver_cb.in_valid<= 1'b1;
    @(vif.driver_cb);
    vif.driver_cb.in_valid<= 1'b0;
  endtask
endclass
