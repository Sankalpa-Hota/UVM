`timescale 1ns/1ps
interface nvme_if ( input logic clk , rst_n);
  logic        nvme_valid, nvme_ready, nvme_last;
  logic [11:0] nvme_addr;
  logic [31:0] nvme_data;
  logic [3:0]  nvme_be;
  logic        db_valid, db_cq;
  logic [1:0]  db_qid;
  logic [15:0] db_value;
  logic        err_valid;
  logic [1:0]  err_code;

  clocking driver_cb @(posedge clk);                   // the NVMe side only drives ready (back-pressure)
    default input #1step output #1;
    output nvme_ready;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input nvme_valid, nvme_ready, nvme_last, nvme_addr, nvme_data, nvme_be;
    input db_valid, db_cq, db_qid, db_value, err_valid, err_code;
  endclocking

  modport DRIVER (clocking driver_cb, input clk, input rst_n);
  modport MONITOR (clocking mon_cb, input clk, input rst_n);

  // 5. a write waiting for nvme_ready must not change
  a_hold   : assert property (@(posedge clk) disable iff (!rst_n) nvme_valid && !nvme_ready |=> nvme_valid && $stable({nvme_addr, nvme_data, nvme_be, nvme_last}))
               else $error("NVMe write changed while waiting for ready");
  // 6. every write is DWORD aligned
  a_align  : assert property (@(posedge clk) disable iff (!rst_n) nvme_valid |-> nvme_addr[1:0] == 2'b00)
               else $error("unaligned NVMe write");
  // 7. at least one byte enabled on every write
  a_be     : assert property (@(posedge clk) disable iff (!rst_n) nvme_valid |-> nvme_be != 4'b0000)
               else $error("write with no byte enabled");
  // 8. doorbell is a one-cycle pulse
  a_db     : assert property (@(posedge clk) disable iff (!rst_n) db_valid |=> !db_valid)
               else $error("doorbell longer than 1 cycle");
  // 9. error report is a one-cycle pulse with a real code
  a_err    : assert property (@(posedge clk) disable iff (!rst_n) err_valid |-> err_code != 0 ##1 !err_valid)
               else $error("bad error report");
  // 10. reset values
  a_reset  : assert property (@(posedge clk) $rose(rst_n) |-> !nvme_valid && !db_valid && !err_valid)
               else $error("outputs active after reset");
endinterface
