/*
 * MicroBlaze IO bus address comparator
 *
 * The IO bus mux uses split-level address decoding. This module implements
 * the bus mux portion of the decoding, activating a single strobe output
 * to a downstream bus target and passing the lower address bits on.
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

module iobus_address_compare#(
    parameter BASE_ADDRESS = 32'hc0000000,
    parameter ADDRESS_STRIDE = 32'h1000,
    parameter CORE_COUNT = 2
    ) (
    input addr_strobe,
    input [31:0] address,
    output [CORE_COUNT:0] strobe_out
    );

    reg [CORE_COUNT-1:0] core_strobe;
    integer i;

    // individual target core strobes
    assign strobe_out[CORE_COUNT-1:0] = core_strobe;

    // default responder strobe when no core is addressed
    assign strobe_out[CORE_COUNT] = ~(|core_strobe) & ~(&address[31:29]) & addr_strobe;

    always @(*) begin
        core_strobe = {CORE_COUNT{1'b0}};
        for (i = 0; i < CORE_COUNT; i = i+1)
            if (address == (BASE_ADDRESS + ADDRESS_STRIDE*i))
                core_strobe[i] = addr_strobe;
    end

endmodule
