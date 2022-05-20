/*
 * MicroBlaze IO bus target output multiplexer
 *
 * This module multiplexes the outputs from all IO bus targets back to
 * the bus initiator.
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

module iobus_output_mux#(
    parameter CORE_COUNT = 2
    ) (
    input [31+32*(CORE_COUNT-1):0] read_data_in,
    input [CORE_COUNT-1:0] ready_in,
    output reg [31:0] read_data_out,
    output reg ready_out
    );

    integer i;

    always @(*) begin
        read_data_out = 32'h0;
        ready_out = 1'b0;

        for (i = 0; i < CORE_COUNT; i = i+1) begin
            if (ready_in[i]) begin
                read_data_out = read_data_in[32*i +: 32];
                ready_out = ready_in[i];
            end
        end
    end

endmodule
