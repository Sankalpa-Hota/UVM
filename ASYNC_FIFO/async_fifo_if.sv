`timescale 1ns/1ps
interface async_fifo_if #(parameter DATA_W = 8) ( input logic wclk , wrst_n , rclk , rrst_n);
  logic winc;
  logic [DATA_W-1:0] wdata;
  logic wfull;
  logic rinc;
  logic [DATA_W-1:0] rdata;
  logic rempty;

  clocking wdrv_cb @(posedge wclk);
    default input #1step output #1;
    output winc, wdata;
    input wfull;
  endclocking

  clocking rdrv_cb @(posedge rclk);
    default input #1step output #1;
    output rinc;
    input rempty, rdata;
  endclocking

  clocking wmon_cb @(posedge wclk);
    default input #1step;
    input winc, wdata, wfull;
  endclocking

  clocking rmon_cb @(posedge rclk);
    default input #1step;
    input rinc, rdata, rempty;
  endclocking

  modport DRIVER (clocking wdrv_cb, clocking rdrv_cb, input wclk, wrst_n, rclk, rrst_n);
  modport MONITOR (clocking wmon_cb, clocking rmon_cb, input wclk, wrst_n, rclk, rrst_n);

endinterface
