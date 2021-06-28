`include "parameter.v"

module if_stage(
    input  clk,
    input  rst,

    output reg [31:0] pc,

    output Inst_Req_Valid,
    input  Inst_Req_Ready,
    input  Inst_Valid,
    output Inst_Ready,

    input [31:0] Instruction,

    //predict branch info from id
    input  [`BR_WD - 1 : 0] br_info,

    //cancle if
    input cancle,

    //real pc from exe
    input [31:0] real_pc,

    //id is ready to accept data
    input  id_allowin,

    //if is ready to pass data
    output if_to_id_valid,

    //data from if to id
    output [`IF_TO_ID_DATA_WD - 1 : 0] if_to_id_data,

    //perf cnt
    output reg [31:0] Cancle_cnt

);

    reg  [ 4:0] if_current_state;
    reg  [ 4:0] if_next_state; 

    wire        br_go;
    wire [31:0] br_target;
    wire [31:0] next_pc;    //predict next pc (from id)

    reg  if_valid;
    wire if_allowin;
    wire to_if_valid;
    wire if_ready_go;

    reg [31:0] inst_reg;

    reg        refresh;

    always@(posedge clk) begin
        if(rst)
            if_current_state <= `INIT;
        else
            if_current_state <= if_next_state;
    end

    always@(*) begin
        case(if_current_state)

            `INIT : begin
                if_next_state = `IF;
            end

            `IF   : begin                
                if(Inst_Req_Valid && Inst_Req_Ready)
                    if_next_state = `IW;
                else
                    if_next_state = `IF;
            end

            `IW   : begin
                if(Inst_Ready && Inst_Valid)
                    if_next_state = `GO;
                else
                    if_next_state = `IW;
            end

            `GO   : begin
                if(id_allowin)
                    if_next_state = `NPC;
                else
                    if_next_state = `GO;
            end

            `NPC  : begin
                if(id_allowin)
                    if_next_state = `IF;
                else
                    if_next_state = `NPC;
            end

        endcase
    end

    always@(posedge clk) begin
        if(rst)
            if_valid <= 1'b0;
        else begin
            if(cancle)
                if_valid <= 1'b0;
            else if(if_allowin && !refresh)
                if_valid <= to_if_valid;
        end
    end

    always@(posedge clk) begin
        if(rst)
            pc <= 32'hfffffffc;
        else begin
            if(if_allowin && to_if_valid && if_next_state == `IF) begin
                if(refresh)
                    pc <= real_pc;
                else
                    pc <= next_pc;
            end
               
        end
    end

    always@(posedge clk) begin
        if(Inst_Valid && if_valid)
            inst_reg <= Instruction;
    end

    always@(posedge clk) begin
        if(cancle)
            refresh <= 1'b1;
        else begin
            if(if_next_state == `IF)
                refresh <= 1'b0;
        end
    end

    always@(posedge clk) begin
        if(rst)
            Cancle_cnt <= 1'b0;
        else begin
            if(cancle)
                Cancle_cnt <= Cancle_cnt + 1;
        end
    end

    assign {br_go, br_target} = br_info;

    assign next_pc = br_go ? br_target : pc + 4;

    assign Inst_Req_Valid = if_current_state == `IF;

    assign Inst_Ready = if_current_state == `IW || if_current_state == `INIT;

    assign if_allowin = !if_valid || if_ready_go && id_allowin;

    assign to_if_valid = ~rst;

    assign if_ready_go = (if_current_state == `GO || if_current_state == `NPC) && !refresh;

    assign if_to_id_valid = if_valid && if_ready_go && !cancle;

    assign if_to_id_data = {
                            pc      ,   //63:32
                            inst_reg    //31:0
                           };


endmodule