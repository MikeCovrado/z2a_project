// SPDX-FileCopyrightText: 2020 Efabless Corporation
// SPDX-FileCopyrightText: 2021 Mike Thompson (Covrado)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0
//
///////////////////////////////////////////////////////////////////////////////
//
// Wrapper file for ZeroToAsic user project.  The Z2A user project is a multi-
// project wrapper for the Caravel user project.
//

`ifndef _WRAPPER_SERIAL_DIVIDER_
`define _WRAPPER_SERIAL_DIVIDER_

`default_nettype none

`ifndef MPRJ_IO_PADS
  `define MPRJ_IO_PADS 38
`endif

`include "mike_proj_rtl/proj_serial_divider.v"

module wrapper_serial_divider #(
    parameter WBW  = 32, // Wishbone bus width
              LAW  = 32, // Width of local instance of Logic Analyser
              XLEN = 32  // Data width of Dividend, Divisor, Quotient and Remainder
)(
`ifdef USE_POWER_PINS
    inout vdda1,    // User area 1 3.3V supply
    inout vdda2,    // User area 2 3.3V supply
    inout vssa1,    // User area 1 analog ground
    inout vssa2,    // User area 2 analog ground
    inout vccd1,    // User area 1 1.8V supply
    inout vccd2,    // User area 2 1.8v supply
    inout vssd1,    // User area 1 digital ground
    inout vssd2,    // User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input  wire             wb_clk_i,
    input  wire             wb_rst_i,
    input  wire             wbs_stb_i,
    input  wire             wbs_cyc_i,
    input  wire             wbs_we_i,
    input  wire [WBW/8-1:0] wbs_sel_i,
    input  wire [WBW-1  :0] wbs_dat_i,
    input  wire [WBW-1  :0] wbs_adr_i,
    output wire             wbs_ack_o,
    output wire [WBW-1  :0] wbs_dat_o,

    // Logic Analyzer Signals
    input  wire [LAW-1:0] la_data_in,
    output wire [LAW-1:0] la_data_out,
    input  wire [LAW-1:0] la_oen,

    // IOs
    input  wire [`MPRJ_IO_PADS-1:0] io_in,
    output wire [`MPRJ_IO_PADS-1:0] io_out,
    output wire [`MPRJ_IO_PADS-1:0] io_oeb,

    // active input, only connect tristated outputs if this is high
    input wire active
);

    // all outputs must be tristated before being passed onto the project
    wire                     buf_wbs_ack_o;
    wire [          WBW-1:0] buf_wbs_dat_o;
    wire [          LAW-1:0] buf_la_data_out;
    wire [`MPRJ_IO_PADS-1:0] buf_io_out;
    wire [`MPRJ_IO_PADS-1:0] buf_io_oeb;

    // Divider operation start/finish
    wire                     div_start;
    wire                     div_fini;

    // wires to connect LED control to IO_PADs
    wire                     hw_blinky;
    wire                     sw_blinky;

    // selector for la_out
    wire [              3:0] hw_sel;

`ifdef FORMAL
    // formal can't deal with z, so set all outputs to 0 if not active
    assign wbs_ack_o    = active ? buf_wbs_ack_o    : {              1'b0}};
    assign wbs_dat_o    = active ? buf_wbs_dat_o    : {          WBW{1'b0}};
    assign la_data_out  = active ? buf_la_data_out  : {          LAW{1'b0}};
    assign io_out       = active ? buf_io_out       : {`MPRJ_IO_PADS{1'b0}};
    assign io_oeb       = active ? buf_io_oeb       : {`MPRJ_IO_PADS{1'b0}};
    `include "properties.v"
`else
    // tristate buffers
    assign wbs_ack_o    = active ? buf_wbs_ack_o    :                1'bZ;
    assign wbs_dat_o    = active ? buf_wbs_dat_o    : {          WBW{1'bZ}};
    assign la_data_out  = active ? buf_la_data_out  : {          LAW{1'bZ}};
    assign io_out       = active ? buf_io_out       : {`MPRJ_IO_PADS{1'bZ}};
    assign io_oeb       = active ? buf_io_oeb       : {`MPRJ_IO_PADS{1'bZ}};
`endif

/*
    // permanently set oeb so that lower nibble of IO_PADs are inputs and all others are outputs
    // 0 is output, 1 is high-impedance
    assign buf_io_oeb = { {`MPRJ_IO_PADS-4{1'b0}}, 4'b1111 };

    // drive the blinky lights; tie-off unused outputs
    assign buf_io_out = { {`MPRJ_IO_PADS-6{1'b0}}, hw_blinky, sw_blinky, 4'b0000 };

    // Low order bits of can be used to select la_data_out
    assign hw_sel     = io_in[3:0];
*/
    // permanently set oeb so that outputs are always enabled: 0 is output, 1 is high-impedance
    assign buf_io_oeb = {`MPRJ_IO_PADS{1'b0}};

    // tie-off unused outputs
    assign buf_io_out = { {`MPRJ_IO_PADS-2{1'b0}}, hw_blinky, sw_blinky };
    assign hw_sel     = 4'h0;

    // The _actual_ project!
    proj_serial_divider #(
        .WBW  (WBW ), // Wishbone bus width
        .LAW  (LAW ), // Logical Analyzer bus width
        .XLEN (XLEN)  // Data width of Dividend, Divisor, Quotient and Remainder
    ) serial_divider (
        .clk_i       (wb_clk_i),
        .reset_i     (wb_rst_i),
        .wbs_stb_i   (wbs_stb_i),
        .wbs_cyc_i   (wbs_cyc_i),
        .wbs_we_i    (wbs_we_i),
        .wbs_sel_i   (wbs_sel_i),
        .wbs_adr_i   (wbs_adr_i),
        .wbs_dat_i   (wbs_dat_i),
        .wbs_ack_o   (wbs_ack_o),
        .wbs_dat_o   (wbs_dat_o),
        .la_data_o   (la_data_out),
        .hw_blinky_o (hw_blinky),
        .sw_blinky_o (sw_blinky),
        .start_o     (div_start),
        .fini_o      (div_fini),
        .hw_sel_i    (hw_sel)
    );

endmodule // wrapper_serial_divider

`default_nettype wire

`endif // _WRAPPER_SERIAL_DIVIDER_
