`timescale 1ns/1ps
// checker module: only inputs, no logic of its own; bind puts it inside the DUT so it can see internal pointers
module async_fifo_sva #(parameter DATA_W = 8, parameter ADDR_W = 4) (
  input logic              wclk, wrst_n, winc, wfull,
  input logic              rclk, rrst_n, rinc, rempty,
  input logic [ADDR_W:0]   wbin, wgray, wq2_rgray,
  input logic [ADDR_W:0]   rbin, rgray, rq2_wgray);

  localparam int DEPTH = 1 << ADDR_W;

  function automatic logic [ADDR_W:0] gray2bin(logic [ADDR_W:0] g);
    for (int i = ADDR_W; i >= 0; i--)
      gray2bin[i] = (i == ADDR_W) ? g[i] : gray2bin[i+1] ^ g[i];
  endfunction

  logic [ADDR_W:0] wcount;
  assign wcount = wbin - gray2bin(wq2_rgray);   // entries as seen from the write side

  // ---------------- write domain (all sampled on wclk) ----------------
  // accepted write: binary write pointer must move by exactly 1 on the next wclk
  a_wptr_inc   : assert property (@(posedge wclk) disable iff (!wrst_n) (winc && !wfull) |=> wbin == $past(wbin) + 1'b1)
                   else $error("wptr did not increment on accepted write");
  // no write request: pointer must not move
  a_wptr_hold  : assert property (@(posedge wclk) disable iff (!wrst_n) !winc |=> $stable(wbin))
                   else $error("wptr moved without winc");
  // write while full must be dropped (no overflow)
  a_no_overflow: assert property (@(posedge wclk) disable iff (!wrst_n) (winc && wfull) |=> $stable(wbin))
                   else $error("write accepted while full");
  // gray pointer crosses clock domains, so only 0 or 1 bit may change per clock
  a_wgray_1bit : assert property (@(posedge wclk) disable iff (!wrst_n) $onehot0(wgray ^ $past(wgray)))
                   else $error("wgray changed more than 1 bit");
  // never more than DEPTH entries in the FIFO
  a_wcount_max : assert property (@(posedge wclk) disable iff (!wrst_n) wcount <= DEPTH)
                   else $error("fifo holds more than DEPTH entries");
  // full may lag (stay high a cycle late) but must never be low when the FIFO is really full
  a_full_safe  : assert property (@(posedge wclk) disable iff (!wrst_n) !wfull |-> wcount < DEPTH)
                   else $error("full low while fifo is full");
  // first wclk out of reset: not full
  a_full_rst   : assert property (@(posedge wclk) $rose(wrst_n) |-> !wfull)
                   else $error("full high after reset");

  // ---------------- read domain (all sampled on rclk) ----------------
  a_rptr_inc    : assert property (@(posedge rclk) disable iff (!rrst_n) (rinc && !rempty) |=> rbin == $past(rbin) + 1'b1)
                    else $error("rptr did not increment on accepted read");
  a_rptr_hold   : assert property (@(posedge rclk) disable iff (!rrst_n) !rinc |=> $stable(rbin))
                    else $error("rptr moved without rinc");
  // read while empty must be dropped (no underflow)
  a_no_underflow: assert property (@(posedge rclk) disable iff (!rrst_n) (rinc && rempty) |=> $stable(rbin))
                    else $error("read accepted while empty");
  a_rgray_1bit  : assert property (@(posedge rclk) disable iff (!rrst_n) $onehot0(rgray ^ $past(rgray)))
                    else $error("rgray changed more than 1 bit");
  // empty may lag, but must never be low when read ptr == synced write ptr (nothing to read)
  a_empty_safe  : assert property (@(posedge rclk) disable iff (!rrst_n) !rempty |-> rgray != rq2_wgray)
                    else $error("empty low while fifo is empty");
  a_empty_rst   : assert property (@(posedge rclk) $rose(rrst_n) |-> rempty)
                    else $error("empty low after reset");

  // cover = "did this ever happen"; proves the test really reached full and empty
  c_full      : cover property (@(posedge wclk) disable iff (!wrst_n) $rose(wfull));
  c_empty     : cover property (@(posedge rclk) disable iff (!rrst_n) $rose(rempty));
  c_overflow  : cover property (@(posedge wclk) disable iff (!wrst_n) winc && wfull);
  c_underflow : cover property (@(posedge rclk) disable iff (!rrst_n) rinc && rempty);

endmodule

// bind <design module> <checker module> <instance name> (connections)
// inserts u_sva inside every async_fifo instance without editing the DUT; names on the right are DUT signals (incl. internal)
bind async_fifo async_fifo_sva #(.DATA_W(DATA_W), .ADDR_W(ADDR_W)) u_sva (
  .wclk(wclk), .wrst_n(wrst_n), .winc(winc), .wfull(wfull),
  .rclk(rclk), .rrst_n(rrst_n), .rinc(rinc), .rempty(rempty),
  .wbin(wbin), .wgray(wgray), .wq2_rgray(wq2_rgray),
  .rbin(rbin), .rgray(rgray), .rq2_wgray(rq2_wgray));
