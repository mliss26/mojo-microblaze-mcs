/*
 * MicroBlaze IO bus default responder
 *
 * Provides a default response on the IO bus when no target is
 * addressed to prevent a bus hang.
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

module iobus_default_response#(
    parameter DEFAULT_VALUE = 32'hffffffff
    ) (
    input io_addr_strobe,
    output [31:0] io_read_data,
    output io_ready
    );

    assign io_read_data = DEFAULT_VALUE;
    assign io_ready = io_addr_strobe;

endmodule
