/*
 * PRNG testbench
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

`timescale 1ns/10ps

module prng_tb#(
    parameter PRNG_SEED = 32'hdeadbeef,
    parameter RAND_COUNT = 100000
    ) ();

    reg clk, rst, next;
    reg [31:0] seed;
    wire [31:0] rand;

    integer i;

    // instantiate DUT
    prng DUT (
        .clk(clk),
        .rst(rst),
        .next(next),
        .seed(seed),
        .num(rand)
    );

    // generate reset and clock
    initial begin
        clk = 1'b0;
        rst = 1'b1;
        repeat(4) #10 clk = ~clk;
        rst = 1'b0;
        forever #10 clk = ~clk;
    end

    // run tests
    initial begin
        $dumpfile("prng_tb.vcd");
        $dumpvars(0, prng_tb);

        seed = PRNG_SEED;
        next = 1'b0;
        @(negedge rst);
        @(posedge clk);

        for (i = 0; i < RAND_COUNT; i = i+1) begin
            next = 1'b1;
            @(posedge clk);
            $display("0x%h", rand);
            next = 1'b0;
            @(posedge clk);
        end

        $finish;
    end
endmodule
