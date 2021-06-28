`timescale 10 ns / 1 ns

`define DATA_WIDTH 32
`define ADDR_WIDTH 5
`define NUM        32

module reg_file(
    input                      clk,
    input                      rst,
    input  [`ADDR_WIDTH - 1:0] waddr,
    input  [`ADDR_WIDTH - 1:0] raddr1,
    input  [`ADDR_WIDTH - 1:0] raddr2,
    input                      wen,
    input  [`DATA_WIDTH - 1:0] wdata,
    output [`DATA_WIDTH - 1:0] rdata1,
    output [`DATA_WIDTH - 1:0] rdata2
);
    
    // No rst & No init
    reg [`DATA_WIDTH - 1:0] REG_Files [0:`NUM - 1];
	
    always@(posedge clk)
    begin
        if(wen && waddr)
            REG_Files[waddr] <= wdata;
    end

    assign rdata1 = {32{raddr1 != 5'b0}} & REG_Files[raddr1];

    assign rdata2 = {32{raddr2 != 5'b0}} & REG_Files[raddr2];

endmodule
