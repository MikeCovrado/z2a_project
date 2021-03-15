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

`default_nettype none

`timescale 1 ns / 1 ps

`include "caravel.v"
`include "spiflash.v"

module smoke_test_tb;
  reg clock;
  reg RSTB;
  reg power1;
  reg power2;

  wire        gpio;
  wire [37:0] mprj_io;
  wire [15:0] checkbits;

  integer     wdt_loop;

  assign checkbits = mprj_io[31:16];

  always #12.5 clock <= (clock === 1'b0);

  initial begin
    clock = 0;
  end

  initial begin
    $dumpfile("smoke_test.caravel_u0.mprj.vcd");
    $dumpvars(0, smoke_test_tb.caravel_u0.mprj);
    //$dumpfile("smoke_test.vcd");
    //$dumpvars(0, smoke_test_tb);
    $timeformat(-9, 1, "ns", 5);

    // Repeat cycles of 1000 clock edges as needed to complete testbench
    wdt_loop = 0;
    repeat (30) begin
      repeat (1000) @(posedge clock);
      $display("%0t: %0d*1000 cycles", $time, ++wdt_loop);
    end
    $display("%c[1;31m",27);
    $display("%m @ %0t: Timeout, Test Mega-Project IO (RTL) Failed", $time);
    $display("%c[0m",27);
    $finish;
  end

  initial begin
    wait(checkbits == 16'h AB60);
    $display("%m @ %0t: Smoke Test MPRJ-Serial-Divider Started", $time);
    wait(checkbits == 16'h AB61);
    $display("%m @ %0t: Smoke Test MPRJ-Serial-Divider Passed", $time);
    repeat (100) @(posedge clock);
    $display("%m @ %0t: Smoke Test terminating simulation", $time);
    $finish;
  end

  initial begin
    RSTB <= 1'b0;
    #1000;
    RSTB <= 1'b1;       // Release reset
    #2000;
  end

  initial begin       // Power-up sequence
    power1 <= 1'b0;
    power2 <= 1'b0;
    #200;
    power1 <= 1'b1;
    #200;
    power2 <= 1'b1;
  end

  wire flash_csb;
  wire flash_clk;
  wire flash_io0;
  wire flash_io1;

  wire VDD1V8;
  wire VDD3V3;
  wire VSS;

  assign VDD3V3 = power1;
  assign VDD1V8 = power2;
  assign VSS = 1'b0;

  caravel caravel_u0 (
    .vddio    (VDD3V3),
    .vssio    (VSS),
    .vdda     (VDD3V3),
    .vssa     (VSS),
    .vccd     (VDD1V8),
    .vssd     (VSS),
    .vdda1    (VDD3V3),
    .vdda2    (VDD3V3),
    .vssa1    (VSS),
    .vssa2    (VSS),
    .vccd1    (VDD1V8),
    .vccd2    (VDD1V8),
    .vssd1    (VSS),
    .vssd2    (VSS),
    .clock    (clock),
    .gpio     (gpio),
    .mprj_io  (mprj_io),
    .flash_csb(flash_csb),
    .flash_clk(flash_clk),
    .flash_io0(flash_io0),
    .flash_io1(flash_io1),
    .resetb   (RSTB)
  );

  spiflash #(
    .FILENAME("smoke_test.hex")
  ) spiflash (
    .csb(flash_csb),
    .clk(flash_clk),
    .io0(flash_io0),
    .io1(flash_io1),
    .io2(),
    .io3()
  );

endmodule //smoke_test_tb;

`default_nettype wire
