class nvme_rel_item extends uvm_sequence_item;
  `uvm_object_utils(nvme_rel_item)
  rand bit         mode;             // 0 = write path, 1 = read path (check)
  rand bit [127:0] data;
  rand bit [127:0] key;
  rand bit [31:0]  lba;
  rand bit [15:0]  app_tag;
  rand bit [1:0]   pattern;          // 0 random, 1 all zeros, 2 all ones, 3 A5 pattern
  rand int         idle_cycles;
  rand bit         bad_guard16, bad_guard32, bad_reftag, bad_parity;   // error knobs (read path)

  bit [15:0] guard16;  bit [31:0] guard32;  bit [31:0] ref_tag;  bit [15:0] parity;   // PI sent with a read
  bit [127:0] cipher;                                                                    // observed by monitor
  bit g16_err, g32_err, ref_err, par_err;

  constraint c_mode    { mode dist {0 := 50, 1 := 50}; }                                   // 1
  constraint c_pattern { pattern dist {0 := 70, [1:3] :/ 30}; }                            // 2
  constraint c_err_mode{ (bad_guard16 || bad_guard32 || bad_reftag || bad_parity) -> mode == 1; }   // 3
  constraint c_lba     { lba dist {[0:1023] :/ 40, [32'h0000_0400:32'hFFFF_FBFF] :/ 30,
                                   [32'hFFFF_FC00:32'hFFFF_FFFF] :/ 30}; }                 // 4: edges of the ref tag
  constraint c_app     { app_tag dist {16'hFFFF := 10, [0:16'hFFFE] :/ 90}; }              // 5: escape value 10%
  constraint c_idle    { idle_cycles inside {[1:3]}; }                                     // 7
  constraint c_good    { bad_guard16 == 0; bad_guard32 == 0; bad_reftag == 0; bad_parity == 0; }   // 8
  constraint c_key     { key != 128'h0; }                                                  // 10

  function new ( string name = "nvme_rel_item");
   super.new(name);
 endfunction

  // fill the data pattern, then the PI that a read path would carry (correct), then the planted errors
  function void post_randomize();
    if (pattern == 1) data = '0;
    if (pattern == 2) data = '1;
    if (pattern == 3) data = {16{8'hA5}};
    if (mode == 1) begin
      guard16 = nvme_rel_model::crc16(data);
      guard32 = nvme_rel_model::crc32c(data);
      ref_tag = lba;
      parity  = nvme_rel_model::parity16(data);
      if (bad_guard16) guard16 ^= 16'h0001;
      if (bad_guard32) guard32 ^= 32'h0000_0001;
      if (bad_reftag)  ref_tag ^= 32'h0000_0001;
      if (bad_parity)  parity  ^= 16'h0001;
    end else begin
      guard16 = 0; guard32 = 0; ref_tag = 0; parity = 0;
    end
  endfunction

  function void do_copy (uvm_object rhs);
    nvme_rel_item r;
    if (!$cast(r, rhs)) `uvm_fatal ("Txn","Unable to cast ");
    super.do_copy(rhs);
    mode = r.mode; data = r.data; key = r.key; lba = r.lba; app_tag = r.app_tag;
    guard16 = r.guard16; guard32 = r.guard32; ref_tag = r.ref_tag; parity = r.parity; cipher = r.cipher;
  endfunction
 endclass
