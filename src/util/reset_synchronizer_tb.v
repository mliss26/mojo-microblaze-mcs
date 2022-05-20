/*
 * Testbench for reset synchronizer
 *
 * Copyright (C) 2022 Matt Liss
 * BSD-3-Clause
 */

`timescale 1ns/10ps

module reset_synchronizer_tb ();

    localparam DELAY = 8;

    reg clk, rst;
    wire rst_out;

    integer i = 0, err_count = 0;

    reset_synchronizer #(.DELAY(DELAY)) DUT (
        .clk(clk),
        .rst_in(rst),
        .rst_out(rst_out)
    );

    // check value of reset output
    always @(posedge clk) begin
        if (rst)
            i <= 0;
        else
            i <= i + 1;

        if (i < DELAY) begin
            if (rst_out != 1'b1) begin
                $display("ERROR: expected rst_out == 1 at %t", $time);
                err_count = err_count + 1;
            end
        end else begin
            if (rst_out != 1'b0) begin
                $display("ERROR: expected rst_out == 0 at %t", $time);
                err_count = err_count + 1;
            end
        end
    end

    // generate reset and clock
    initial begin
        $dumpfile("reset_synchronizer_tb.vcd");
        $dumpvars(0, reset_synchronizer_tb);

        clk = 1'b0;
        rst = 1'b1;
        repeat(4) #10 clk = ~clk;
        rst = 1'b0;
        repeat(47) #10 clk = ~clk;

        rst = 1'b1;
        repeat(20) #10 clk = ~clk;
        rst = 1'b0;
        repeat(48) #10 clk = ~clk;

        $display("test finished with %d errors", err_count);
        $finish;
    end

endmodule
