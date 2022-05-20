/*
 * MicroBlaze MCS IO bus multiplexer for SDRAM testbench
 *
 * Instantates the SDRAM controller and PRNG IO modules
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

`define IOMUX_CONNECT(addr_idx)     \
        .clk(io_clk), \
        .rst(io_rst), \
        .io_addr_strobe(core_addr_strobe[(addr_idx)]), \
        .io_read_strobe(io_read_strobe), \
        .io_write_strobe(io_write_strobe), \
        .io_address(io_address[11:0]), \
        .io_byte_enable(io_byte_enable), \
        .io_write_data(io_write_data), \
        .io_read_data(core_read_data[32*(addr_idx)+31:32*(addr_idx)]), \
        .io_ready(core_ready[(addr_idx)])


module sdram_test_iobus#(
    parameter BASE_ADDRESS = 32'hc0000000,
    parameter ADDRESS_STRIDE = 32'h1000
    ) (
    // io bus signals
    input io_clk,
    input io_rst,
    input io_addr_strobe,
    input io_read_strobe,
    input io_write_strobe,
    input [31:0] io_address,
    input [3:0] io_byte_enable,
    input [31:0] io_write_data,
    output [31:0] io_read_data,
    output io_ready,

    // SDRAM signals
    input mc_clk,
    input mc_rst,
    output sdram_clk,
    output sdram_cle,
    output sdram_cs,
    output sdram_cas,
    output sdram_ras,
    output sdram_we,
    output sdram_dqm,
    output [1:0] sdram_ba,
    output [12:0] sdram_a,
    inout [7:0] sdram_dq
    );

    localparam CORE_COUNT = 2;

    // one additional set of ios for default responder
    wire [CORE_COUNT-1:0] core_addr_strobe;
    wire [CORE_COUNT:0] core_ready;
    wire [31+32*(CORE_COUNT):0] core_read_data;

    // memory controller has upper half of IO space
    wire mc_addr_strobe;
    assign mc_addr_strobe = io_addr_strobe & (&io_address[31:29]); // 0xE0000000++

    // partial address decoding for the cores
    iobus_address_compare#(
        .BASE_ADDRESS(BASE_ADDRESS),
        .ADDRESS_STRIDE(ADDRESS_STRIDE),
        .CORE_COUNT(CORE_COUNT-1)
    ) addr_cmp (
        .addr_strobe(io_addr_strobe),
        .address({io_address[31:12],12'b0}),
        .strobe_out(core_addr_strobe)
    );

    // mux for core output signals
    iobus_output_mux#(
        .CORE_COUNT(CORE_COUNT+1)
    ) output_mux (
        .read_data_in(core_read_data),
        .ready_in(core_ready),
        .read_data_out(io_read_data),
        .ready_out(io_ready)
    );

    // default responder to avoid bus hangs if reading from urouted address
    iobus_default_response default_resp (
        .io_addr_strobe(core_addr_strobe[CORE_COUNT-1]),
        .io_read_data(core_read_data[32*CORE_COUNT +: 32]),
        .io_ready(core_ready[CORE_COUNT])
    );

    // SDRAM memory controller (custom io wiring, must be last io core in mux)
    sdram_iom sdram_module (
        .io_clk(io_clk),
        .io_rst(io_rst),
        .io_addr_strobe(mc_addr_strobe),
        .io_read_strobe(io_read_strobe),
        .io_write_strobe(io_write_strobe),
        .io_address(io_address[24:0]),
        .io_byte_enable(io_byte_enable),
        .io_write_data(io_write_data),
        .io_read_data(core_read_data[32*(CORE_COUNT-1)+31:32*(CORE_COUNT-1)]),
        .io_ready(core_ready[(CORE_COUNT-1)]),

        .mc_clk(mc_clk),
        .mc_rst(mc_rst),
        .sdram_clk(sdram_clk),
        .sdram_cle(sdram_cle),
        .sdram_cs(sdram_cs),
        .sdram_cas(sdram_cas),
        .sdram_ras(sdram_ras),
        .sdram_we(sdram_we),
        .sdram_dqm(sdram_dqm),
        .sdram_ba(sdram_ba),
        .sdram_a(sdram_a),
        .sdram_dq(sdram_dq)
    );

    //instantiate cores
    prng_iom prng_module (
        `IOMUX_CONNECT(0)
    );

endmodule
