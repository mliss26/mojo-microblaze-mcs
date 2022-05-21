/*
 * Button debouncer testbench
 *
 * Copyright (C) 2022 Matt Liss
 * BSD-3-Clause
 */

`timescale 1ns/1ns

module debounce_tb#(
    parameter CTR_BITS = 20,
    parameter BOUNCE_COUNT_THRESH = 50000
    )();

    reg clk;
    wire btn, out;

    integer err_count = 0;
    integer count = 0; // clock cycle counter
    integer last_out_cnt = 0;
    integer seed;

    debounce#(
        .CTR_BITS(CTR_BITS)
    ) DUT (
        .clk(clk),
        .btn(btn),
        .out(out)
    );

    btn_bounce#(
        .ACTIVE_STATE(1'b1)
    ) button (
        .btn(btn)
    );

    // generate clock
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end
    always @(posedge clk)
        count = count + 1;

    // check debouncer output
    always @(out)
        if (last_out_cnt == 0)
            last_out_cnt = count;
        else begin
            if ((count - last_out_cnt) < BOUNCE_COUNT_THRESH) begin
                err_count += 1;
                $display("ERROR: output bounced in %d cycles", (count - last_out_cnt));
            end
            last_out_cnt = count;
        end

    // run tests
    initial begin
        $dumpfile("debounce_tb.vcd");
        $dumpvars(1, debounce_tb);

        seed = 732;

        #1e6;
        button.press(50e6, seed);
        #1e6;

        $display("testbench finished with %d errors", err_count);
        $finish;
    end

endmodule
