`timescale 1ns/1ps
// [REG] new interface: the register bus
interface reg_if ( input logic clk , rst_n);
  logic        reg_valid, reg_wr, reg_ready;
  logic [3:0]  reg_addr;
  logic [31:0] reg_wdata, reg_rdata;

  clocking driver_cb @(posedge clk);
    default input #1step output #1;
    output reg_valid, reg_wr, reg_addr, reg_wdata;
    input  reg_ready, reg_rdata;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input reg_valid, reg_wr, reg_addr, reg_wdata, reg_ready, reg_rdata;
  endclocking

  modport DRIVER (clocking driver_cb, input clk, input rst_n);
  modport MONITOR (clocking mon_cb, input clk, input rst_n);

  a_hold  : assert property (@(posedge clk) disable iff (!rst_n) reg_valid && !reg_ready |=> reg_valid && $stable({reg_wr, reg_addr, reg_wdata}))
              else $error("register request changed before reg_ready");
  a_ready : assert property (@(posedge clk) disable iff (!rst_n) reg_ready |=> !reg_ready)
              else $error("reg_ready longer than 1 cycle");
endinterface
