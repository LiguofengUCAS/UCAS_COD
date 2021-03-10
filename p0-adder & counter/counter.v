`timescale 1ns / 1ps

`define STATE_RESET 8'd0
`define STATE_RUN   8'd1
`define STATE_HALT  8'd2

module counter(
    input             clk     ,
    input      [31:0] interval,
    input      [ 7:0] state   ,
    output reg [31:0] counter
);

    reg [31:0] clk_cnt;

    always@(posedge clk) begin
        if(state == `STATE_RESET)
            clk_cnt <= 32'b0;

        else if(state == `STATE_RUN) begin
            if(clk_cnt == interval)
                clk_cnt <= 32'b1;
            else
                clk_cnt <= clk_cnt + 1;
        end
            
        else if(state == `STATE_HALT)
            clk_cnt <= clk_cnt;
        
    end

    always@(posedge clk) begin
        if(state == `STATE_RESET)
            counter <= 32'b0;

        else if(state == `STATE_RUN)
            if(clk_cnt == interval)
                counter <= counter + 1;

        else if(state == `STATE_HALT)
            counter <= counter;   
    end

endmodule
