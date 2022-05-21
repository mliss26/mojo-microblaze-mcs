/*
 * MicroBlaze SoC top level module
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

module mb_soc_top#(
    parameter GCNT_BITS = 56,
    parameter PDM_COUNT = 4,
    parameter IRQ_COUNT = 8
    ) (
    // Mojo board base connections
    // 50MHz clock input
    input clk,
    // Input from reset button (active low)
    input rst_n,
    // cclk input from AVR, high when AVR is ready
    input cclk,
    // Outputs to the 8 onboard LEDs
    output[7:0]led,
    // AVR SPI connections
    output spi_miso,
    input spi_ss,
    input spi_mosi,
    input spi_sck,
    // AVR ADC channel select
    output [3:0] spi_channel,
    // Serial connections
    input avr_tx, // AVR Tx => FPGA Rx
    output avr_rx, // AVR Rx => FPGA Tx
    input avr_rx_busy, // AVR Rx buffer full


    output uart0_tx, // MicroBlaze TX
    input  uart0_rx, // MicroBlaze RX

    output [PDM_COUNT-1:0]pdm,

    // SDRAM connections
    output sdram_clk,
    output sdram_cle,
    output sdram_dqm,
    output sdram_cs,
    output sdram_we,
    output sdram_cas,
    output sdram_ras,
    output [1:0] sdram_ba,
    output [12:0] sdram_a,
    inout [7:0] sdram_dq
    );

    // these signals should be high-z when not used
    assign spi_miso = 1'bz;
    assign avr_rx = 1'bz;
    assign spi_channel = 4'bzzzz;

    // io bus wires
    wire io_addr_strobe, io_read_strobe, io_write_strobe, io_ready;
    wire [31:0] io_address, io_write_data, io_read_data;
    wire [3:0] io_byte_enable;

    // interrupts
    wire [IRQ_COUNT-1:0] irq;

    // clock and reset handling
    wire lock, cpu_clk, mc_clk;

    mbsoc_clk_gen cc (
        .lock(lock),
        .clk_in(clk),
        .cpu_clk(cpu_clk),
        .sdram_clk(mc_clk)
    );
    /* for testing at 50 MHz
    assign cpu_clk = clk;
    assign mc_clk = clk;
    */

    // make reset active high and synchronize to clocks
    wire rst, cpu_rst, mc_rst;

    assign rst = ~rst_n | ~lock;

    reset_synchronizer#(.DELAY(8)) cpu_rst_sync (
        .clk(cpu_clk),
        .rst_in(rst),
        .rst_out(cpu_rst)
    );

    reset_synchronizer#(.DELAY(8)) mc_rst_sync (
        .clk(mc_clk),
        .rst_in(rst),
        .rst_out(mc_rst)
    );

    // io bus multiplexer with all peripherals
    iobus_top#(
        .GCNT_BITS(GCNT_BITS),
        .PDM_COUNT(PDM_COUNT)
    ) iom (
        // io bus signals
        .io_clk(cpu_clk),
        .io_rst(cpu_rst),
        .io_addr_strobe(io_addr_strobe),
        .io_read_strobe(io_read_strobe),
        .io_write_strobe(io_write_strobe),
        .io_address(io_address),
        .io_byte_enable(io_byte_enable),
        .io_write_data(io_write_data),
        .io_read_data(io_read_data),
        .io_ready(io_ready),

        // SDRAM signals
        .mc_clk(mc_clk),
        .mc_rst(mc_rst),
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

        // external interrupt signals
        .irq(irq),

        // dedicated PDM outputs
        .pdm(pdm)
    );

    // cpu/mem subsystem
    microblaze_mcs_v1_4 mcs_0 (
        // io bus signals
        .Clk(cpu_clk), // input Clk
        .Reset(cpu_rst), // input Reset
        .IO_Addr_Strobe(io_addr_strobe), // output IO_Addr_Strobe
        .IO_Read_Strobe(io_read_strobe), // output IO_Read_Strobe
        .IO_Write_Strobe(io_write_strobe), // output IO_Write_Strobe
        .IO_Address(io_address), // output [31 : 0] IO_Address
        .IO_Byte_Enable(io_byte_enable), // output [3 : 0] IO_Byte_Enable
        .IO_Write_Data(io_write_data), // output [31 : 0] IO_Write_Data
        .IO_Read_Data(io_read_data), // input [31 : 0] IO_Read_Data
        .IO_Ready(io_ready), // input IO_Ready

        // UART signals
        .UART_Rx(uart0_rx), // input UART_Rx
        .UART_Tx(uart0_tx), // output UART_Tx
        .UART_Interrupt(), // output UART_Interrupt

        // timer signals
        .FIT1_Interrupt(), // output FIT1_Interrupt
        .FIT1_Toggle(), // output FIT1_Toggle
        .PIT1_Enable(1'b0), // input PIT1_Enable
        .PIT1_Interrupt(), // output PIT1_Interrupt
        .PIT1_Toggle(), // output PIT1_Toggle
        .PIT2_Enable(1'b0), // input PIT2_Enable
        .PIT2_Interrupt(), // output PIT2_Interrupt
        .PIT2_Toggle(), // output PIT2_Toggle
        .PIT3_Interrupt(), // output PIT3_Interrupt
        .PIT3_Toggle(), // output PIT3_Toggle
        .PIT4_Interrupt(), // output PIT4_Interrupt
        .PIT4_Toggle(), // output PIT4_Toggle

        // GPIO signals
        .GPO1(), // output [31 : 0] GPO1
        .GPO2(led), // output [7 : 0] GPO2
        .GPI1(32'd0), // input [31 : 0] GPI1
        .GPI1_Interrupt(), // output GPI1_Interrupt

        // external interrupt signals
        .INTC_Interrupt(irq), // input [7 : 0] INTC_Interrupt
        .INTC_IRQ() // output INTC_IRQ
    );

endmodule
