/*
 * Counter testbench
 *
 * Copyright (C) 2022 Matt Liss
 * BSD-3-Clause
 */

`timescale 1ns/10ps

module counter_tb ();

    localparam COUNT_BITS = 6;
    localparam HIDDEN_BITS = 0;

    reg clk, rst;
    wire [COUNT_BITS-1:0] count;

    integer i, err_count = 0;

    counter #(
        .COUNT_BITS(COUNT_BITS),
        .HIDDEN_BITS(HIDDEN_BITS)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .count(count)
    );

    // check the counter value
    always @(posedge clk) begin
        if (rst || (i == {COUNT_BITS{1'b1}}))
            i <= 0;
        else
            i <= i + 1;

        if (i != count) begin
            $display("ERROR: counter has value %d, expected %d", count, i);
            err_count = err_count + 1;
        end
    end

    // generate reset and clock
    initial begin
        $dumpfile("counter_tb.vcd");
        $dumpvars(0, counter_tb);

        clk = 1'b0;
        rst = 1'b1;
        repeat(4) #10 clk = ~clk;

        rst = 1'b0;
        repeat(1000) #10 clk = ~clk;

        $display("test finished with %d errors", err_count);
        $finish;
    end

endmodule
