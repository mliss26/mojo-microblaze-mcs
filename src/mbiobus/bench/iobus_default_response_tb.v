/*
 * MicroBlaze IO bus default responder testbench
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

`timescale 1ns/10ps

module iobus_default_response_tb();

    reg io_addr_strobe;
    wire [31:0] io_read_data;
    wire io_ready;

    integer err_count = 0;

    iobus_default_response DUT (
        .io_addr_strobe(io_addr_strobe),
        .io_read_data(io_read_data),
        .io_ready(io_ready)
    );

    task resp_check;
        begin
            if (io_read_data != 32'hffffffff) begin
                err_count = err_count + 1;
                $display("ERROR: io_read_data = 0x%h", io_read_data);
            end
            if (io_ready != io_addr_strobe) begin
                err_count = err_count + 1;
                $display("ERROR: io_ready = %d", io_ready);
            end
        end
    endtask

    initial begin
        $dumpfile("iobus_default_response_tb.vcd");
        $dumpvars(0, iobus_default_response_tb);

        io_addr_strobe = 1'b0;
        #10;
        resp_check();

        io_addr_strobe = 1'b1;
        #10;
        resp_check();

        io_addr_strobe = 1'b0;
        #10;
        resp_check();

        $display("testbench finished with %d errors", err_count);
        $finish;
    end

endmodule
