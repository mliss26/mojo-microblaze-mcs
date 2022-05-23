/*
 * MicroBlaze IO bus wrapper for opencores wishbone I2C master core
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

module i2cm_iom(

    // uBlaze IO Bus signals
    input clk,
    input rst,
    input io_addr_strobe,
    input io_read_strobe,
    input io_write_strobe,
    input [11:0] io_address,
    input [3:0] io_byte_enable, // unused
    input [31:0] io_write_data,
    output [31:0] io_read_data,
    output io_ready,

    // interrupt signals
    output irq,

    // I2C signals
    inout scl,
    inout sda
    );

    // wishbone signals
    reg [2:0] wb_adr;
    reg [7:0] wb_dat_i;
    reg  wb_we;     // write enable input
    reg  wb_cyc;    // valid bus cycle input
    wire wb_ack;    // bus cycle acknowledge output

    // i2c clock line
    wire scl_pad_i;     // SCL-line input
    wire scl_pad_o;     // SCL-line output (always 1'b0)
    wire scl_padoen;    // SCL-line output enable (active low)

    assign scl = (scl_padoen ? 1'bz : scl_pad_o);
    assign scl_pad_i = scl;

    // i2c data line
    wire sda_pad_i;     // SDA-line input
    wire sda_pad_o;     // SDA-line output (always 1'b0)
    wire sda_padoen;    // SDA-line output enable (active low)

    assign sda = (sda_padoen ? 1'bz : sda_pad_o);
    assign sda_pad_i = sda;

    // wire up io bus signals
    reg io_ready_default;
    assign io_read_data[31:8] = 24'b0;
    assign io_ready = io_ready_default | wb_ack;

    // generate wishbone signals from iobus signals
    always @(posedge clk) begin
        io_ready_default <= #1 1'b0;

        if (rst) begin
            wb_adr <= #1 3'b0;
            wb_dat_i <= #1 8'b0;
            wb_we <= #1 1'b0;
            wb_cyc <= #1 1'b0;
        end else begin
            wb_adr <= #1 wb_adr;
            wb_dat_i <= #1 wb_dat_i;
            wb_we <= #1 wb_we;
            wb_cyc <= #1 wb_cyc;

            // start wb cycle for valid addresses or respond instead
            if (io_addr_strobe) begin
                if (io_address[11:5] == 7'b0) begin
                    wb_adr <= #1 io_address[4:2];
                    wb_dat_i <= #1 io_write_data[7:0];
                    wb_we <= #1 io_write_strobe;
                    wb_cyc <= #1 1'b1;
                end else begin
                    io_ready_default <= #1 1'b1;
                end
            end

            // end wb cycle when core responds
            if (wb_cyc & wb_ack) begin
                wb_adr <= #1 3'b0;
                wb_dat_i <= #1 8'b0;
                wb_we <= #1 1'b0;
                wb_cyc <= #1 1'b0;
            end
        end
    end

    // instatiate I2C master controller
    i2c_master_top i2c_top (

        // wishbone interface
        .wb_clk_i(clk),
        .wb_rst_i(1'b0),
        .arst_i(~rst),
        .wb_adr_i(wb_adr),
        .wb_dat_i(wb_dat_i),
        .wb_dat_o(io_read_data[7:0]),
        .wb_we_i(wb_we),
        .wb_stb_i(wb_cyc),
        .wb_cyc_i(wb_cyc),
        .wb_ack_o(wb_ack),
        .wb_inta_o(irq),

        // i2c signals
        .scl_pad_i(scl_pad_i),
        .scl_pad_o(scl_pad_o),
        .scl_padoen_o(scl_padoen),
        .sda_pad_i(sda_pad_i),
        .sda_pad_o(sda_pad_o),
        .sda_padoen_o(sda_padoen)
    );

endmodule
