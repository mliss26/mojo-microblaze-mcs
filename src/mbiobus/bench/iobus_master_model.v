/*
 * MicroBlaze IO bus master module for test benches
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

module iobus_master_model(
    input  clk,
    input  rst,
    output reg io_addr_strobe,
    output reg io_read_strobe,
    output reg io_write_strobe,
    output reg [3:0] io_byte_en,
    output reg [31:0] io_addr,
    output reg [31:0] io_write_data,
    input  [31:0] io_read_data,
    input  io_ready
    );

    // local data value for checking
    reg [31:0] tmp;

    initial begin
        io_addr = 32'b0;
        io_addr_strobe = 1'b0;
        io_read_strobe = 1'b0;
        io_write_strobe = 1'b0;
        io_byte_en = 3'b0;
        io_write_data = 32'b0;
    end

    task io_read;
        input  [31:0] addr;
        output [31:0] data;
        begin
            // assert io signals
            #1;
            io_addr = addr;
            io_addr_strobe = 1'b1;
            io_read_strobe = 1'b1;
            io_write_strobe = 1'b0;
            io_byte_en = 4'b1111;
            io_write_data = 32'b0;

            // deassert io signals
            @(posedge clk);
            #1;
            io_addr = 32'b0;
            io_addr_strobe = 1'b0;
            io_read_strobe = 1'b0;
            io_write_strobe = 1'b0;
            io_byte_en = 4'b0;
            io_write_data = 32'b0;

            // wait for ack
            while (~io_ready) @(posedge clk);

            // get read data
            #1;
            data = io_read_data;
        end
    endtask

    task io_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            // assert io signals
            #1;
            io_addr = addr;
            io_addr_strobe = 1'b1;
            io_read_strobe = 1'b0;
            io_write_strobe = 1'b1;
            io_byte_en = 4'b1111;
            io_write_data = data;

            // deassert io signals
            @(posedge clk);
            #1;
            io_addr = 32'b0;
            io_addr_strobe = 1'b0;
            io_read_strobe = 1'b0;
            io_write_strobe = 1'b0;
            io_byte_en = 4'b0;
            io_write_data = 32'b0;

            // wait for ack
            while (~io_ready) @(posedge clk);
        end
    endtask

    task io_check;
        input [31:0] addr;
        input [31:0] exp_data;
        begin
            io_read(addr, tmp);
            if (tmp != exp_data)
                $display("%t: io_check failure, expected %h, got %h", $time, exp_data, tmp);
        end
    endtask

endmodule
