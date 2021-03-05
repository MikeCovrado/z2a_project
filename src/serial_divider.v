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

module serial_divider #(
    parameter WBW  =  32, // Wishbone bus width
              LAW  = 128, // Logic Analyzer width
              XLEN =  32, // Data width of Dividend, Divisor and Quotient
//              BLINK_CYCLES = 40_000_000  // period in clk cycles of hw blink
              BLINK_CYCLES = 32_000  // period in clk cycles of hw blink
)(
    input              clk_i,
    input              reset_i,
    // Hacking...
    output             start_o,
    output             fini_o,
    // Wishbone
    input              wbs_stb_i,
    input              wbs_cyc_i,
    input              wbs_we_i,
    input  [WBW/8-1:0] wbs_sel_i,
    input  [  WBW-1:0] wbs_adr_i,
    input  [  WBW-1:0] wbs_dat_i,
    output             wbs_ack_o,
    output [  WBW-1:0] wbs_dat_o,
    // Logic Analyser
    output [  LAW-1:0] la_data_o,
    // No project is truly complete without blinking LEDs
    output             hw_blinky_o,  // hardware control
    output             sw_blinky_o   // software control
);

    localparam HWBCW = $clog2(BLINK_CYCLES/2); // hardware blink counter width

    // Module outputs
    wire            start_o;
    wire            fini_o;
    wire            wbs_ack_o;
    wire [ WBW-1:0] wbs_dat_o;
    wire [ LAW-1:0] la_data_o;
    reg             hw_blinky_o;
    reg             sw_blinky_o;

    reg             ack;
    reg  [ WBW-1:0] rdata;

    // Debug outputs
    assign start_o   = start;
    assign fini_o    = fini;

    assign wbs_ack_o = ack;
    assign wbs_dat_o = rdata;
`ifdef FORMAL
    assign la_data_o = quotient;
`else
    assign la_data_o = dividend;
