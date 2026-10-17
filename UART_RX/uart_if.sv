`timescale 1ns/1ps
interface uart_if ( input logic clk , rst_n);
  logic       rx;
  logic       rx_valid;
  logic [7:0] rx_byte;

  clocking driver_cb @(posedge clk);
    default input #1step output #1;
    output rx;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input rx, rx_valid, rx_byte;
  endclocking

  modport DRIVER (clocking driver_cb,input clk , input rst_n);
  modport MONITOR (clocking mon_cb,input clk , input rst_n);

  a_valid_pulse : assert property (@(posedge clk) disable iff (!rst_n) rx_valid |=> !rx_valid)
                    else $error("rx_valid high for more than 1 cycle");

endinterface
