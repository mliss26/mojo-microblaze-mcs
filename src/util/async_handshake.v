/*
 * Async handshake signals for clock boundry crossings
 *
 * Based on EE5375 Async Presentation by Eric MacDonald
 *
 * Copyright (C) 2022 Matt Liss
 * BSD-3-Clause
 */

`timescale 1ns/10ps

module async_handshake #(
    parameter   DATA_W = 8
    ) (
    input               rst_src,
    input               clk_src,
    input [DATA_W-1:0]  data_src,
    input               valid_src,
    output reg          ready_src,
    input               rst_dst,
    input               clk_dst,
    output [DATA_W-1:0] data_dst,
    output reg          valid_dst,
    input               ready_dst
    );

    localparam SYNC_W = 5;

    reg [SYNC_W-1:0] valid = {SYNC_W{1'b0}}; // chain of valid ffs (src => dest)
    reg [SYNC_W-1:0] ready = {SYNC_W{1'b0}}; // chain of ready ffs (src <= dest)

    reg [DATA_W-1:0] data_src_r = {DATA_W{1'b0}};
    reg [DATA_W-1:0] data_dst_r = {DATA_W{1'b0}};

    assign data_dst = data_dst_r;

    // source clock domain valid signal
    always @(*)
        valid[0] = valid_src ? ~valid[1] : valid[1];

    always @(posedge clk_src)
        if (rst_src) begin
            data_src_r <= {DATA_W{1'b0}};
            valid[1] <= 1'b0;
        end else begin
            data_src_r <= #1 data_src;
            valid[1] <= #1 valid[0];
        end

    // destination clock domain valid signal
    always @(posedge clk_dst)
        if (rst_dst)
            valid[SYNC_W-1:2] <= {(SYNC_W-3){1'b0}};
        else
            valid[SYNC_W-1:2] <= #1 valid[SYNC_W-2:1];

    always @(*)
        valid_dst = valid[SYNC_W-1] ^ valid[SYNC_W-2];

    // destination clock domain ready signal
    always @(*)
        ready[0] = ready_dst ? ~ready[1] : ready[1];

    always @(posedge clk_dst)
        if (rst_dst) begin
            data_dst_r <= {DATA_W{1'b0}};
            ready[1] <= 1'b0;
        end else begin
            data_dst_r <= #1 valid_dst ? data_src_r : data_dst_r;
            ready[1] <= #1 ready[0];
        end

    // source clock domain ready signal
    always @(posedge clk_src)
        if (rst_src)
            ready[SYNC_W-1:2] <= {(SYNC_W-3){1'b0}};
        else
            ready[SYNC_W-1:2] <= #1 ready[SYNC_W-2:1];

    always @(*)
        ready_src = ready[SYNC_W-1] ^ ready[SYNC_W-2];

endmodule
