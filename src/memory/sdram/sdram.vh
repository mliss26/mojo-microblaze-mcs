/*
 * SDRAM shared definitions
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */
`ifndef _sdram_vh_
`define _sdram_vh_


// define this only for 50 MHz clock, leave undefined for anything higher
//`define SDRAM_CLK_50MHZ

`define SDRAM_WIRE_DECLS            \
            wire sdram_clk;         \
            wire sdram_cle;         \
            wire sdram_cs;          \
            wire sdram_cas;         \
            wire sdram_ras;         \
            wire sdram_we;          \
            wire sdram_dqm;         \
            wire [1:0] sdram_ba;    \
            wire [12:0] sdram_a;    \
            wire [7:0] sdram_dq


`endif
