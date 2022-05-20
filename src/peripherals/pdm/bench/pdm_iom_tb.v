/*
 * PDM IO Module testbench
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

`timescale 1ns/10ps

module pdm_iom_tb();

    localparam PDM_COUNT = 4;

    integer i;

    reg clk, rst;
    wire [PDM_COUNT-1:0] pdm;

    wire io_addr_strobe, io_read_strobe, io_write_strobe;
    wire [3:0] io_byte_en;
    wire [31:0] io_addr, io_write_data;
    wire [31:0] io_read_data;
    wire io_ready;

    reg [31:0] value;

    // instantiate DUT
    pdm_iom#(
        .PDM_COUNT(PDM_COUNT)
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
        .io_ready(io_ready),
        .pdm(pdm)
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
        $dumpfile("pdm_iom_tb.vcd");
        $dumpvars(0, pdm_iom_tb);

        // wait for reset and next clock
        @(negedge rst);
        @(posedge clk);

        // perform initial read of all addresses
        io.io_read(32'h0000, value);
        repeat(2) @(posedge clk);

        for (i = 0; i < PDM_COUNT; i = i+1)
            io.io_read(32'h0000+4*(i+1), value);
        repeat(2) @(posedge clk);

        // enable all PDMs
        io.io_write(32'h1000, 32'hffffffff);
        io.io_read(32'h1000, value);
        repeat(4) @(posedge clk);

        // max out all PDMs
        for (i = 0; i < PDM_COUNT; i = i+1) begin
            io.io_write(32'h1000+4*(i+1), 32'hffffffff);
            io.io_read(32'h1000+4*(i+1), value);
        end
        repeat(4) @(posedge clk);

        // disable all PDMs
        io.io_write(32'h2000, 32'h0);
        repeat(4) @(posedge clk);

        // enable PDMs one at a time
        for (i = 0; i < PDM_COUNT; i = i+1) begin
            io.io_write(32'h2000, 32'h1 << i);
            repeat(8) @(posedge clk);
        end

        // enable all PDMs at different duty cycles
        io.io_write(32'h5000, 32'hffffffff);
        for (i = 0; i < PDM_COUNT; i = i+1) begin
            io.io_write(32'h5000+4*(i+1), 32'd32*(i+1));
        end
        repeat(32) @(posedge clk);

        $display("%t: PDM IO module testbench complete", $time);
        $finish;
    end

endmodule
