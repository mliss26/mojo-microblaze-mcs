/*
 * Pulse Density Modulation
 *
 * Description:
 *  This module implements a pulse density modulation output signal whose duty
 *  cycle is dependent on an adjustable width input.
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

module pdm#(parameter DUTY_BITS = 8) (
    input clk,
    input rst,
    input en,
    input [DUTY_BITS-1:0] duty,
    output pdm
    );

    reg pdm_d, pdm_q;
    reg [DUTY_BITS:0] accumulator_d, accumulator_q;

    // output synchronous to clk
    assign pdm = pdm_q;

    // combinational feedback circuit
    always @(accumulator_q, duty, en) begin
        if (en) begin
            if (accumulator_q >= {DUTY_BITS{1'b1}}) begin
                accumulator_d = accumulator_q - {DUTY_BITS{1'b1}} + duty;
                pdm_d = 1'b1;
            end else begin
                accumulator_d = accumulator_q + duty;
                pdm_d = 1'b0;
            end
        end else begin
            accumulator_d = accumulator_q;
            pdm_d = 1'b0;
        end
    end

    // sequential circuit with async reset
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            accumulator_q <= {(DUTY_BITS+1){1'b0}};
            pdm_q <= 1'b0;
        end else begin
            accumulator_q <= accumulator_d;
            pdm_q <= pdm_d;
        end
    end

endmodule
