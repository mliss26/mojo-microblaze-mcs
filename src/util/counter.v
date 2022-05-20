/*
 * Simple binary counter
 *
 * Copyright (C) 2022 Matt Liss
 * BSD-3-Clause
 */

module counter #(
    parameter COUNT_BITS = 8,
    parameter HIDDEN_BITS = 0
    ) (
    input clk,
    input rst,
    output [COUNT_BITS-1:0] count
    );

    reg [COUNT_BITS+HIDDEN_BITS-1:0] count_d, count_q;

    assign count = count_q[COUNT_BITS+HIDDEN_BITS-1:HIDDEN_BITS];

    always @(count_q)
        count_d = count_q + 1'b1;

    always @(posedge clk)
        if (rst)
            count_q <= #1 1'b0;
        else
            count_q <= #1 count_d;

endmodule
