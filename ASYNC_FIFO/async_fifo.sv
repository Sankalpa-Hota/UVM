`timescale 1ns/1ps
module async_fifo #(parameter DATA_W = 8, parameter ADDR_W = 4) (
   input  logic              wclk,
   input  logic              wrst_n,
   input  logic              winc,
   input  logic [DATA_W-1:0] wdata,
   output logic              wfull,
   input  logic              rclk,
   input  logic              rrst_n,
   input  logic              rinc,
   output logic [DATA_W-1:0] rdata,
   output logic              rempty);

  localparam int DEPTH = 1 << ADDR_W;

  logic [DATA_W-1:0] mem [DEPTH];

  logic [ADDR_W:0] wbin, wgray, wbin_next, wgray_next;
  logic [ADDR_W:0] rbin, rgray, rbin_next, rgray_next;
  logic [ADDR_W:0] wq1_rgray, wq2_rgray;
  logic [ADDR_W:0] rq1_wgray, rq2_wgray;
  logic            wfull_next, rempty_next;

  always_comb begin
    wbin_next  = wbin + (winc & ~wfull);
    wgray_next = (wbin_next >> 1) ^ wbin_next;
    wfull_next = (wgray_next == {~wq2_rgray[ADDR_W:ADDR_W-1], wq2_rgray[ADDR_W-2:0]});
  end

  always_ff @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      wbin  <= '0;
      wgray <= '0;
      wfull <= 1'b0;
    end else begin
      wbin  <= wbin_next;
      wgray <= wgray_next;
      wfull <= wfull_next;
    end
  end

  always_ff @(posedge wclk) begin
    if (winc && !wfull)
      mem[wbin[ADDR_W-1:0]] <= wdata;
  end

  always_ff @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      wq1_rgray <= '0;
      wq2_rgray <= '0;
    end else begin
      wq1_rgray <= rgray;
      wq2_rgray <= wq1_rgray;
    end
  end

  always_comb begin
    rbin_next   = rbin + (rinc & ~rempty);
    rgray_next  = (rbin_next >> 1) ^ rbin_next;
    rempty_next = (rgray_next == rq2_wgray);
  end

  always_ff @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      rbin   <= '0;
      rgray  <= '0;
      rempty <= 1'b1;
    end else begin
      rbin   <= rbin_next;
      rgray  <= rgray_next;
      rempty <= rempty_next;
    end
  end

  always_ff @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      rq1_wgray <= '0;
      rq2_wgray <= '0;
    end else begin
      rq1_wgray <= wgray;
      rq2_wgray <= rq1_wgray;
    end
  end

  assign rdata = mem[rbin[ADDR_W-1:0]];

endmodule
