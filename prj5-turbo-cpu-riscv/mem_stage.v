`include "parameter.v"

module mem_stage(
    input  clk,
    input  rst,

    output [31:0] Address,
    output MemWrite,
    output MemRead,
    input  Mem_Req_Ready,
    output Read_data_Ready,
    input  Read_data_Valid,

    input  [31:0] Read_data,
    output [31:0] Write_data,

    output [ 3:0] Write_strb,

    //data from exe is valid
    input  exe_to_mem_valid,
    input [`EXE_TO_MEM_DATA_WD - 1 : 0] exe_to_mem_data,

    //wb is ready to accept data
    input  wb_allowin,

    //mem is ready to accept data
    output mem_allowin,

    //mem is ready to pass data
    output mem_to_wb_valid,

    //data from mem to rdw
    output [`MEM_TO_WB_DATA_WD - 1 : 0] mem_to_wb_data,

    //data-foward path
    output [`MEM_TO_ID_FW_WD - 1 : 0] mem_to_id_fw_data

);

    reg [ 4:0] mem_current_state;
    reg [ 4:0] mem_next_state;

    reg  mem_valid;
    wire mem_ready_go;

    wire [31:0] mem_pc;

    reg [`EXE_TO_MEM_DATA_WD - 1 : 0] exe_to_mem_data_reg;

    wire        mem_rf_wen;
    wire [ 4:0] mem_dest;

    wire [31:0] mem_alu_result;

    wire        mem_is_br;
    wire        mem_inst;

    wire [31:0] mem_wdata;
    wire [ 4:0] mem_load_op;
    wire [ 2:0] mem_store_op;
    wire        mem_load;
    wire        mem_store;
    wire        lb;
    wire        lh;
    wire        lbu;
    wire        lhu;
    wire        lw;
    wire [31:0] load_result;

    reg         read_data_req;
    reg         write_data_req;
    reg         read_data_ready;

    reg  [31:0] read_data_reg;

    wire [ 3:0] addr_low;
    wire [ 7:0] lb_lbu_origin;
    wire [15:0] lh_lhu_origin;
    wire [31:0] lw_result;
    wire [31:0] lb_result;
    wire [31:0] lbu_result;
    wire [31:0] lh_result;
    wire [31:0] lhu_result;
    wire [31:0] load_reuslt;
    wire [31:0] mem_result;

    always@(posedge clk) begin
        if(rst)
            mem_current_state <= `INIT;
        else
            mem_current_state <= mem_next_state;
    end

    always@(*) begin
        case(mem_current_state)

            `INIT : begin
                mem_next_state = `PRE;
            end

            `PRE  : begin
                if(mem_load || mem_store)
                    mem_next_state = `REQ;
                else
                    mem_next_state = `GO;
            end

            `REQ  : begin
                if(mem_load && Mem_Req_Ready)
                    mem_next_state = `RDW;
                else if(mem_store && Mem_Req_Ready)
                    mem_next_state = `GO;
                else
                    mem_next_state = `REQ;
            end

            `RDW  : begin
                if(Read_data_Ready && Read_data_Valid)
                    mem_next_state = `GO;
                else
                    mem_next_state = `RDW;
            end
    
            `GO   : begin
                if(mem_allowin && (exe_to_mem_data != exe_to_mem_data_reg))
                    mem_next_state = `PRE;
                else
                    mem_next_state = `GO;
            end

        endcase
    end

    always@(posedge clk) begin
        if(rst)
            exe_to_mem_data_reg <= 0;
        else begin
            if(exe_to_mem_valid && mem_allowin)
                exe_to_mem_data_reg <= exe_to_mem_data;
        end
    end

    always@(posedge clk) begin
        if(rst)
            mem_valid <= 1'b0;
        else begin
            if(mem_allowin)
                mem_valid <= exe_to_mem_valid;
        end
    end

    always@(posedge clk) begin
        if(Read_data_Valid)
            read_data_reg <= Read_data;
    end

    always@(posedge clk) begin
        if(rst)
            read_data_ready <= 1'b1;
        else begin
            if(Mem_Req_Ready)
                read_data_ready <= 1'b1;
            else if(Read_data_Valid)
                read_data_ready <= 1'b0;
            else
                read_data_ready <= 1'b0;
        end
    end

    assign mem_ready_go = mem_current_state == `GO && mem_valid;

    assign mem_allowin = !mem_valid || mem_ready_go && wb_allowin;

    assign mem_to_wb_valid = mem_valid && mem_ready_go;

    assign {lb, lbu, lh, lhu, lw} = mem_load_op;

    assign {sb, sh, sw} = mem_store_op;

    assign mem_load = |mem_load_op;

    assign mem_store = |mem_store_op;

    assign MemWrite = mem_store && mem_current_state == `REQ;

    assign MemRead  = mem_load && mem_current_state == `REQ;

    assign Read_data_Ready = mem_current_state == `RDW || mem_current_state == `INIT;

    assign {
            mem_is_br,
            mem_store_op,
            mem_load_op,
            mem_dest,
            mem_rf_wen,
            mem_wdata,
            mem_alu_result,
            mem_pc
           } = exe_to_mem_data_reg;

    assign Address = {mem_alu_result[31:2], 2'b0};

    assign addr_low[0] = mem_alu_result[1:0] == 2'b00;
    assign addr_low[1] = mem_alu_result[1:0] == 2'b01;
    assign addr_low[2] = mem_alu_result[1:0] == 2'b10;
    assign addr_low[3] = mem_alu_result[1:0] == 2'b11;

    assign lb_lbu_origin = ({8{addr_low[0]}} & read_data_reg[ 7:0 ]) |
                           ({8{addr_low[1]}} & read_data_reg[15:8 ]) |
                           ({8{addr_low[2]}} & read_data_reg[23:16]) |
                           ({8{addr_low[3]}} & read_data_reg[31:24]) ;

    assign lh_lhu_origin = ({16{addr_low[3] | addr_low[2]}} & read_data_reg[31:16]) |
                           ({16{addr_low[1] | addr_low[0]}} & read_data_reg[15:0 ]) ;

    assign lb_result  = {{24{lb_lbu_origin[ 7]}}, lb_lbu_origin};

    assign lbu_result = {24'b0, lb_lbu_origin};

    assign lh_result  = {{16{lh_lhu_origin[15]}}, lh_lhu_origin};

    assign lhu_result = {16'b0, lh_lhu_origin};

    assign lw_result  = read_data_reg;

    assign load_result = {32{lb }} & lb_result  |
                         {32{lh }} & lh_result  |
                         {32{lw }} & lw_result  |
                         {32{lbu}} & lbu_result |
                         {32{lhu}} & lhu_result ;

    assign Write_data = mem_wdata;

    assign Write_strb = {4{sb}} & addr_low |
                        {4{sw}} & 4'b1111  |
                        {4{sh}} & {{2{addr_low[3] | addr_low[2]}}, {2{addr_low[1] | addr_low[0]}}};

    assign mem_result = mem_load ? load_result : mem_alu_result;

    assign mem_inst = mem_load || mem_store;

    assign mem_to_wb_data = {
                             mem_inst    ,  //71:71
                             mem_is_br   ,  //70:70
                             mem_dest    ,  //69:65
                             mem_rf_wen  ,  //64:64
                             mem_result  ,  //63:32
                             mem_pc         //31:0
                            };

    assign mem_to_id_fw_data = {
                                mem_pc,
                                mem_ready_go, 
                                mem_load, 
                                mem_valid && mem_rf_wen, 
                                mem_dest, 
                                mem_result
                               };

endmodule