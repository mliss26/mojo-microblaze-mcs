/*
 * MicroBlaze MCS Global Counter IO Module
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

module gcnt_iom#(
    parameter COUNT_BITS = 56
    )(
    input clk,
    input rst,
    input io_addr_strobe,
    input io_read_strobe,
    input io_write_strobe, // unused
    input [11:0] io_address,
    input [3:0] io_byte_enable, // unused
    input [31:0] io_write_data, // unused
    output [31:0] io_read_data,
    output io_ready
    // TODO grey-coded output for consumption by other modules which need timestamps
    );

    reg [31:0] io_read_data_q;
    reg io_ready_q;

    wire [COUNT_BITS-1:0] count;

    assign io_read_data = io_read_data_q;
    assign io_ready = io_ready_q;

    counter #(.COUNT_BITS(COUNT_BITS)) global_counter (
        .clk(clk),
        .rst(rst),
        .count(count)
    );

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            io_read_data_q <= #1 32'b0;
            io_ready_q <= #1 1'b0;
        end else begin
            io_read_data_q <= #1 32'b0;
            io_ready_q <= #1 1'b0;

            if (io_addr_strobe) begin
                if (io_read_strobe) begin
                    case (io_address)
                        0: io_read_data_q <= #1 count[31:0];
                        4: io_read_data_q <= #1 count[COUNT_BITS-1:32];
                    endcase
                end
                // writes ignored
                io_ready_q <= #1 1'b1;
            end
        end
    end

endmodule
