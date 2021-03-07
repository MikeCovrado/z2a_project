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

module serial_divider_ftb #(
    parameter WBW  = 32,
              LAW  = 32, // Logic Analyzer width
              XLEN = 32, // Data width of Dividend, Divisor and Quotient
              BLINK_CYCLES = 32_000  // period in clk cycles of hw blink
)();
    // Wishbone Slave ports (WB MI A)
    reg              clk;
    reg              rst;
    reg              wbs_stb_i;
    reg              wbs_cyc_i;
    reg              wbs_we_i;
    reg  [WBW/8-1:0] wbs_sel_i;
    reg  [WBW-1  :0] wbs_dat_i;
    reg  [WBW-1  :0] wbs_adr_i;
    wire             wbs_ack_o;
    wire [WBW-1  :0] wbs_dat_o;

    // Select what is presented on Logical Analyzer outputs
    localparam   SELDIVISOR   = 2'b00,
                 SELDIVIDEND  = 2'b01,
                 SELQUOTIENT  = 2'b10,
                 SELREMAINDER = 2'b11;

    // Logic Analyzer Signals
    reg [127:0] la_data_out;

    reg         hw_blinky_o;
    reg         sw_blinky_o;

    reg         start;
    reg         fini;
    reg   [3:0] hw_sel;

    // initial conditions
    reg f_past_valid = 0;
    initial begin
      assume(rst);
      assume(~wbs_stb_i);
      assume(~wbs_cyc_i);
      assume(~wbs_we_i);
      assume(~|wbs_sel_i);
      assume(~|wbs_dat_i);
      assume(~|wbs_adr_i);
    end

    always @(posedge clk) begin
      f_past_valid <= 1;

      // Prevent writes to both args/results and control regs in same cycle
      assume (~( |(wbs_adr_i[WBW-1:WBW-4]) & |(wbs_adr_i[WBW-5:WBW-8]) ));
      //assume (~serial_divider.debug);
      assume ( hw_sel[3]);

      // No back-to-back transactions
      if (f_past_valid) begin
        if (wbs_ack_o)
          assume ( (wbs_stb_i == 1'b0) && (wbs_cyc_i == 1'b0) );
      end

      if (f_past_valid) begin
       // let's see an easy division operation actually happen
        _calc_quotient_: cover ( (la_data_out[31:0]       == 32'h0000_0004) &&
                                 (hw_sel[1:0]             == SELQUOTIENT)   &&
                                 (fini                    == 1'b1         ) );

        _set_start_:     cover (start == 1'b1);

      end
    end

    proj_serial_divider #(
        .WBW  (32),
        .LAW  (32),
        .XLEN (32),
        .BLINK_CYCLES (32_000),
    ) serial_divider (
        .clk_i       (clk),
        .reset_i     (rst),
        .wbs_stb_i   (wbs_stb_i),
        .wbs_cyc_i   (wbs_cyc_i),
        .wbs_we_i    (wbs_we_i),
        .wbs_sel_i   (wbs_sel_i),
        .wbs_adr_i   (wbs_adr_i),
        .wbs_dat_i   (wbs_dat_i),
        .wbs_ack_o   (wbs_ack_o),
        .wbs_dat_o   (wbs_dat_o),
        .la_data_o   (la_data_out[31:0]),
        .hw_blinky_o (hw_blinky_o),
        .sw_blinky_o (sw_blinky_o),
        .start_o     (start),
        .fini_o      (fini),
        .hw_sel_i    (hw_sel)
    );

endmodule: serial_divider_ftb

`default_nettype wire
