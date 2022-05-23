/*
 * MicroBlaze IO bus testbench
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */
`include "sdram.vh"

`timescale 1ns/10ps

module iobus_top_tb();

    localparam BASE_ADDRESS = 32'hc0000000;
    localparam ADDRESS_STRIDE = 32'h1000;
    localparam PDM_COUNT = 4;
    localparam CORE_COUNT = 5;

    localparam SDRAM_BASE = 32'hE0000000;
    localparam PRNG_BASE  = 32'hC0002000;
    localparam PRNG_SEED  = PRNG_BASE;
    localparam PRNG_RAND  = PRNG_BASE+4;

    // test signals
    reg [31:0] test_addr, value_wr, value_rd = 0;
    integer i, err_count = 0;

    reg io_clk, mc_clk, rst;

    // SDRAM signals
    `SDRAM_WIRE_DECLS;

    // IO bus signals
    wire io_addr_strobe, io_read_strobe, io_write_strobe;
    wire [3:0] io_byte_en;
    wire [31:0] io_addr, io_write_data;
    wire [31:0] io_read_data;
    wire io_ready;

    // PDM outputs
    wire [PDM_COUNT-1:0] pdm;

    iobus_top#(
        .BASE_ADDRESS(BASE_ADDRESS),
        .ADDRESS_STRIDE(ADDRESS_STRIDE),
        .PDM_COUNT(PDM_COUNT)
    ) DUT (
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
        .sdram_dq(sdram_dq),

        .pdm(pdm)
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
        $dumpfile("iobus_top_tb.vcd");
        $dumpvars(2, iobus_top_tb);

        // wait for reset and some time for SDRAM init
        @(negedge rst);
        #100000;
        @(posedge io_clk);

        /*
         * read first and last addrs from all the IO modules
         */
        for (i = 0; i < CORE_COUNT; i = i+1) begin

            test_addr = BASE_ADDRESS + ADDRESS_STRIDE*i;
            io.io_read(test_addr, value_rd);

            if ((i == (CORE_COUNT-1) && value_rd != 32'hffffffff)
                    || (i < (CORE_COUNT-1) && value_rd == 32'hffffffff)) begin
                err_count += 1;
                $display("read unexpected value from 0x%h: 0x%h", test_addr, value_rd);
            end

            test_addr += 4;
            io.io_read(test_addr, value_rd);

            if ((i == (CORE_COUNT-1) && value_rd != 32'hffffffff)
                    || (i < (CORE_COUNT-1) && value_rd == 32'hffffffff)) begin
                err_count += 1;
                $display("read unexpected value from 0x%h: 0x%h", test_addr, value_rd);
            end

            test_addr = BASE_ADDRESS + ADDRESS_STRIDE*i + 32'hffc;
            io.io_read(test_addr, value_rd);

            if ((i == (CORE_COUNT-1) && value_rd != 32'hffffffff)
                    || (i < (CORE_COUNT-1) && value_rd == 32'hffffffff)) begin
                err_count += 1;
                $display("read unexpected value from 0x%h: 0x%h", test_addr, value_rd);
            end

            repeat(2) @(posedge io_clk);
        end

        // read and write a couple random value to SDRAM
        for (i = 0; i < 20; i += 4) begin
            test_addr = SDRAM_BASE + i;

            io.io_read(PRNG_RAND, value_wr);
            io.io_write(test_addr, value_wr);
            io.io_read(test_addr, value_rd);

            if (value_rd != value_wr) begin
                err_count += 1;
                $display("SDRAM 0x%h: wrote 0x%h, read 0x%h", test_addr, value_wr, value_rd);
            end
        end

        repeat(16) @(posedge io_clk);
        $display("testbench completed with %d errors", err_count);
        $finish;
    end

endmodule
