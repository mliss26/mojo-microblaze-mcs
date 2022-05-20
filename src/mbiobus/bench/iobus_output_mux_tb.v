/*
 * MicroBlaze IO bus target output multiplexer testbench
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

`timescale 1ns/10ps

module iobus_output_mux_tb();

    localparam CORE_COUNT = 8;

    integer i, err_count = 0;

    reg [31+32*(CORE_COUNT-1):0] read_data_in;
    reg [CORE_COUNT-1:0] ready_in;
    wire [31:0] read_data_out;
    wire ready_out;

    iobus_output_mux#(
        .CORE_COUNT(CORE_COUNT)
    ) DUT (
        .read_data_in(read_data_in),
        .ready_in(ready_in),
        .read_data_out(read_data_out),
        .ready_out(ready_out)
    );

    // run tests
    initial begin
        $dumpfile("iobus_output_mux_tb.vcd");
        $dumpvars(0, iobus_output_mux_tb);

        // setup a unique input value from each target
        for (i = 0; i < CORE_COUNT; i = i+1)
            read_data_in[32*i +:32] = 32'hdeadd00d + 32'h5a5a5a5a*i;
        ready_in = {CORE_COUNT{1'b0}};
        #10;

        for (i = 0; i < CORE_COUNT; i = i+1) begin
            ready_in[i] = 1'b1;
            #10;
            if (ready_out != 1'b1) begin
                err_count = err_count + 1;
                $display("%t: ERROR: ready_out not set following ready_in[%d]", $time, i);
            end

            if (read_data_out != read_data_in[32*i +:32]) begin
                err_count = err_count + 1;
                $display("%t: ERROR: invalid read_data_out for input %d", $time, i);
            end else
                $display("%t: read_data_out valid for input %d", $time, i);

            ready_in[i] = 1'b0;
            #10;
            if (ready_out != 1'b0) begin
                err_count = err_count + 1;
                $display("%t: ERROR: ready_out not clear following ready_in[%d]", $time, i);
            end
        end

        $display("testbench finished with %d errors", err_count);
        $finish;
    end

endmodule
