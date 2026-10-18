`uvm_analysis_imp_decl(_in)
`uvm_analysis_imp_decl(_out)

class nvme_rel_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(nvme_rel_scoreboard)

  uvm_analysis_imp_in  #(nvme_rel_item, nvme_rel_scoreboard) imp_in;
  uvm_analysis_imp_out #(nvme_rel_item, nvme_rel_scoreboard) imp_out;

  nvme_rel_item exp[$];
  int unsigned n_pass, n_fail, n_kat, n_err_flagged;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp_in  = new("imp_in",  this);
    imp_out = new("imp_out", this);
  endfunction

  // reference: what the block must produce for this input (and which checks must fail)
  function void write_in(nvme_rel_item t);
    nvme_rel_item e = nvme_rel_item::type_id::create("exp");
    bit escape = (t.app_tag == 16'hFFFF);
    e.mode    = t.mode;
    e.cipher  = nvme_rel_model::aes128(t.data, t.key);
    e.guard16 = nvme_rel_model::crc16(t.data);
    e.guard32 = nvme_rel_model::crc32c(t.data);
    e.parity  = nvme_rel_model::parity16(t.data);
    e.app_tag = t.app_tag;
    e.ref_tag = t.lba;
    e.g16_err = t.mode && !escape && (e.guard16 != t.guard16);
    e.g32_err = t.mode && !escape && (e.guard32 != t.guard32);
    e.ref_err = t.mode && !escape && (t.ref_tag != t.lba);
    e.par_err = t.mode && (e.parity != t.parity);
    if (t.data == FIPS_PT && t.key == FIPS_KEY) begin     // the model itself against published answers
      n_kat++;
      if (e.cipher != FIPS_CT || e.guard16 != FIPS_CRC16 || e.guard32 != FIPS_CRC32)
        `uvm_error("SB_KAT", "reference model disagrees with the known answer")
    end
    exp.push_back(e);
  endfunction

  function void write_out(nvme_rel_item t);
    nvme_rel_item e;
    if (exp.size() == 0) begin n_fail++; `uvm_error("SB", "result with no input") return; end
    e = exp.pop_front();
    if (t.cipher != e.cipher || t.guard16 != e.guard16 || t.guard32 != e.guard32 || t.parity != e.parity ||
        t.app_tag != e.app_tag || t.ref_tag != e.ref_tag ||
        {t.g16_err, t.g32_err, t.ref_err, t.par_err} != {e.g16_err, e.g32_err, e.ref_err, e.par_err}) begin
      n_fail++;
      `uvm_error("SB", $sformatf("mismatch: cipher %h/%h g16 %h/%h g32 %h/%h flags %b/%b", t.cipher, e.cipher,
                 t.guard16, e.guard16, t.guard32, e.guard32,
                 {t.g16_err, t.g32_err, t.ref_err, t.par_err}, {e.g16_err, e.g32_err, e.ref_err, e.par_err}))
    end else begin
      n_pass++;
      if (t.g16_err || t.g32_err || t.ref_err || t.par_err) n_err_flagged++;
    end
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (exp.size() != 0) `uvm_error("SB", $sformatf("%0d block(s) never produced a result", exp.size()))
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SB", $sformatf("blocks pass=%0d fail=%0d  known-answer checks=%0d  error flags raised (expected)=%0d",
                              n_pass, n_fail, n_kat, n_err_flagged), UVM_LOW)
    if (n_pass > 0 && n_fail == 0 && exp.size() == 0) `uvm_info("SB", "Test PASS", UVM_LOW)
    else `uvm_error("SB", "Test FAIL")
  endfunction
endclass
