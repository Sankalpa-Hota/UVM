// what the NVMe side RECEIVED from the DUT (built by the NVMe monitor, compared by the scoreboard)
typedef enum {EVT_WRITE, EVT_DOORBELL, EVT_ERROR} evt_e;
class nvme_evt extends uvm_object;
  `uvm_object_utils(nvme_evt)
  evt_e      kind;
  bit [11:0] addr;          // write: start offset in the window
  bit [31:0] data[$];       // write: the DWs
  bit [3:0]  first_be, last_be;
  bit        db_cq;  bit [1:0] db_qid;  bit [15:0] db_value;
  bit [1:0]  err_code;

  function new(string name = "nvme_evt"); super.new(name); endfunction

  function string convert2string();
    case (kind)
      EVT_WRITE:    return $sformatf("WRITE @%03h %0d DW be %h/%h", addr, data.size(), first_be, last_be);
      EVT_DOORBELL: return $sformatf("DOORBELL %s%0d = %0d", db_cq ? "CQ" : "SQ", db_qid, db_value);
      default:      return $sformatf("ERROR code %0d", err_code);
    endcase
  endfunction

  function bit same(nvme_evt o);
    if (kind != o.kind) return 0;
    case (kind)
      EVT_WRITE:    return addr == o.addr && data == o.data && first_be == o.first_be && last_be == o.last_be;
      EVT_DOORBELL: return db_cq == o.db_cq && db_qid == o.db_qid && db_value == o.db_value;
      default:      return err_code == o.err_code;
    endcase
  endfunction
endclass
