`include "parameter.v"

module id_stage(
    input  clk,
    input  rst,

    //cancle id
    input cancle,

    //branch info
    output [`BR_WD - 1 : 0] br_info,

    //data from iw is valid
    input  if_to_id_valid,
    input [`IF_TO_ID_DATA_WD - 1 : 0] if_to_id_data,

    //exe is ready to accept data
    input  exe_allowin,

    //id is ready to accept data
    output id_allowin,

    //id is ready to pass data
    output id_to_exe_valid,

    //data from id to exe
    output [`ID_TO_EXE_DATA_WD - 1 : 0] id_to_exe_data,

    //pass data to register
    input [`WB_TO_RF_DATA_WD - 1 : 0] wb_to_rf_data,

    //data-foward path
    input [`EXE_TO_ID_FW_WD - 1 : 0] exe_to_id_fw_data,
    input [`MEM_TO_ID_FW_WD - 1 : 0] mem_to_id_fw_data,
    input [`WB_TO_ID_FW_WD  - 1 : 0] wb_to_id_fw_data

);

    reg  id_valid;
    wire id_ready_go;

    wire [31:0] id_pc;
    wire [31:0] id_inst;

    reg [`IF_TO_ID_DATA_WD - 1 : 0] if_to_id_data_reg;

    wire        rf_wen;     //send to exe then mem then wb
    wire [ 4:0] dest;
    wire        dest_valid;

    wire        wb_rf_wen;
    wire [ 4:0] wb_rf_waddr;
    wire [31:0] wb_rf_wdata;
    wire [31:0] rf_rdata1;
    wire [31:0] rf_rdata2;

    wire        br_go;
    wire        prdct_br_go;
    wire [31:0] br_target;
    wire [ 5:0] br_op;
    wire        beq;
    wire        bne;
    wire        blt;
    wire        bge;
    wire        bltu;
    wire        bgeu;

    wire r_type;
    wire i_type;
    wire s_type;
    wire b_type;
    wire u_type;
    wire j_type;
    
    wire [ 4:0] rs1   ;
    wire [ 4:0] rs2   ;
    wire [ 4:0] rd    ;
    wire [ 6:0] opcode;
    wire [ 2:0] funct3;
    wire [ 6:0] funct7;

    wire [11:0] aluop;

    wire is_load;

    wire [4:0] load_op;
    wire [2:0] store_op;

    wire lb;
    wire lbu;
    wire lh;
    wire lhu;
    wire lw;

    wire sb;
    wire sh;
    wire sw;

    wire src1_is_pc;
    wire src2_is_4;
    wire src2_is_imm;

    wire [31:0] alu_src1;
    wire [31:0] alu_src2;

    wire [31:0] rs1_value;
    wire [31:0] rs2_value;

    wire [31:0] s_type_imm;
    wire [31:0] i_type_imm;
    wire [31:0] b_type_imm;
    wire [31:0] u_type_imm;
    wire [31:0] j_type_imm;
    wire [31:0] final_imm;

    wire rs1_eq_rs2;
    wire rs1_ne_rs2;
    wire rs1_lt_rs2;
    wire rs1_ge_rs2;
    wire rs1_ltu_rs2;
    wire rs1_geu_rs2;

    wire [31:0] exe_pc;
    wire [31:0] mem_pc;
    wire [31:0] wb_pc;

    wire exe_valid;
    wire mem_valid;
    wire wb_valid;

    wire [ 4:0] exe_dest;
    wire [ 4:0] mem_dest;
    wire [ 4:0] wb_dest;

    wire [31:0] exe_data;
    wire [31:0] mem_data;
    wire [31:0] wb_data;

    wire exe_is_load;
    wire mem_is_load;

    wire mem_ready_go;

    wire exe_related;
    wire mem_related;
    wire wb_related;

    wire block;

    wire jump;

    wire [31:0] mem_wdata;

    always@(posedge clk) begin
        if(rst)
            if_to_id_data_reg <= 0;
        else begin 
            if(if_to_id_valid && id_allowin)
                if_to_id_data_reg <= if_to_id_data;
        end
    end

    always@(posedge clk) begin
        if(rst)
            id_valid <= 1'b0;
        else begin
            if(cancle)
                id_valid <= 1'b0;
            else if(id_allowin)
                id_valid <= if_to_id_valid;
        end
    end

    assign block = (exe_is_load && exe_related) || (mem_is_load && mem_related && !mem_ready_go);

    assign id_ready_go = !block && !cancle;

    assign id_allowin = !id_valid || id_ready_go && exe_allowin;

    assign id_to_exe_valid = id_valid && id_ready_go;

    assign {
            id_pc  ,  
            id_inst
           } = if_to_id_data_reg; 

    assign rs1    = id_inst[19:15];
    assign rs2    = id_inst[24:20];
    assign rd     = id_inst[11: 7];
    assign opcode = id_inst[ 6: 0];
    assign funct3 = id_inst[14:12];
    assign funct7 = id_inst[31:25];

    assign r_type = opcode == 7'b0110011;

    assign i_type = opcode == 7'b1100111 ||
                    opcode == 7'b0000011 ||
                    opcode == 7'b0010011  ;

    assign s_type = opcode == 7'b0100011;

    assign b_type = opcode == 7'b1100011;

    assign u_type = opcode == 7'b0110111 ||
                    opcode == 7'b0010111  ;

    assign j_type = opcode == 7'b1101111;

    assign aluop[ 0] = r_type && funct3 == 3'b000 && funct7 == 7'b0000000 ||
                       i_type && opcode == 7'b1100111                     ||
                       i_type && opcode == 7'b0000011                     ||
                       i_type && opcode == 7'b0010011 && funct3 == 3'b000 ||
                       s_type                                             ||
                       j_type ;

    assign aluop[ 1] = r_type && funct3 == 3'b000 && funct7 == 7'b0100000 ||
                       b_type && funct3 == 3'b000                         ||
                       b_type && funct3 == 3'b001 ;
                      
    assign aluop[ 2] = r_type && funct3 == 3'b111 && funct7 == 7'b0000000 ||
                       i_type && funct3 == 3'b111 && opcode == 7'b0010011 ;

    assign aluop[ 3] = r_type && funct3 == 3'b110 && funct7 == 7'b0000000 ||
                       i_type && funct3 == 3'b110 && opcode == 7'b0010011 ;

    assign aluop[ 4] = u_type && opcode == 7'b0010111;

    assign aluop[ 5] = r_type && funct3 == 3'b100 && funct7 == 7'b0000000 ||
                       i_type && funct3 == 3'b100 && opcode == 7'b0010011 ;

    assign aluop[ 6] = r_type && funct3 == 3'b010 && funct7 == 7'b0000000 ||
                       i_type && funct3 == 3'b010 && opcode == 7'b0010011 ||
                       b_type && funct3 == 3'b100                         ||
                       b_type && funct3 == 3'b101 ;

    assign aluop[ 7] = r_type && funct3 == 3'b011 && funct7 == 7'b0000000 ||
                       i_type && funct3 == 3'b011 && opcode == 7'b0010011 ||
                       b_type && funct3 == 3'b110                         ||
                       b_type && funct3 == 3'b111 ;

    assign aluop[ 8] = r_type && funct3 == 3'b001 && funct7 == 7'b0000000 ||
                       i_type && funct3 == 3'b001 && funct7 == 7'b0000000 && opcode == 7'b0010011 ;

    assign aluop[ 9] = r_type && funct3 == 3'b101 && funct7 == 7'b0000000 ||
                       i_type && funct3 == 3'b101 && funct7 == 7'b0000000 && opcode == 7'b0010011;

    assign aluop[10] = r_type && funct3 == 3'b101 && funct7 == 7'b0100000 ||
                       i_type && funct3 == 3'b101 && funct7 == 7'b0100000 && opcode == 7'b0010011 ;

    assign aluop[11] = u_type && opcode == 7'b0110111;  

    assign src1_is_pc = j_type ||
                        i_type && opcode == 7'b1100111 ||
                        u_type && opcode == 7'b0010111  ;

    assign src2_is_4 = j_type ||
                       i_type && opcode == 7'b1100111;
 
    assign src2_is_imm = i_type && opcode != 7'b1100111 ||
                         s_type                         ||
                         u_type ;

    assign alu_src1 = src1_is_pc ? id_pc : rs1_value;

    assign alu_src2 = src2_is_imm ? final_imm :
                      src2_is_4   ? 32'h4     :
                      rs2_value   ;

    assign i_type_imm = {{20{id_inst[31]}}, id_inst[31:20]};

    assign s_type_imm = {{20{id_inst[31]}}, id_inst[31:25], id_inst[11:7]};

    assign b_type_imm = {{20{id_inst[31]}}, id_inst[7], id_inst[30:25], id_inst[11:8], 1'b0};

    assign u_type_imm = {{12{id_inst[31]}}, id_inst[31:12]};

    assign j_type_imm = {{12{id_inst[31]}}, id_inst[19:12], id_inst[20], id_inst[30:25], id_inst[24:21], 1'b0};

    assign final_imm = {32{i_type}} & i_type_imm |
                       {32{s_type}} & s_type_imm |
                       {32{b_type}} & b_type_imm |
                       {32{u_type}} & u_type_imm |
                       {32{j_type}} & j_type_imm ;

    assign rf_wen = r_type || i_type || u_type || j_type;

    assign dest = rd;

    assign is_load = i_type && opcode == 7'b0000011;

    assign is_store = s_type;

    assign lb  = is_load && funct3 == 3'b000;
    assign lbu = is_load && funct3 == 3'b100;
    assign lh  = is_load && funct3 == 3'b001;
    assign lhu = is_load && funct3 == 3'b101;
    assign lw  = is_load && funct3 == 3'b010;

    assign sb = s_type && funct3 == 3'b000;
    assign sh = s_type && funct3 == 3'b001;
    assign sw = s_type && funct3 == 3'b010;
    
    assign load_op = {lb, lbu, lh, lhu, lw};

    assign store_op = {sb, sh, sw};

    assign mem_wdata = {32{sb}} & {4{rs2_value[ 7:0]}} |
                       {32{sh}} & {2{rs2_value[15:0]}} |
                       {32{sw}} &    rs2_value         ;

    assign id_to_exe_data = {
                             jump      ,   //193:193
                             br_go     ,   //192:192    
                             br_target ,   //191:160
                             br_op     ,   //159:154  
                             store_op  ,   //153:151               
                             load_op   ,   //150:146
                             dest      ,   //145:141
                             rf_wen    ,   //140:140
                             mem_wdata ,   //139:108
                             alu_src2  ,   //107:76
                             alu_src1  ,   //75:44
                             aluop     ,   //43:32
                             id_pc         //31:0
                            };  

    assign {exe_pc, exe_is_load, exe_valid, exe_dest, exe_data} = exe_to_id_fw_data;
    assign {mem_pc, mem_ready_go, mem_is_load, mem_valid, mem_dest, mem_data} = mem_to_id_fw_data;
    assign {wb_pc, wb_valid , wb_dest , wb_data} = wb_to_id_fw_data ;

    assign exe_related = (rs1 == exe_dest || rs2 == exe_dest) && exe_dest != 5'b00000 && exe_valid && exe_pc != id_pc;
    assign mem_related = (rs1 == mem_dest || rs2 == mem_dest) && mem_dest != 5'b00000 && mem_valid && mem_pc != id_pc;
    assign wb_related  = (rs1 == wb_dest  || rs2 == wb_dest ) && wb_dest  != 5'b00000 && wb_valid  && wb_pc  != id_pc;

    assign rs1_value = (exe_dest == rs1 && exe_dest != 5'b00000 && exe_valid && exe_pc != id_pc) ? exe_data :
                       (mem_dest == rs1 && mem_dest != 5'b00000 && mem_valid && mem_pc != id_pc) ? mem_data :
                       (wb_dest  == rs1 && wb_dest  != 5'b00000 && wb_valid  && wb_pc  != id_pc) ? wb_data  :
                                                                                                   rf_rdata1;

    assign rs2_value = (exe_dest == rs2 && exe_dest != 5'b00000 && exe_valid && exe_pc != id_pc) ? exe_data :
                       (mem_dest == rs2 && mem_dest != 5'b00000 && mem_valid && mem_pc != id_pc) ? mem_data :
                       (wb_dest  == rs2 && wb_dest  != 5'b00000 && wb_valid  && wb_pc  != id_pc) ? wb_data  :
                                                                                                   rf_rdata2;

    assign {
            wb_rf_wen  ,
            wb_rf_waddr,
            wb_rf_wdata
           } = wb_to_rf_data;

    assign jump = i_type && opcode == 7'b1100111 || j_type;

    assign br_go = jump ? 1'b1 : prdct_br_go && b_type;

    assign br_target = (i_type && opcode == 7'b1100111) ? final_imm + rs1_value :
                        /* b_type || j_type */            final_imm + id_pc     ;

    assign br_info = {br_go, br_target};

    assign beq  = b_type && funct3 == 3'b000;
    assign bne  = b_type && funct3 == 3'b001;
    assign blt  = b_type && funct3 == 3'b100;
    assign bge  = b_type && funct3 == 3'b101;
    assign bltu = b_type && funct3 == 3'b110;
    assign bgeu = b_type && funct3 == 3'b111;

    assign br_op = {beq, bne, blt, bge, bltu, bgeu};

    reg_file cpu_register(
        .clk   (clk        ),
        .rst   (rst        ),
        .waddr (wb_rf_waddr),
        .raddr1(rs1        ),
        .raddr2(rs2        ),
        .wen   (wb_rf_wen  ),
        .wdata (wb_rf_wdata),
        .rdata1(rf_rdata1  ),
        .rdata2(rf_rdata2  )
    );

    predictor cpu_predictor(
        .clk        (clk        ),
        .rst        (rst        ),
        .cancle     (cancle     ),
        .prdct_br_go(prdct_br_go)
    );

endmodule