/*
 * Pulse Density Modulation Testbench
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

`timescale 1ns/10ps

module pdm_tb();

    reg clk, rst, en;
    reg [7:0] duty;
    wire pdm;

    pdm#(.DUTY_BITS(8)) DUT (
        .clk(clk),
        .rst(rst),
        .en(en),
        .duty(duty),
        .pdm(pdm)
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
        $dumpfile("pdm_tb.vcd");
        $dumpvars(0, pdm_tb);

        en = 1'b0;
        duty = 8'd0;
        @(negedge rst);

        repeat(32) @(posedge clk);

        en = 1'b1;
        duty = 8'd255;
        repeat(32) @(posedge clk);

        en = 1'b0;
        repeat(32) @(posedge clk);

        en = 1'b1;
        duty = 8'd0;
        repeat(300) @(posedge clk);

        duty = 8'd128;
        repeat(300) @(posedge clk);

        duty = 8'd192;
        repeat(300) @(posedge clk);

        duty = 8'd255;
        repeat(300) @(posedge clk);

        duty = 8'd40;
        repeat(300) @(posedge clk);

        $display("%t: PDM testbench complete", $time);
        $finish;
  end

endmodule
