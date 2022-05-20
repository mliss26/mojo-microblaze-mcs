/*
 * PRNG IO Module testbench
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

`define PRNG_SEED_OFFS          0
`define PRNG_RAND_OFFS          4

`timescale 1ns/10ps

module prng_iom_tb();

    reg clk, rst;

    wire io_addr_strobe, io_read_strobe, io_write_strobe;
    wire [3:0] io_byte_en;
    wire [31:0] io_addr, io_write_data;
    wire [31:0] io_read_data;
    wire io_ready;

    reg [31:0] value;

    // instantiate DUT
    prng_iom DUT (
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

    // generate reset and clock
    initial begin
        clk = 1'b0;
        rst = 1'b1;
        repeat(2) #10 clk = ~clk;
        rst = 1'b0;
        forever #10 clk = ~clk;
    end

    task read_rand;
        input integer count;
        begin: read_rand_block
            integer i;

            io.io_read(`PRNG_SEED_OFFS, value);
            $display("%t: seed = %h", $time, value);

            for (i = 0; i < count; i = i+1) begin
                io.io_read(`PRNG_RAND_OFFS, value);
                $display("%t: rand = %h", $time, value);
            end
        end
    endtask

    // run tests
    initial begin
        $dumpfile("prng_iom_tb.vcd");
        $dumpvars(0, prng_iom_tb);

        value = 32'b0;
        @(negedge rst);
        @(posedge clk);

        read_rand(4);

        io.io_write(`PRNG_SEED_OFFS, 32'b0);
        read_rand(4);

        io.io_write(`PRNG_SEED_OFFS, 32'hdeadbeef);
        read_rand(4);

        io.io_write(`PRNG_SEED_OFFS, 32'hdeadbeef);
        read_rand(4);

        $finish;
    end

endmodule
