/*
 * SPDX-FileCopyrightText: 2021 Mike Thompson (Covrado)
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
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#ifndef _LOCAL_DEFS_H_
#define _LOCAL_DEFS_H_

// Address map for resources in mike_proj
#define reg_mprj_slave_dividend  (*(volatile uint32_t*)0x30000000)
#define reg_mprj_slave_divisor   (*(volatile uint32_t*)0x30000004)
#define reg_mprj_slave_quotient  (*(volatile uint32_t*)0x30000008)
#define reg_mprj_slave_remainder (*(volatile uint32_t*)0x3000000C)
#define reg_mprj_slave_debug     (*(volatile uint32_t*)0x30000010)
#define reg_mprj_slave_fini      (*(volatile uint32_t*)0x30000014)
#define reg_mprj_slave_start     (*(volatile uint32_t*)0x30000018)
#define reg_mprj_slave_sw_blinky (*(volatile uint32_t*)0x3000001C)

// LED_PERIOD==10 yields a period of ~285us.
#define LED_PERIOD 10

#endif
