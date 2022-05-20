/*
 * Testbench for async handshake clock boundry crossing
 *
 * Matt Liss
 * 2022
 */

`timescale 1ns/10ps

module async_handshake_tb #(
    parameter SRC_CLK_DELAY = 3.75, // (133.33 MHz)
    parameter DST_CLK_DELAY = 10,   // (50 MHz)
    parameter DATA_W = 8
    ) ();

    reg rst, clk_src, clk_dst, valid_src, ready_dst;
    wire valid_dst, ready_src;

    reg  [DATA_W-1:0] data_src;
    wire [DATA_W-1:0] data_dst;

    async_handshake #(
        .DATA_W(DATA_W)
    ) DUT (
        .rst_src(rst),
        .clk_src(clk_src),
        .data_src(data_src),
        .valid_src(valid_src),
        .ready_src(ready_src),
        .rst_dst(rst),
        .clk_dst(clk_dst),
        .data_dst(data_dst),
        .valid_dst(valid_dst),
        .ready_dst(ready_dst)
    );

    // generate source clock
    initial begin
        clk_src = 0;
        forever #SRC_CLK_DELAY clk_src = ~clk_src;
    end

    // generate destination clock
    initial begin
        clk_dst = 0;
        forever #DST_CLK_DELAY clk_dst = ~clk_dst;
    end

    // generate reset
    initial begin
        rst = 1'b1;
        repeat(4) @(negedge clk_dst);
        rst = 1'b0;
    end

    // run tests
    initial begin
        $dumpfile("async_handshake_tb.vcd");
        $dumpvars(0, async_handshake_tb);

        valid_src = 1'b0;
        ready_dst = 1'b0;
        data_src = {DATA_W{1'b0}};

        // wait for reset to begin
        @(negedge rst);
        @(posedge clk_src) #1;

        // check current output state
        if (data_dst != {DATA_W{1'b0}} || valid_dst == 1'b1 || ready_src == 1'b1)
            $display("%t: ERROR: invalid initial state", $time);
        else
            $display("%t: INFO: initial state valid", $time);

        // set src data
        data_src = 8'hA5;

        // signal valid from src => dst
        @(posedge clk_src) valid_src <= #1 1'b1;
        @(posedge clk_src) valid_src <= #1 1'b0;

        // wait for dst valid
        while (~valid_dst)
            @(posedge clk_dst) #1;

        // check current output state
        #1;
        if (data_dst != 8'hA5 || ready_src == 1'b1)
            $display("%t: ERROR: invalid src->dest state", $time);
        else
            $display("%t: INFO: src->dest state valid", $time);

        // signal ready from dst => src
        #1 ready_dst = 1'b1;
        @(posedge clk_dst) ready_dst <= #1 1'b0;

        // wait for src ready
        while (~ready_src)
            @(posedge clk_src) #1;

        // update source data for next transfer cycle
        data_src = 8'h5A;

        // check current output state
        if (data_dst != 8'hA5 || valid_src == 1'b1)
            $display("%t: ERROR: invalid final state", $time);
        else
            $display("%t: INFO: final state valid", $time);

        // end after a small window
        @(posedge clk_src);
        @(posedge clk_dst);
        $finish;
    end

endmodule
