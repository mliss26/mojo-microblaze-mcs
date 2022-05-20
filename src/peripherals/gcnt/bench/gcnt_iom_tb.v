/*
 * Global Counter IO Module testbench
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

`timescale 1ns/10ps

module gcnt_iom_tb();

    localparam COUNT_BITS = 56;

    reg clk, rst;

    wire io_addr_strobe, io_read_strobe, io_write_strobe;
    wire [3:0] io_byte_en;
    wire [31:0] io_addr, io_write_data;
    wire [31:0] io_read_data;
    wire io_ready;

    reg [31:0] value;

    integer err_count = 0;

    // instantiate DUT
    gcnt_iom#(
        .COUNT_BITS(COUNT_BITS)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .io_addr_strobe(io_addr_strobe),
        .io_read_strobe(io_read_strobe),
        .io_write_strobe(io_write_strobe),
        .io_address(io_addr[11:0]),
        .io_byte_enable(io_byte_en),
        .io_write_data(io_write_data),
        .io_read_data(io_read_data),
        .io_ready(io_ready)
    );

    iobus_master_model io (
        .clk(clk),
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
        $dumpfile("gcnt_iom_tb.vcd");
        $dumpvars(0, gcnt_iom_tb);

        // wait for reset and next clock
        @(negedge rst);
        @(posedge clk);

        // read the counter
        io.io_read(0, value);
        $display("%t: io_read(0) = %h", $time, value);
        if (value != 1)
            err_count = err_count + 1;
        io.io_read(4, value);
        $display("%t: io_read(4) = %h", $time, value);
        if (value != 0)
            err_count = err_count + 1;

        repeat(2) @(posedge clk);

        io.io_read(32'h1000, value);
        $display("%t: io_read(0x1000) = %h", $time, value);
        if (value != 7)
            err_count = err_count + 1;
        io.io_read(32'h1004, value);
        $display("%t: io_read(0x1004) = %h", $time, value);
        if (value != 0)
            err_count = err_count + 1;

        repeat(50) @(posedge clk);

        io.io_read(32'h2000, value);
        $display("%t: io_read(0x2000) = %h", $time, value);
        if (value != 32'h3d)
            err_count = err_count + 1;
        io.io_read(32'h2004, value);
        $display("%t: io_read(0x2004) = %h", $time, value);
        if (value != 0)
            err_count = err_count + 1;

        repeat(31) @(posedge clk);

        io.io_read(32'h3000, value);
        $display("%t: io_read(0x3000) = %h", $time, value);
        if (value != 32'h60)
            err_count = err_count + 1;
        io.io_read(32'h3004, value);
        $display("%t: io_read(0x3004) = %h", $time, value);
        if (value != 0)
            err_count = err_count + 1;

        repeat(2) @(posedge clk);

        $display("testbench finished with %d errors", err_count);
        $finish;
    end

endmodule
