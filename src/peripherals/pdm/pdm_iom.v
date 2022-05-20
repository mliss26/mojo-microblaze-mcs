/*
 * MicroBlaze MCS PDM IO Module
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

module pdm_iom#(
    parameter DUTY_BITS = 8,
    parameter PDM_COUNT = 2
    )(
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
    output [PDM_COUNT-1:0] pdm
    );

    genvar i;
    integer j;

    reg io_ready_q;
    reg [DUTY_BITS-1:0] io_read_data_q;
    reg [PDM_COUNT-1:0] pdm_en;

    reg [DUTY_BITS-1:0] pdm_duty [0:PDM_COUNT-1];

    assign io_read_data = {{(32-DUTY_BITS){1'b0}},io_read_data_q};
    assign io_ready = io_ready_q;

    generate
        for(i = 0; i < PDM_COUNT; i = i+1) begin: gen_pdm_loop
            pdm #(.DUTY_BITS(DUTY_BITS)) pdm_inst (
                .clk(clk),
                .rst(rst),
                .en(pdm_en[i]),
                .duty(pdm_duty[i]),
                .pdm(pdm[i])
            );
        end
    endgenerate

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            pdm_en <= {PDM_COUNT{1'b0}};
            for(j = 0; j < PDM_COUNT; j = j+1)
                pdm_duty[j] <= 8'b0;
            io_read_data_q <= {DUTY_BITS{1'b0}};
            io_ready_q <= 1'b0;
        end else begin
            io_read_data_q <= {DUTY_BITS{1'b0}};
            io_ready_q <= 1'b0;

            if (io_addr_strobe) begin
                if (io_address == 0) begin
                    if (io_read_strobe)
                        io_read_data_q <= {{DUTY_BITS-PDM_COUNT{1'b0}},pdm_en};
                    else if (io_write_strobe)
                        pdm_en <= io_write_data[PDM_COUNT-1:0];
                end
                for(j = 0; j < PDM_COUNT; j = j+1) begin: gen_addr_loop
                    if (io_address == 4*(j+1)) begin
                        if (io_read_strobe)
                            io_read_data_q <= pdm_duty[j];
                        else if (io_write_strobe)
                            pdm_duty[j] <= io_write_data[7:0];
                    end
                end
                io_ready_q <= 1'b1;
            end
        end
    end

endmodule
