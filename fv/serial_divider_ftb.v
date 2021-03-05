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
    wire             wbs_stb_i;
    wire             wbs_cyc_i;
    wire             wbs_we_i;
    wire [WBW/8-1:0] wbs_sel_i;
    wire [WBW-1  :0] wbs_dat_i;
    wire [WBW-1  :0] wbs_adr_i;
    wire             wbs_ack_o;
    wire [WBW-1  :0] wbs_dat_o;

    // Logic Analyzer Signals
    wire [127:0] la_data_out;

    wire         hw_blink_o;
    wire         sw_blink_o;

    reg f_past_valid = 0;
    initial assume(rst);

    always @(posedge clk) begin
      f_past_valid <= 1;

      // Prevent writes to both args/results and control regs in same cycle
      assume (~( |(wbs_adr_i[WBW-1:WBW-4]) & |(wbs_adr_i[WBW-5:WBW-8]) ));
      assume (~serial_divider_u0.debug);

      // No back-to-back transactions
      if (f_past_valid) begin
        if (wbs_ack_o)
          assume ( (wbs_stb_i == 1'b0) && (wbs_cyc_i == 1'b0) );
      end

      if (f_past_valid) begin
        //_set_dividend_:  cover( (la_data_out[31:0] == serial_divider_u0.dividend ) &&
        //                        (la_data_out[31:0] != 32'h0000_0000              ) );

        _calc_quotient_: cover ( (la_data_out[31:0] == 32'h0000_0004) &&
                                 (fini              == 1'b1         ) );

        _set_start_:     cover (start == 1'b1);

        /*
        _set_divisor_:  cover( (la_data_out[ 95:64] == serial_divider_u0.divisor  ) &&
                               (la_data_out[ 95:64] != 32'h0000_0000              ) );

        _set_d_and_d_:  cover( (la_data_out[ 95:64] == serial_divider_u0.divisor  ) &&
                               (la_data_out[127:96] == serial_divider_u0.dividend ) &&
                               (la_data_out[ 95:64] != 32'h0000_0000              ) &&
                               (la_data_out[127:96] != 32'h0000_0000              ) );

        _set_all_:      cover( (la_data_out[127:96] == serial_divider_u0.dividend ) &&
                               (la_data_out[ 95:64] == serial_divider_u0.divisor  ) &&
                               (la_data_out[ 63:32] == serial_divider_u0.quotient ) &&
                               (la_data_out[ 31: 0] == serial_divider_u0.remainder) &&
                               (la_data_out[127:96] != 32'h0000_0000              ) &&
                               (la_data_out[ 95:64] != 32'h0000_0000              ) &&
                               (la_data_out[ 63:32] != 32'h0000_0000              ) &&
                               (la_data_out[ 31: 0] != 32'h0000_0000              ) );
        */
      end
    end

    serial_divider #(
        .WBW  (32),
        .LAW  (32),
        .XLEN (32),
        .BLINK_CYCLES (32_000),
    ) serial_divider_u0 (
        .clk_i       (clk),
        .reset_i     (rst),

        .start_o     (start),
        .fini_o      (fini),

        .wbs_stb_i   (wbs_stb_i),
        .wbs_cyc_i   (wbs_cyc_i),
        .wbs_we_i    (wbs_we_i),
        .wbs_sel_i   (wbs_sel_i),
        .wbs_adr_i   (wbs_adr_i),
        .wbs_dat_i   (wbs_dat_i),
        .wbs_ack_o   (wbs_ack_o),
        .wbs_dat_o   (wbs_dat_o),
        .la_data_o   (la_data_out),
        .hw_blinky_o (hw_blinky_o),
        .sw_blinky_o (sw_blinky_o)
    );

endmodule: serial_divider_ftb

`default_nettype wire
