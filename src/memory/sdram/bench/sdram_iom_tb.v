/*
 * SDRAM controller IO module test bench
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

`include "sdram.vh"

`timescale 1ns/1ps

module sdram_iom_tb#(
    parameter SDRAM_TEST_LEN = 32'h10
    ) ();

    localparam SDRAM_BASE = 32'hE0000000;
    localparam PRNG_BASE  = 32'hC0000000;
    localparam PRNG_SEED  = PRNG_BASE;
    localparam PRNG_RAND  = PRNG_BASE+4;

    reg io_clk, mc_clk, rst;

    // SDRAM signals
    `SDRAM_WIRE_DECLS;

    // IO bus signals
    wire io_addr_strobe, io_read_strobe, io_write_strobe;
    wire [3:0] io_byte_en;
    wire [31:0] io_addr, io_write_data;
    wire [31:0] io_read_data;
    wire io_ready;

    reg [31:0] ram_addr, value_wr, value_rd;
    integer err_count = 0;

    sdram_test_iobus DUT (
        .io_clk(io_clk),
        .io_rst(rst),
        .io_addr_strobe(io_addr_strobe),
        .io_read_strobe(io_read_strobe),
        .io_write_strobe(io_write_strobe),
        .io_address(io_addr),
        .io_byte_enable(io_byte_en),
        .io_write_data(io_write_data),
        .io_read_data(io_read_data),
        .io_ready(io_ready),

        .mc_clk(mc_clk),
        .mc_rst(rst),
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

    mt48lc32m8a2 ram_model (
        .Dq(sdram_dq),
        .Addr(sdram_a),
        .Ba(sdram_ba),
        .Clk(sdram_clk),
        .Cke(sdram_cle),
        .Cs_n(sdram_cs),
        .Ras_n(sdram_ras),
        .Cas_n(sdram_cas),
        .We_n(sdram_we),
        .Dqm(sdram_dqm)
    );

    iobus_master_model io (
        .clk(io_clk),
        .rst(rst),
        .io_addr_strobe(io_addr_strobe),
        .io_read_strobe(io_read_strobe),
        .io_write_strobe(io_write_strobe),
        .io_addr(io_addr),
        .io_byte_en(io_byte_en),
        .io_write_data(io_write_data),
        .io_read_data(io_read_data),
        .io_ready(io_ready)
    );

    // generate IO clock (50 MHz)
    initial begin
        io_clk = 1'b0;
        forever begin
            #10;
            io_clk = ~io_clk;
        end
    end

    // generate MC clock (133.33 MHz)
    initial begin
        mc_clk = 1'b0;
        forever begin
            #3.75;
            mc_clk = ~mc_clk;
        end
    end

    // generate reset
    initial begin
        rst = 1'b1;
        repeat(16) @(negedge io_clk);
        rst = 1'b0;
    end

    // run tests
    initial begin
        $dumpfile("sdram_iom_tb.vcd");
        $dumpvars(0, sdram_iom_tb);

        // wait for reset and some time for SDRAM init
        @(negedge rst);
        #100000;
        @(posedge io_clk);

        /* test pattern
        io.io_write(SDRAM_BASE, 32'h5aa55aa5);
        repeat(10) @(posedge io_clk);
        $finish;
        */

        // init PRNG for known pattern
        io.io_write(PRNG_SEED, 0);

        // fill ram with random data
        for (ram_addr = SDRAM_BASE; ram_addr < SDRAM_BASE+SDRAM_TEST_LEN; ram_addr = ram_addr+4) begin
            io.io_read(PRNG_RAND, value_wr);
            io.io_write(ram_addr, value_wr);
        end

        // init PRNG for known pattern
        io.io_write(PRNG_SEED, 0);

        // check ram for expected data
        for (ram_addr = SDRAM_BASE; ram_addr < SDRAM_BASE+SDRAM_TEST_LEN; ram_addr = ram_addr+4) begin
            io.io_read(PRNG_RAND, value_wr);
            io.io_read(ram_addr, value_rd);
            if (value_rd != value_wr) begin
                err_count += 1;
                $display("%t: ram failure at %h: %h != %h", $time, ram_addr, value_rd, value_wr);
            end
        end

        repeat(16) @(posedge io_clk);
        $display("testbench completed with %d errors", err_count);
        $finish;
    end

endmodule
