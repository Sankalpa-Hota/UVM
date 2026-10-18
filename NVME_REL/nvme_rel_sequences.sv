class nvme_rel_sequences extends uvm_sequence #(nvme_rel_item);
  `uvm_object_utils(nvme_rel_sequences)
  int num_items = 200;
  function new (string name = "nvme_rel_sequences");
    super.new(name);
  endfunction

  task body;
    repeat (num_items) begin
      req=nvme_rel_item::type_id::create("req");
      start_item(req);
      if(!req.randomize()) `uvm_fatal("SEQ","Randomization failed");
      finish_item(req);
      end
  endtask
endclass

// known answer first: the FIPS-197 block on the write path, then the same block on the read path with correct PI
class nvme_rel_kat_seq extends uvm_sequence #(nvme_rel_item);
  `uvm_object_utils(nvme_rel_kat_seq)
  function new (string name = "nvme_rel_kat_seq");
    super.new(name);
  endfunction

  task body;
    for (int m = 0; m < 2; m++) begin
      req = new("req");                          // new(), not create(): a factory override must never change known answers
      start_item(req);
      req.c_mode.constraint_mode(0);             // directed values: switch the random distributions off
      req.c_pattern.constraint_mode(0);
      req.c_app.constraint_mode(0);
      req.c_good.constraint_mode(0);             // known answers are always clean blocks, even under an error override
      if (!req.randomize() with { mode == m; pattern == 0; app_tag == 16'h1234;
                                  bad_guard16 == 0; bad_guard32 == 0; bad_reftag == 0; bad_parity == 0; })
        `uvm_fatal("SEQ", "KAT randomization failed")
      req.data = FIPS_PT;                        // fixed known-answer block and key
      req.key  = FIPS_KEY;
      req.post_randomize();                      // recompute the PI for this data
      finish_item(req);
    end
  endtask
endclass
