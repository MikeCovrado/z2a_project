/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

#include "../../defs.h"
#include "../serial_divider_defs.h"
#include "../../stub.c"

/*
  SERIAL_DIVIDER Smoke Test:
    - Borrows heavily from example user project test2.c
    - several write/read checks of serial_divider CSRs via Wishbone
    - hardware and software blinky LED
    - reg_mprj_datal sets MPRJ_IO[31:0]
      The values 0xAB610000 and 0xAB600000 are magic numbers expected
      by the testbench.
*/

int clk = 0;
int cyc_cnt;
int i, j;

void main()
{
    // All GPIO pins are configured to be output
    // Used to flag the start/end of a test

    reg_mprj_io_37 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_36 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_35 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_34 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_33 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_32 = GPIO_MODE_MGMT_STD_OUTPUT;

    reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;

    reg_mprj_io_15 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_14 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_13 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_12 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_11 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_10 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_9  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_8  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_7  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_6  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_5  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_4  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_3  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_2  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_1  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_0  = GPIO_MODE_USER_STD_OUTPUT;

    /* Apply configuration */
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);

    // Configure All LA probes as inputs to the cpu
    reg_la0_ena = 0xFFFFFFFF;    // [31:0]
    reg_la1_ena = 0xFFFFFFFF;    // [63:32]
    reg_la2_ena = 0xFFFFFFFF;    // [95:64]
    reg_la3_ena = 0xFFFFFFFF;    // [127:96]

    // Flag start of the test
    reg_mprj_datal = 0xAB600000;

    // Configure LA[64] LA[65] as outputs from the cpu
    reg_la2_ena  = 0xFFFFFFFC;

    // Set clk & reset to one
    reg_la2_data = 0x00000003;

    // Set active (connected to la_data_in[32])
    reg_la1_data = 0x00000001;

    ///////////////////////////////////////////////////////////////////////////
    // These are defined in ../serial_divider_defs.h

    // 'typical' serial_divider use case:
    reg_mprj_slave_dividend  = 0x00000040;  // set DIVIDEND
    reg_mprj_slave_divisor   = 0x00000008;  // set DIVISOR
    reg_mprj_slave_start     = 0x1;         // start divider
    while (reg_mprj_slave_fini != 1);       // poll for completion
    j = reg_mprj_slave_quotient;            // fetch QUOTIENT
    j = reg_mprj_slave_remainder;           // fetch REMAINDER

    reg_mprj_slave_remainder = 0x01010101; // ingored: debug not set
    reg_mprj_slave_quotient  = 0x02020202; // ignored: debug not set

    reg_mprj_slave_debug     = 0x1;        // set debug

    reg_mprj_slave_quotient  = 0x02020202; // works: debug set
    reg_mprj_slave_remainder = 0x01010101; // works: debug set

    j = reg_mprj_slave_debug;              // clear debug

    // Toggle clk & de-assert reset
    // Use same to blink the LED (on MPRJ_IO[0])
    /*
    for (i=0; i<2; i=i+1) {
        reg_mprj_slave_sw_blinky = 0x1; // write (anything) to turn on
        for (cyc_cnt = 0; cyc_cnt < (LED_PERIOD/2); cyc_cnt++) {
           clk = !clk;
           reg_la2_data = 0x00000000 | clk;
        }

        j = reg_mprj_slave_sw_blinky;   // read to turn off
        for (cyc_cnt = 0; cyc_cnt < (LED_PERIOD/2); cyc_cnt++) {
           clk = !clk;
           reg_la2_data = 0x00000000 | clk;
        }
    }
    */

    // By default, Logical Analyzer 0 data driven by DIVISOR
    reg_mprj_slave_divisor = 0x04040404;
    if (reg_la0_data == 0x04040404) {
        reg_mprj_datal = 0xAB610000;
    }

}

