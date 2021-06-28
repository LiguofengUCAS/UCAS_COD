`include "parameter.v"

module exe_stage(
    input  clk,
    input  rst,

    //cancle if and id
    output cancle,

    //real pc from exe to if
    output [31:0] real_pc,

    //data from id is valid
    input  id_to_exe_valid,
    input [`ID_TO_EXE_DATA_WD - 1 : 0] id_to_exe_data,

    //mem is ready to accept data
    input  mem_allowin,

    //exe is ready to accept data
    output exe_allowin,

    //exe is ready to pass data
    output exe_to_mem_valid,

    //data from exe to mem
    output [`EXE_TO_MEM_DATA_WD - 1 : 0] exe_to_mem_data,

    //data-foward path
    output [`EXE_TO_ID_FW_WD - 1 : 0] exe_to_id_fw_data

);

    reg  exe_valid;
    wire exe_ready_go;

    wire [31:0] exe_pc;
    
    reg [`ID_TO_EXE_DATA_WD - 1 : 0] id_to_exe_data_reg;

    wire        exe_rf_wen;
    wire [ 4:0] exe_dest;

    wire [11:0] aluop;
    wire [31:0] alu_src1;
    wire [31:0] alu_src2;
    wire [31:0] alu_result;
    wire [31:0] exe_alu_result;
    wire        zero;
    wire        overflow;
    wire        carryout;

    wire [31:0] mem_wdata;
    wire [31:0] exe_br_target;
    wire [ 4:0] exe_load_op;
    wire [ 2:0] exe_store_op;
    wire [ 5:0] br_op;
    wire        beq;
    wire        bne;
    wire        blt;
    wire        bge;
    wire        bltu;
    wire        bgeu;
    wire        id_br_go;
    wire        exe_br_go;
    wire        id_is_br;
    wire        predict_wrong;

    wire        exe_is_load;

    reg         up_cancle;

    wire        jump;

    always@(posedge clk) begin
        if(id_to_exe_data != id_to_exe_data_reg)
            up_cancle <= 1'b1;
        else
            up_cancle <= 1'b0;
    end

    always@(posedge clk) begin
        if(rst)
            id_to_exe_data_reg <= 0;
        else begin
            if(id_to_exe_valid && exe_allowin)
                id_to_exe_data_reg <= id_to_exe_data;
        end
    end

    always@(posedge clk) begin
        if(rst)
            exe_valid <= 1'b0;
        else begin
            if(exe_allowin)
                exe_valid <= id_to_exe_valid;
        end
    end

    assign exe_ready_go = 1'b1;

    assign exe_allowin = !exe_valid || exe_ready_go && mem_allowin;

    assign exe_to_mem_valid = exe_valid && exe_ready_go;

    assign {
            jump         ,
            id_br_go     ,
            exe_br_target,
            br_op        ,
            exe_store_op ,
            exe_load_op  ,
            exe_dest     ,
            exe_rf_wen   ,
            mem_wdata    ,
            alu_src2     ,
            alu_src1     ,
            aluop        ,
            exe_pc
           } = id_to_exe_data_reg;

    assign rs1_eq_rs2 = zero;

    assign rs1_ne_rs2 = !zero;

    assign rs1_lt_rs2 = alu_result[0];

    assign rs1_ge_rs2 = !alu_result[0];

    assign rs1_ltu_rs2 = alu_result[0];

    assign rs1_geu_rs2 = !alu_result[0];

    assign {beq, bne, blt, bge, bltu, bgeu} = br_op;

    assign exe_br_go = jump                ||
                       beq  && rs1_eq_rs2  ||
                       bne  && rs1_ne_rs2  ||
                       blt  && rs1_lt_rs2  ||
                       bge  && rs1_ge_rs2  ||
                       bltu && rs1_ltu_rs2 ||
                       bgeu && rs1_geu_rs2  ;

    assign predict_wrong = id_br_go != exe_br_go;

    assign cancle = predict_wrong && up_cancle;

    assign real_pc = exe_br_go ? exe_br_target : exe_pc + 4;

    assign id_is_br = |br_op;

    assign exe_to_mem_data = {
                              id_is_br         ,  //110:110
                              exe_store_op  ,  //109:107
                              exe_load_op   ,  //106:102
                              exe_dest      ,  //101:97
                              exe_rf_wen    ,  //96:96
                              mem_wdata     ,  //95:64
                              exe_alu_result,  //63:32
                              exe_pc           //31:0
                             };

    assign exe_alu_result = alu_result;

    assign exe_is_load = |exe_load_op;

    assign exe_to_id_fw_data = {exe_pc, exe_is_load, exe_valid & exe_rf_wen, exe_dest, exe_alu_result};

    alu cpu_alu(
        .A       (alu_src1  ),
        .B       (alu_src2  ),
        .ALUop   (aluop     ),
        .Overflow(overflow  ),
        .CarryOut(carryout  ),
        .Zero    (zero      ),
        .Result  (alu_result)
    );

endmodule