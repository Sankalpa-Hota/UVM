`timescale 1ns/1ps
interface nvme_rel_if ( input logic clk , rst_n);
  logic         in_valid, in_ready, in_mode;
  logic [127:0] in_data, in_key;
  logic [31:0]  in_lba, in_ref_tag, in_guard32;
  logic [15:0]  in_app_tag, in_guard16, in_parity;
  logic         out_valid, out_mode;
  logic [127:0] out_cipher;
  logic [15:0]  out_guard16, out_app_tag, out_parity;
  logic [31:0]  out_ref_tag, out_guard32;
  logic         out_guard16_err, out_guard32_err, out_reftag_err, out_parity_err;

  clocking driver_cb @(posedge clk);
    default input #1step output #1;
    output in_valid, in_mode, in_data, in_key, in_lba, in_app_tag, in_guard16, in_guard32, in_ref_tag, in_parity;
    input  in_ready;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input in_valid, in_ready, in_mode, in_data, in_key, in_lba, in_app_tag, in_guard16, in_guard32, in_ref_tag, in_parity;
    input out_valid, out_mode, out_cipher, out_guard16, out_app_tag, out_ref_tag, out_guard32, out_parity;
    input out_guard16_err, out_guard32_err, out_reftag_err, out_parity_err;
  endclocking

  modport DRIVER (clocking driver_cb, input clk, input rst_n);
  modport MONITOR (clocking mon_cb, input clk, input rst_n);

  // 1. handshake: a block waiting for in_ready must not change
  a_hold     : assert property (@(posedge clk) disable iff (!rst_n) in_valid && !in_ready |=> in_valid && $stable(in_data) && $stable(in_key) && $stable(in_mode))
                 else $error("input changed while waiting for in_ready");
  // 2. latency: an accepted block comes out exactly 11 cycles later (1 + 10 AES rounds)
  a_latency  : assert property (@(posedge clk) disable iff (!rst_n) in_valid && in_ready |-> ##11 out_valid)
                 else $error("out_valid not 11 cycles after accept");
  // 3. out_valid is a one-cycle pulse
  a_pulse    : assert property (@(posedge clk) disable iff (!rst_n) out_valid |=> !out_valid)
                 else $error("out_valid longer than 1 cycle");
  // 4. busy after accept: in_ready drops on the next cycle
  a_busy     : assert property (@(posedge clk) disable iff (!rst_n) in_valid && in_ready |=> !in_ready)
                 else $error("in_ready still high after accept");
  // 5. ready again when the result comes out
  a_ready    : assert property (@(posedge clk) disable iff (!rst_n) out_valid |-> in_ready)
                 else $error("in_ready low with out_valid");
  // 6. no output without an accepted block 11 cycles earlier
  a_cause    : assert property (@(posedge clk) disable iff (!rst_n) out_valid |-> $past(in_valid && in_ready, 11))
                 else $error("out_valid without an input");
  // 7. no X/Z on the result
  a_no_x     : assert property (@(posedge clk) disable iff (!rst_n) out_valid |-> !$isunknown({out_cipher, out_guard16, out_guard32, out_parity}))
                 else $error("X on outputs");
  // 8. write path never reports a check error
  a_wr_clean : assert property (@(posedge clk) disable iff (!rst_n) out_valid && !out_mode |-> !(out_guard16_err || out_guard32_err || out_reftag_err || out_parity_err))
                 else $error("error flag on the write path");
  // 9. NVMe PI escape: App Tag FFFFh disables the Guard and Ref Tag checks
  a_escape   : assert property (@(posedge clk) disable iff (!rst_n) out_valid && out_app_tag == 16'hFFFF |-> !(out_guard16_err || out_guard32_err || out_reftag_err))
                 else $error("PI check not disabled by App Tag FFFFh");
  // 10. reset values
  a_reset    : assert property (@(posedge clk) $rose(rst_n) |-> !out_valid && in_ready)
                 else $error("bad state after reset");
endinterface
