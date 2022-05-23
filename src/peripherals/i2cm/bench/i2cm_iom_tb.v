/*
 * I2C master IO Module testbench
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

`include "timescale.v"

module i2cm_iom_tb();

    localparam PRER_LO = 5'b00000;
    localparam PRER_HI = 5'b00100;
    localparam CTR     = 5'b01000;
    localparam RXR     = 5'b01100;
    localparam TXR     = 5'b01100;
    localparam CR      = 5'b10000;
    localparam SR      = 5'b10000;

    localparam TXR_R   = 5'b10100; // undocumented / reserved output
    localparam CR_R    = 5'b11000; // undocumented / reserved output

    localparam RD      = 1'b1;
    localparam WR      = 1'b0;
    localparam SADR    = 7'b0010_000;

    reg clk, rst;

    wire io_addr_strobe, io_read_strobe, io_write_strobe;
    wire [3:0] io_byte_en;
    wire [31:0] io_addr, io_write_data;
    wire [31:0] io_read_data;
    wire io_ready;

    reg [31:0] value;

    wire irq;
    wire scl, sda;

    pullup(scl);
    pullup(sda);

    // instantiate DUT
    i2cm_iom DUT (
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
        .irq(irq),
        .scl(scl),
        .sda(sda)
    );

    // IO bus master simulator helper
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

    // TODO instantiate I2C slave model and send some traffic

    // generate reset and clock
    initial begin
        clk = 1'b0;
        rst = 1'b1;
        repeat(2) #10 clk = ~clk;
        rst = 1'b0;
        forever #10 clk = ~clk;
    end

    // run tests
    initial begin
        $dumpfile("i2cm_iom_tb.vcd");
        $dumpvars(0, i2cm_iom_tb);

        value = 32'b0;
        @(negedge rst);
        @(posedge clk);

        io.io_write(PRER_LO, 32'hfa);
        io.io_write(PRER_LO, 32'hc8);
        io.io_write(PRER_HI, 32'h00);

        repeat(2) @(posedge clk);

        io.io_check(PRER_LO, 32'hc8);
        io.io_check(PRER_HI, 32'h00);

        io.io_read(CR, value);
        $display("%t: io_read(CR) = %h", $time, value);
        io.io_read(SR, value);
        $display("%t: io_read(SR) = %h", $time, value);

        io.io_read(32'h100, value);
        $display("%t: io_read(0x100) = %h", $time, value);

        $finish;
    end

endmodule
