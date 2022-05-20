/*
 * SDRAM controller test bench
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

`include "sdram.vh"

`timescale 1ns/1ps

module sdram_tb();

    reg clk, rst;

    `SDRAM_WIRE_DECLS;

    wire [22:0] addr;
    wire rw;
    wire [31:0] data_in, data_out;
    wire busy;
    wire in_valid, out_valid;

    wire [7:0] leds;

    sdram DUT (
        .clk(clk),
        .rst(rst),
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
        .addr(addr),
        .rw(rw),
        .data_in(data_in),
        .data_out(data_out),
        .busy(busy),
        .in_valid(in_valid),
        .out_valid(out_valid)
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

    ram_test ram_test (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .rw(rw),
        .data_in(data_in),
        .data_out(data_out),
        .busy(busy),
        .in_valid(in_valid),
        .out_valid(out_valid),
        .leds(leds)
    );

    // generate clock and reset
    initial begin
        clk = 1'b0;
        rst = 1'b1;
        repeat(32) #5 clk = ~clk;
        rst = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("sdram_tb.vcd");
        $dumpvars(0, sdram_tb);

        // wait for complete write/read cycle
        repeat(2) @(negedge leds[7]);
        $display("read errors: %h", leds[6:0]);
        $finish();
    end

endmodule
