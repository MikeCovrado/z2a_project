// Copyright 2021 Mike Thompson (Covrado)
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://solderpad.org/licenses/
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * top_mike_proj
 *     $ iverilog -D MPRJ_IO_PADS=128 -g2012 top_mike_proj.v serial_divider.v
 *
 *-------------------------------------------------------------
 */

module top_mike_proj #(
    parameter BITS = 32,   // TODO: find out what this is really for...
              WBW  = 32
)(
`ifdef USE_POWER_PINS
    inout vdda1,   // User area 1 3.3V supply
    inout vdda2,   // User area 2 3.3V supply
    inout vssa1,   // User area 1 analog ground
    inout vssa2,   // User area 2 analog ground
    inout vccd1,   // User area 1 1.8V supply
    inout vccd2,   // User area 2 1.8v supply
    inout vssd1,   // User area 1 digital ground
    inout vssd2,   // User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input              wb_clk_i,
    input              wb_rst_i,
    input              wbs_stb_i,
    input              wbs_cyc_i,
    input              wbs_we_i,
    input  [WBW/8-1:0] wbs_sel_i,
    input  [WBW-1  :0] wbs_dat_i,
    input  [WBW-1  :0] wbs_adr_i,
    output             wbs_ack_o,
    output [WBW-1  :0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oen,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    wire [WBW-1:0] dividend;
    wire [WBW-1:0] divisor;
    wire [WBW-1:0] quotient;
    wire [WBW-1:0] remainder;

    wire        valid;
    wire [31:0] la_write;

    // WB MI A
    assign valid     = wbs_cyc_i && wbs_stb_i;

    // IO
    assign io_out = dividend;
    assign io_oeb = {(`MPRJ_IO_PADS-1){rst}};

    // LA
    assign la_data_out = {dividend, divisor, quotient, remainder};
    // FIXME: what are LA probes [63:32] for????
    assign la_write = ~la_oen[63:32] & ~{BITS{valid}};
    // Assuming LA probes [65:64] are for controlling the serial_divider clk & reset
    assign clk = (~la_oen[64]) ? la_data_in[64]: wb_clk_i;
    assign rst = (~la_oen[65]) ? la_data_in[65]: wb_rst_i;

    serial_divider #(
        .WBW  (32), // Wishbone bus width
        .XLEN (32)  // Data width of Dividend, Divisor, Quotient and Remainder
    ) serial_divider_u0 (
        .clk_i      (clk),
        .reset_i    (rst),
        .wbs_stb_i  (wbs_stb_i),
        .wbs_cyc_i  (wbs_cyc_i),
        .wbs_we_i   (wbs_we_i),
        .wbs_sel_i  (wbs_sel_i),
        .wbs_adr_i  (wbs_adr_i),
        .wbs_dat_i  (wbs_dat_i),
        .wbs_ack_o  (wbs_ack_o),
        .wbs_dat_o  (wbs_dat_o),
        .la_data_o  (la_data_out)
    );

endmodule: top_mike_proj

`default_nettype wire
