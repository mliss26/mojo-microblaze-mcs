/*
 * MicroBlaze MCS PRNG IO Module
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

`define PRNG_SEED_OFFS          0
`define PRNG_RAND_OFFS          4

module prng_iom(
    input clk,
    input rst,
    input io_addr_strobe,
    input io_read_strobe,
    input io_write_strobe,
    input [11:0] io_address,
    input [3:0] io_byte_enable, // unused
    input [31:0] io_write_data,
    output reg [31:0] io_read_data,
    output reg io_ready
    );

    reg next, prng_rst;
    reg  [31:0] seed;
    wire [31:0] rand;

    prng prng (
        .clk(clk),
        .rst(prng_rst),
        .next(next),
        .seed(seed),
        .num(rand)
    );

    always @(posedge clk) begin
        next <= #1 1'b0;
        io_ready <= #1 1'b0;

        if (rst) begin
            seed <= #1 32'b0;
            prng_rst <= #1 1'b1;
            io_read_data <= #1 32'b0;
        end else begin
            seed <= seed;
            io_read_data <= io_read_data;
            prng_rst <= #1 1'b0;

            if (io_addr_strobe) begin
                case (io_address)
                    `PRNG_SEED_OFFS: begin
                        if (io_read_strobe) begin
                            io_read_data <= #1 seed;
                        end else begin
                            seed <= #1 io_write_data;
                            prng_rst <= #1 1'b1;
                        end
                    end
                    `PRNG_RAND_OFFS: begin
                        if (io_read_strobe) begin
                            io_read_data <= #1 rand;
                            next <= #1 1'b1;
                        end
                    end
                endcase
                io_ready <= #1 1'b1;
            end
        end
    end

endmodule
