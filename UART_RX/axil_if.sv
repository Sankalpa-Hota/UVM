`timescale 1ns/1ps
interface axil_if ( input logic clk , rst_n);
  logic [7:0]  awaddr;
  logic        awvalid;
  logic        awready;
  logic [31:0] wdata;
  logic        wvalid;
  logic        wready;
  logic [1:0]  bresp;
  logic        bvalid;
  logic        bready;
  logic [7:0]  araddr;
  logic        arvalid;
  logic        arready;
  logic [31:0] rdata;
  logic [1:0]  rresp;
  logic        rvalid;
  logic        rready;

  clocking driver_cb @(posedge clk);
    default input #1step output #1;
    output awaddr, awvalid, wdata, wvalid, bready, araddr, arvalid, rready;
    input  awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input awaddr, awvalid, awready, wdata, wvalid, wready, bresp, bvalid, bready;
    input araddr, arvalid, arready, rdata, rresp, rvalid, rready;
  endclocking

  modport DRIVER (clocking driver_cb,input clk , input rst_n);
  modport MONITOR (clocking mon_cb,input clk , input rst_n);

  a_aw_stable : assert property (@(posedge clk) disable iff (!rst_n) awvalid && !awready |=> awvalid && $stable(awaddr))
                  else $error("awvalid/awaddr changed before awready");
  a_w_stable  : assert property (@(posedge clk) disable iff (!rst_n) wvalid && !wready |=> wvalid && $stable(wdata))
                  else $error("wvalid/wdata changed before wready");
  a_b_stable  : assert property (@(posedge clk) disable iff (!rst_n) bvalid && !bready |=> bvalid && $stable(bresp))
                  else $error("bvalid/bresp changed before bready");
  a_ar_stable : assert property (@(posedge clk) disable iff (!rst_n) arvalid && !arready |=> arvalid && $stable(araddr))
                  else $error("arvalid/araddr changed before arready");
  a_r_stable  : assert property (@(posedge clk) disable iff (!rst_n) rvalid && !rready |=> rvalid && $stable(rdata))
                  else $error("rvalid/rdata changed before rready");

endinterface
