`timescale 1ns / 1ps

`define STATE_RESET 8'd0
`define STATE_RUN 8'd1
`define STATE_HALT 8'd2

module counter_test
();

	reg			clk;
    reg  [7:0]		state;
    reg [31:0]		inter;

    wire [31:0]     counter;

	counter count32(
				.interval(inter),
				.state(state),
				.counter(counter),
				.clk(clk));

	always #10 clk=~clk;

	initial
	begin
		clk = 0;
		state=`STATE_RESET;
		#200 state=`STATE_RUN;
		#500 state=`STATE_HALT;
    end
	
	initial
	begin
		inter=8'd5;
	end


endmodule
