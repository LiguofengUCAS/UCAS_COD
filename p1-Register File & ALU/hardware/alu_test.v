`timescale 10ns / 1ns

`define DATA_WIDTH 32

module alu_test
();

	reg [`DATA_WIDTH - 1:0] A;
	reg [`DATA_WIDTH - 1:0] B;
	reg [2:0] ALUop;
	wire Overflow;
	wire CarryOut;
	wire Zero;
	wire [`DATA_WIDTH - 1:0] Result;

	initial
	begin
		ALUop=3'b000;A=32'h0000_0000;B=32'h0000_0001;#50;
		ALUop=3'b000;A=32'h0000_0001;B=32'h0000_0001;#50;

		ALUop=3'b001;A=32'h0000_0000;B=32'h0000_0001;#50;
		ALUop=3'b001;A=32'h0000_0000;B=32'h0000_0000;#50;

		ALUop=3'b010;A=32'h7FFF_FFFF;B=32'h7FFF_FFFF;#50;
		ALUop=3'b010;A=32'hFFFF_FFFF;B=32'hFFFF_FFFF;#50;

		ALUop=3'b110;A=32'h7FFF_FFFF;B=32'h7FFF_FFFD;#50;
		ALUop=3'b110;A=32'h7FFF_FFFF;B=32'hFFFF_FFFF;#50;

		ALUop=3'b111;A=32'h0000_0000;B=32'h0000_0001;#50;
		ALUop=3'b111;A=32'hFFFF_FFFF;B=32'h7FFF_FFFF;#50;
	end

	alu u_alu(
		.A(A),
		.B(B),
		.ALUop(ALUop),
		.Overflow(Overflow),
		.CarryOut(CarryOut),
		.Zero(Zero),
		.Result(Result)
	);

endmodule

