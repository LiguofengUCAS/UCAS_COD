`timescale 1ns / 1ns

`define DATA_WIDTH 32
`define ADDR_WIDTH 5

module reg_file_test
();

	reg clk;
	reg rst;
	reg [`ADDR_WIDTH - 1:0] waddr;
	reg wen;
	reg [`DATA_WIDTH - 1:0] wdata;

	reg [`ADDR_WIDTH - 1:0] raddr1;
	reg [`ADDR_WIDTH - 1:0] raddr2;
	wire [`DATA_WIDTH - 1:0] rdata1;
	wire [`DATA_WIDTH - 1:0] rdata2;

	initial begin
		clk=0;
		rst=0;
		wen=1;
		raddr1=0;
		raddr2=0;
		waddr=0;
		wdata=0;

		#30 raddr1=5'b00000;
			raddr2=5'b00001;
			waddr=5'b00000;
			wdata=32'b00000000000000000000000000000000;

		#30 raddr1=5'b00010;
			raddr2=5'b00011;
			waddr=5'b00011;
			wdata=32'b00000000001100000000000000000000;

		#30	raddr1=5'b10110;
			raddr2=5'b00110;
			waddr=5'b10110;
			wdata=32'b00000000000011010000000000000000;
	end

	always begin
		#5 clk = ~clk;
	end

	always begin
		#15 rst=~rst;
	end

	reg_file Reg_File(
		.clk(clk),
		.rst(rst),
		.waddr(waddr),
		.raddr1(raddr1),
		.raddr2(raddr2),
		.wen(wen),
		.wdata(wdata),
		.rdata1(rdata1),
		.rdata2(rdata2)
	);

endmodule
