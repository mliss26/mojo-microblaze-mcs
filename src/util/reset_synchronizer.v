/*
 * Simple reset synchronizer
 *
 * Copyright (C) 2022 Matt Liss
 * BSD-3-Clause
 */

module reset_synchronizer #(
    parameter DELAY = 4
    ) (
    input clk,
    input rst_in,
    output rst_out
    );

    wire [DELAY-1:0] d;
    reg  [DELAY-1:0] q = {DELAY{1'b1}};

    assign rst_out = q[DELAY-1];

    assign d = {q[DELAY-2:0], 1'b0};

    always @(posedge clk)
        if (rst_in)
            q <= #1 {DELAY{1'b1}};
        else
            q <= #1 d;

endmodule