`endif //FORMAL

    // Control Regs
    reg start;
    reg debug;
    reg running;
    reg fini;

    // Function arguments and results
    reg  [ XLEN-1:0] dividend;
    reg  [ XLEN-1:0] divisor;
    reg  [ XLEN-1:0] quotient;
    reg  [ XLEN-1:0] remainder;
    reg  [ XLEN-1:0] dbg_quotient;
    reg  [ XLEN-1:0] dbg_remainder;

    // Local variables
    reg  [HWBCW-1:0] hw_blink_cntr;
    reg  [     31:0] tmp_divisor;

    ///////////////////////////////////////////////////////////////////////////
    // Wishbone control logic
    //    +--CSR----+---Address---+------Access Mode-------------------
    //     DIVIDEND  32'h3000_0000  write/read
    //     DIVISOR   32'h3000_0004  write/read
    //     QUOTIENT  32'h3000_0008  read-only
    //     REMAINDER 32'h3000_000C  read-only
    //     DEBUG     32'h3000_0010  set-on-write, clear-on-read
    //     FINI      32'h3000_0014  read-only
    //     START     32'h3000_0018  set-on-write-or-read (cannot be read)
    //     SW_BLINKY 32'h3000_001C  set-on-write, clear-on-read

    always @(posedge clk_i) begin
      if (reset_i) begin
        dividend      <= {XLEN{1'b0}};
        divisor       <= {XLEN{1'b0}};
        dbg_quotient  <= {XLEN{1'b0}};
        dbg_remainder <= {XLEN{1'b0}};
        rdata         <= { WBW{1'b0}};
        ack           <= 1'b0;
        start         <= 1'b0;
        debug         <= 1'b0;
        sw_blinky_o   <= 1'b1;
      end
      else begin
        // Single-cycle WB write/reads
        // TODO: support b2b cycles
        // (although it doesn't seem like Caravel can drive those at this time)
        ack   <= 1'b0;
        start <= 1'b0;
        if (wbs_stb_i && wbs_cyc_i && !ack) begin
          ack <= 1'b1;
          // Top nibble addresses args/results
          if (wbs_adr_i[WBW-1:WBW-4] == 4'h3) begin
            case (wbs_adr_i[4:0]) // TODO: could (should?) make this [4:2]
              // DIVIDEND at 32'h3000_0000 is write/read
              5'b0_0000: begin
                if (wbs_we_i) begin
                  if (wbs_sel_i[0]) dividend[ 7: 0] <= wbs_dat_i[ 7: 0];
                  if (wbs_sel_i[1]) dividend[15: 8] <= wbs_dat_i[15: 8];
                  if (wbs_sel_i[2]) dividend[23:16] <= wbs_dat_i[23:16];
                  if (wbs_sel_i[3]) dividend[31:24] <= wbs_dat_i[31:24];
                end
                else begin
                  if (wbs_sel_i[3]) rdata[31:24] <= dividend[31:24];
                  if (wbs_sel_i[2]) rdata[23:16] <= dividend[23:16];
                  if (wbs_sel_i[1]) rdata[15: 8] <= dividend[15: 8];
                  if (wbs_sel_i[0]) rdata[ 7: 0] <= dividend[ 7: 0];
                end
              end
              // DIVISOR at 32'h3000_0004 is write/read
              5'b0_0100: begin
                if (wbs_we_i) begin
                  divisor <= wbs_dat_i;
                end
                else begin
                  rdata <= divisor;
                end
              end
              // QUOTIENT at 32'h3000_0008 is read-only unless debug
              5'b0_1000: begin
                if (wbs_we_i && debug) begin
                end
                else begin
                  rdata <= quotient;
                end
              end
              // REMAINDER at 32'h3000_000C is read-only unless debug
              5'b0_1100: begin
                if (wbs_we_i && debug) begin
                  dbg_remainder <= wbs_dat_i;
                end
                else begin
                  rdata <= remainder;
                end
              end
              // DEBUG at 32'h3000_0010 is set-on-write, clear-on-read
              5'b1_0000: begin
                if (wbs_we_i) begin
                  debug <= 1'b1;
                end
                else begin
                  debug <= 1'b0;
                  rdata <= 32'h0000_0000;
                end
              end
              // FINI at 32'h3000_0014 is read-only (cannot be written)
              5'b1_0100: begin
                if (wbs_we_i) begin
                  rdata <= rdata;
                end
                else begin
                  rdata <= { {31{1'b0}}, fini };
                end
              end
              // START at 32'h3000_0018 is set-on-write-or-read (cannot be read)
              5'b1_1000: begin
                start <= 1'b1;
                rdata <= 32'h0000_0000;
              end
              // SW_BLINKY at 32'h3000_001C is set-on-write, clear-on-read
              5'b1_1100: begin
                if (wbs_we_i) begin
                  sw_blinky_o <= 1'b1;
                end
                else begin
                  sw_blinky_o <= 1'b0;
                  rdata <= 32'h0000_0000;
                end
              end
              // Accesses to all other addresses return error code (even on writes)
              default: begin
                rdata <= 32'h0bad_0bad;  // TODO: set an error?
              end
            endcase // (wbs_adr_i[7:4])
          end // if (wbs_adr_i[WBW-1:WBW-4] == 4'h3)
        end //if (wbs_stb_i && !ack)
      end // if (reset_i)
    end // always @(posedge clk_i)

    ///////////////////////////////////////////////////////////////////////////
    // Divide by even number.
    // Assumes that "start" is a single cycle pulse.
    always @(posedge clk_i) begin
      if (reset_i) begin
        tmp_divisor <= 32'h0000_0000;
        quotient    <= 32'h0000_0000;
        remainder   <= 32'h0000_0000;
        running     <= 1'b0;
        fini        <= 1'b0;
      end
      else begin
        if (debug) begin
          quotient    <= dbg_quotient;
          remainder   <= dbg_remainder;
        end
        else begin
          // Start calculation if:
          //  - not in debug mode
          //  - not already calcuating. (subsequent starts lost without error)
          if (start && !running) begin
            tmp_divisor <= {divisor[31:1], 1'b0};
            quotient    <= dividend;
            running     <= 1'b1;
            fini        <= 1'b0;
          end
          if (tmp_divisor > 32'h0000_0001) begin
            tmp_divisor <= tmp_divisor >> 1;
            quotient    <= quotient >> 1;
          end
          if (tmp_divisor == 32'h0000_0001) begin
            tmp_divisor <= 32'h0000_0000;
            running     <= 1'b0;
            fini        <= 1'b1;
          end
        end
      end
    end

    ///////////////////////////////////////////////////////////////////////////
    // blink LED for sign-of-live (no software control)
    // HWBCW ==  7 ==> 128 clk cycles ==> 3200ns (assume 25ns clk)
    // HWBCW == 15 ==> 32K clk cycles ==> 819,200ns
    // HWBCW == 24 ==> 20M clk cycles ==> ~0.5s
    always @(posedge clk_i) begin
      if (reset_i) begin
        hw_blink_cntr <= 32'h0000_0000;
        hw_blinky_o   <= 1'b1;
      end
      else begin
        hw_blink_cntr <= hw_blink_cntr + 32'h0000_0001;
        if (hw_blink_cntr[HWBCW-1]) begin
            hw_blinky_o   <= !hw_blinky_o;
            hw_blink_cntr <= 32'h0000_0000;
        end
      end
    end // always @(posedge clk_i)

endmodule // serial_divider

`default_nettype wire
