/*
 * MicroBlaze IO bus address comparator testbench
 *
 * Copyright (c) 2022 Matt Liss
 * BSD-3-Clause
 */

`timescale 1ns/100ps

module iobus_address_compare_tb();

    localparam BASE_ADDRESS = 32'hc0000000;
    localparam ADDRESS_STRIDE = 32'h1000;
    localparam CORE_COUNT = 8;

    integer i, err_count = 0;

    reg addr_strobe;
    reg [31:0] address;
    wire [CORE_COUNT:0] strobe_out;

    iobus_address_compare#(
        .BASE_ADDRESS(BASE_ADDRESS),
        .ADDRESS_STRIDE(ADDRESS_STRIDE),
        .CORE_COUNT(CORE_COUNT)
    ) DUT (
        .addr_strobe(addr_strobe),
        .address({address[31:12],12'b0}),
        .strobe_out(strobe_out)
    );

    task strobe_check;
        input [CORE_COUNT:0] strobe_exp;
        begin
            if (strobe_out != strobe_exp) begin
                err_count = err_count + 1;
                $display("ERROR: address: 0x%h, strobe_out: 0x%h, strobe_expected: 0x%h",
                        address, strobe_out, strobe_exp);
            end
        end
    endtask

    // run tests
    initial begin
        $dumpfile("iobus_address_compare_tb.vcd");
        $dumpvars(0, iobus_address_compare_tb);

        addr_strobe = 1'b0;
        address = 32'h0;
        #10;
        strobe_check(0);

        for (i = 0; i < CORE_COUNT+1; i = i+1) begin: core_addr_loop
            address = (BASE_ADDRESS + ADDRESS_STRIDE*i);
            addr_strobe = 1'b1;
            #10;
            strobe_check(1<<i);
            address = 32'h0;
            addr_strobe = 1'b0;
            #10;
            strobe_check(0);
            address = (BASE_ADDRESS + ADDRESS_STRIDE*i + 4);
            addr_strobe = 1'b1;
            #10;
            strobe_check(1<<i);
            address = (BASE_ADDRESS + ADDRESS_STRIDE*i + 8);
            addr_strobe = 1'b1;
            #10;
            strobe_check(1<<i);
            address = (BASE_ADDRESS + ADDRESS_STRIDE*i + 32'hfff);
            addr_strobe = 1'b1;
            #10;
            strobe_check(1<<i);
        end

        $display("testbench finished with %d errors", err_count);
        $finish;
    end

endmodule
