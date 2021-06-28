`include "parameter.v"

module predictor(
    input clk,
    input rst,

    input cancle,

    output prdct_br_go
);

    reg [4:0] prdct_current_state;
    reg [4:0] prdct_next_state;

    always@(posedge clk) begin
        if(rst)
            prdct_current_state <= `INIT;
        else
            prdct_current_state <= prdct_next_state;
    end

    always@(*) begin
        case(prdct_current_state)

            `INIT  : begin
                prdct_next_state = `YES_0;
            end

            `YES_0 : begin
                if(cancle)
                    prdct_next_state = `YES_1;
                else
                    prdct_next_state = `YES_0;
            end

            `YES_1 : begin
                if(cancle)
                    prdct_next_state = `NO_1;
                else
                    prdct_next_state = `YES_0;
            end

            `NO_1  : begin
                if(cancle)
                    prdct_next_state = `YES_1;
                else
                    prdct_next_state = `NO_0;
            end

            `NO_0  : begin
                if(cancle)
                    prdct_next_state = `NO_1;
                else
                    prdct_next_state = `NO_0;
            end

        endcase
    end

    assign prdct_br_go = prdct_current_state == `YES_0 || prdct_current_state == `YES_1 ? 1'b1 : 1'b0;

endmodule