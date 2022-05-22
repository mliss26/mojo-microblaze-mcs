/*
 * MicroBlaze SoC top level module testbench
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

`include "sdram.vh"

`timescale 1ns/100ps

module mb_soc_top_tb#(
    parameter GCNT_BITS = 56,
    parameter PDM_COUNT = 4,
    parameter IRQ_COUNT = 8
    ) ( );

    // Mojo board base connections
    // 50MHz clock input
    reg clk;
    // Input from reset button (active low)
    wire rst_n;
    // cclk input from AVR, high when AVR is ready
    reg cclk;
    // Outputs to the 8 onboard LEDs
    wire [7:0]led;
    // AVR SPI connections
    wire spi_miso;
    reg spi_ss;
    reg spi_mosi;
    reg spi_sck;
    // AVR ADC channel select
    wire [3:0] spi_channel;
    // Serial connections
    reg avr_tx; // AVR Tx => FPGA Rx
    wire avr_rx; // AVR Rx => FPGA Tx
    reg avr_rx_busy; // AVR Rx buffer full

    wire uart0_tx; // MicroBlaze TX
    reg  uart0_rx; // MicroBlaze RX

    wire [PDM_COUNT-1:0]pdm;

    // SDRAM connections
    `SDRAM_WIRE_DECLS;

    integer seed = 377;
    integer err_count = 0;

    mb_soc_top#(
        .GCNT_BITS(GCNT_BITS),
        .PDM_COUNT(PDM_COUNT),
        .IRQ_COUNT(IRQ_COUNT)
    ) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .cclk(cclk),
        .led(led),
        .spi_miso(spi_miso),
        .spi_ss(spi_ss),
        .spi_mosi(spi_mosi),
        .spi_sck(spi_sck),
        .spi_channel(spi_channel),
        .avr_tx(avr_tx),
        .avr_rx(avr_rx),
        .avr_rx_busy(avr_rx_busy),
        .uart0_tx(uart0_tx),
        .uart0_rx(uart0_rx),
        .pdm(pdm),
        .sdram_clk(sdram_clk),
        .sdram_cle(sdram_cle),
        .sdram_dqm(sdram_dqm),
        .sdram_cs(sdram_cs),
        .sdram_we(sdram_we),
        .sdram_cas(sdram_cas),
        .sdram_ras(sdram_ras),
        .sdram_ba(sdram_ba),
        .sdram_a(sdram_a),
        .sdram_dq(sdram_dq)
    );

    // bouncy reset button input
    btn_bounce#(
        .ACTIVE_STATE(1'b0)
    ) button (
        .btn(rst_n)
    );

    // external SDRAM
    mt48lc32m8a2 ram_model (
        .Dq(sdram_dq),
        .Addr(sdram_a),
        .Ba(sdram_ba),
        .Clk(sdram_clk),
        .Cke(sdram_cle),
        .Cs_n(sdram_cs),
        .Ras_n(sdram_ras),
        .Cas_n(sdram_cas),
        .We_n(sdram_we),
        .Dqm(sdram_dqm)
    );

    // generate input clock (50 MHz)
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    // run tests
    initial begin
        $dumpfile("mb_soc_top_tb.vcd");
        $dumpvars(2, mb_soc_top_tb);

        // generate reset button press
        #1e6;
        button.press(50e6, seed);

        // wait some time for SDRAM init
        #100000;
        @(posedge clk);

        repeat(16) @(posedge clk);
        $display("testbench completed with %d errors", err_count);
        $finish;
    end
endmodule
