`uvm_analysis_imp_decl(_tlp)
`uvm_analysis_imp_decl(_nvme)

class pcie_nvme_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(pcie_nvme_scoreboard)

  uvm_analysis_imp_tlp  #(tlp_item, pcie_nvme_scoreboard) imp_tlp;    // TLPs seen on the PCIe side
  uvm_analysis_imp_nvme #(nvme_evt, pcie_nvme_scoreboard) imp_nvme;   // hand-offs seen on the NVMe side

  nvme_evt exp[$];
  int unsigned n_pass, n_fail, n_wr, n_db, n_err;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp_tlp  = new("imp_tlp",  this);
    imp_nvme = new("imp_nvme", this);
  endfunction

  // reference model: what the transaction layer + address decode must do with this TLP
  function void write_tlp(tlp_item t);
    nvme_evt e = nvme_evt::type_id::create("exp");
    int len = (t.length == 0) ? 1024 : t.length;
    if (!(t.fmt[1] && t.typ == 0)) begin e.kind = EVT_ERROR; e.err_code = 2; end              // not a Memory Write
    else if (t.payload.size() != len || t.payload.size() > 32) begin e.kind = EVT_ERROR; e.err_code = 1; end   // malformed
    else if (t.addr[11:0] + 4 * len > 4096) begin e.kind = EVT_ERROR; e.err_code = 1; end    // crosses 4 KB
    else if (t.addr >= WIN_BASE && t.addr < WIN_BASE + 4096) begin
      e.kind = EVT_WRITE;  e.addr = t.addr[11:0];  e.first_be = t.first_be;  e.last_be = t.last_be;
      foreach (t.payload[k]) e.data.push_back(t.payload[k]);
    end
    else if (t.addr >= DB_BASE && t.addr < DB_BASE + 32 && len == 1) begin
      e.kind = EVT_DOORBELL;  e.db_cq = t.addr[2];  e.db_qid = t.addr[4:3];  e.db_value = t.payload[0][15:0];
    end
    else begin e.kind = EVT_ERROR; e.err_code = 3; end                                        // unmapped
    exp.push_back(e);
  endfunction

  function void write_nvme(nvme_evt got);
    nvme_evt e;
    if (exp.size() == 0) begin n_fail++; `uvm_error("SB", {"unexpected ", got.convert2string()}) return; end
    e = exp.pop_front();                                      // the DUT handles TLPs strictly in order
    if (!got.same(e)) begin
      n_fail++;
      `uvm_error("SB", {"expected ", e.convert2string(), " got ", got.convert2string()})
    end else begin
      n_pass++;
      case (got.kind) EVT_WRITE: n_wr++; EVT_DOORBELL: n_db++; default: n_err++; endcase
    end
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (exp.size() != 0) `uvm_error("SB", $sformatf("%0d TLP(s) never handed off", exp.size()))
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SB", $sformatf("pass=%0d fail=%0d  (writes=%0d doorbells=%0d errors reported=%0d)",
                              n_pass, n_fail, n_wr, n_db, n_err), UVM_LOW)
    if (n_pass > 0 && n_fail == 0 && exp.size() == 0) `uvm_info("SB", "Test PASS", UVM_LOW)
    else `uvm_error("SB", "Test FAIL")
  endfunction
endclass
