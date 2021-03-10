`timescale 1ns / 1ps

`define STATE_RESET 8'd0
`define STATE_RUN   8'd1
`define STATE_HALT  8'd2

module counter(
    input         clk  ,
    input  [31:0] inter,
    input  [ 7:0] state,
    output [31:0] count
);

    reg [31:0] clk_cnt;
    reg [31:0] int_cnt;

    always@(posedge clk) begin
        if(state == `STATE_RESET)
            clk_cnt <= 32'b0;

        else if(state == `STATE_RUN) begin
            if(clk_cnt == inter)
                clk_cnt <= 32'b0;
            else
                clk_cnt <= clk_cnt + 1;
        end
            
        else if(state == `STATE_HALT)
            clk_cnt <= clk_cnt;
        
    end

    always@(posedge clk) begin
        if(state == `STATE_RESET)
            int_cnt <= 32'b0;

        else if(state == `STATE_RUN)
            if(clk_cnt == inter)
                int_cnt <= int_cnt + 1;

        else if(state == `STATE_HALT)
            int_cnt <= int_cnt;   
    end

endmodule