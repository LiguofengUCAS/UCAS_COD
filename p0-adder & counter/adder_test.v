`timescale 1ns / 1ps

module adder_test;

	reg	[7:0]			x,y;
	reg clk;

    wire [7:0]          sum;

	adder add_8(.operand0(x),
		        .operand1(y),
				.result(sum));

	initial
	begin
		x = 0;
		y = 0;
		clk=0;
	end

	always #10 clk=~clk;
	always@(posedge clk)
	begin
		x={$random}%256;
		y={$random}%256;
	end

endmodule
