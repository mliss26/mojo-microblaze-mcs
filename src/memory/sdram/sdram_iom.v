/*
 * MicroBlaze MCS IO module wrapper for Mojo v3 SDRAM controller
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

module sdram_iom(

    // uBlaze IO Bus signals
    input io_clk,
    input io_rst,
    input io_addr_strobe,
    input io_read_strobe,
    input io_write_strobe,
    input [24:0] io_address,
    input [3:0] io_byte_enable, // unused
    input [31:0] io_write_data,
    output [31:0] io_read_data,
    output reg io_ready,

    // SDRAM signals
    input mc_clk,
    input mc_rst,
    output sdram_clk,
    output sdram_cle,
    output sdram_cs,
    output sdram_cas,
    output sdram_ras,
    output sdram_we,
    output sdram_dqm,
    output [1:0] sdram_ba,
    output [12:0] sdram_a,
    inout [7:0] sdram_dq
    );

    localparam
        IDLE = 2'h0,
        WAIT_RW = 2'h1,
        WAIT_VALID = 2'h2;

    reg [1:0] state;

    // signals for IO => MC clock domain (slow to fast)
    reg [22:0] addr;
    reg rw;
    reg [31:0] data_in;
    reg in_valid_io;
    wire in_valid_mc;

    // signals for MC => IO clock domain (fast to slow)
    wire [31:0] data_out_mc;
    wire out_valid_mc;
    wire busy;

    // signals for output of async hanshake
    wire out_valid_io;

    sdram sdram (
        .clk(mc_clk),
        .rst(mc_rst),

        // SDRAM IOs
        .sdram_clk(sdram_clk),
        .sdram_cle(sdram_cle),
        .sdram_cs(sdram_cs),
        .sdram_cas(sdram_cas),
        .sdram_ras(sdram_ras),
        .sdram_we(sdram_we),
        .sdram_dqm(sdram_dqm),
        .sdram_ba(sdram_ba),
        .sdram_a(sdram_a),
        .sdram_dq(sdram_dq),

        // user interface
        .addr(addr),
        .rw(rw),
        .data_in(data_in),
        .in_valid(in_valid_mc),
        .data_out(data_out_mc),
        .out_valid(out_valid_mc),
        .busy(busy)
    );

    // handshake to cross MC to IO clock boundary
    async_handshake #(
        .DATA_W(32)
    ) mc_io_cbc (
        .rst_src(mc_rst),
        .clk_src(mc_clk),
        .data_src(data_out_mc),
        .valid_src(out_valid_mc),
        .ready_src(in_valid_mc),
        .rst_dst(io_rst),
        .clk_dst(io_clk),
        .data_dst(io_read_data),
        .valid_dst(out_valid_io),
        .ready_dst(in_valid_io)
    );

    // io clock domain
    always @(posedge io_clk) begin
        if (io_rst) begin
            state <= #1 IDLE;
            addr <= #1 23'b0;
            rw <= #1 1'b0;
            data_in <= #1 32'b0;
            in_valid_io <= #1 1'b0;
            io_ready <= #1 1'b0;
        end else begin
            state <= state;
            addr <= addr;
            rw <= rw;
            data_in <= data_in;
            in_valid_io <= in_valid_io;
            io_ready <= io_ready;

            case (state)
                IDLE: begin
                    io_ready <= #1 1'b0;

                    if (io_addr_strobe) begin
                        addr <= #1 io_address[24:2];
                        rw <= #1 io_write_strobe;
                        data_in <= #1 io_write_data;

                        if (busy) begin
                            state <= #1 WAIT_RW;
                        end else begin
                            in_valid_io <= #1 1'b1;
                            state <= #1 WAIT_VALID;
                        end
                    end
                end

                WAIT_RW: begin
                    if (!busy) begin
                        in_valid_io <= #1 1'b1;
                        state <= #1 WAIT_VALID;
                    end
                end

                WAIT_VALID: begin
                    in_valid_io <= #1 1'b0;

                    if (rw) begin   // WRITE
                        io_ready <= #1 1'b1;
                        state <= #1 IDLE;
                    end else begin  // READ
                        if (out_valid_io) begin
                            io_ready <= #1 1'b1;
                            state <= #1 IDLE;
                        end
                    end
                end

                default: state <= #1 IDLE;
            endcase
        end
    end

endmodule
