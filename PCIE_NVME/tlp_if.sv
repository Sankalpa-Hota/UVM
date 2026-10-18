`timescale 1ns/1ps
interface tlp_if ( input logic clk , rst_n);
  logic        tlp_valid, tlp_ready, tlp_sop, tlp_eop;
  logic [31:0] tlp_data;
  logic        in_pkt;                                   // helper: between sop and eop

  clocking driver_cb @(posedge clk);
    default input #1step output #1;
    output tlp_valid, tlp_sop, tlp_eop, tlp_data;
    input  tlp_ready;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input tlp_valid, tlp_ready, tlp_sop, tlp_eop, tlp_data;
  endclocking

  modport DRIVER (clocking driver_cb, input clk, input rst_n);
  modport MONITOR (clocking mon_cb, input clk, input rst_n);

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) in_pkt <= 0;
    else if (tlp_valid && tlp_ready) in_pkt <= tlp_eop ? 1'b0 : 1'b1;

  // 1. a beat waiting for tlp_ready must not change
  a_hold   : assert property (@(posedge clk) disable iff (!rst_n) tlp_valid && !tlp_ready |=> tlp_valid && $stable({tlp_sop, tlp_eop, tlp_data}))
               else $error("TLP beat changed while waiting for ready");
  // 2. sop/eop only mean something on a valid beat
  a_sop_v  : assert property (@(posedge clk) disable iff (!rst_n) (tlp_sop || tlp_eop) |-> tlp_valid)
               else $error("sop/eop without valid");
  // 3. framing: a new TLP never starts in the middle of another one
  a_frame  : assert property (@(posedge clk) disable iff (!rst_n) tlp_valid && tlp_ready && in_pkt |-> !tlp_sop)
               else $error("sop inside a TLP");
  // 4. no X on a valid beat
  a_no_x   : assert property (@(posedge clk) disable iff (!rst_n) tlp_valid |-> !$isunknown(tlp_data))
               else $error("X on tlp_data");
endinterface
