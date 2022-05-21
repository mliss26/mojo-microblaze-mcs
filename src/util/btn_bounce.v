/*
 * Bouncy Button signal for testbenches
 *
 * Copyright (C) 2022 Matt Liss
 * BSD-3-Clause
 */

module btn_bounce#(
    parameter ACTIVE_STATE = 1'b1
    ) (
    output reg btn
    );

    integer i, j, oscillations, delay;

    initial begin
        btn = ~ACTIVE_STATE;
    end

    task press;
        input integer duration;
        input integer seed;
        begin
            // two bouncy toggles for a press
            for (j = 0; j < 2; j += 1) begin

                // get an odd random number of oscillations so button will toggle
                oscillations = ($urandom(seed) % 7) + 5;
                if ((oscillations & 1) == 0)
                    oscillations |= 1;
                $display("btn_bounce: oscillations = %d", oscillations);

                // bounce
                for (i = 0; i < oscillations; i += 1) begin
                    btn = ~btn;
                    delay = ($urandom(seed) % 1e6) + 1e3;
                    $display("btn_bounce: osc delay = %d", delay);
                    #delay;
                end

                // settle for specified duration
                if (j == 0) begin
                    $display("btn_bounce: stable duration = %d", duration);
                    #duration;
                end
            end
        end
    endtask

endmodule
