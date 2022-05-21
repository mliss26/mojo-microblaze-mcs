/*
 * Button debouncer
 *
 * Copyright (C) 2022 Matt Liss
 * BSD-3-Clause
 */

module debounce#(
	parameter CTR_BITS = 19
	) (
	input clk,
	input btn,
	output out
	);

	reg [CTR_BITS-1:0] ctr_d, ctr_q;
	reg [1:0] sync_d, sync_q;

	assign out = ctr_q == {CTR_BITS{1'b1}};

	always @(*) begin
		sync_d = {sync_q[0], btn};
		ctr_d = ctr_q + 1'b1;

		if (ctr_q == {CTR_BITS{1'b1}})
			ctr_d = ctr_q;

		if (~sync_q[1])
			ctr_d = {CTR_BITS{1'b0}};
	end

	always @(posedge clk) begin
		ctr_q <= ctr_d;
		sync_q <= sync_d;
	end

endmodule
