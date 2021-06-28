`include "parameter.v"

`timescale 10ns / 1ns

module custom_cpu(
    input  rst,
    input  clk,

`ifdef BHV_SIM
    input  inst_retired_fifo_full,
`endif

    //Instruction request channel
    output [31:0] PC,
    output Inst_Req_Valid,
    input  Inst_Req_Ready,

    //Instruction response channel
    input  [31:0] Instruction,
    input  Inst_Valid,
    output Inst_Ready,

    //Memory request channel
    output [31:0] Address,
    output MemWrite,
    output [31:0] Write_data,
    output [3:0] Write_strb,
    output MemRead,
    input  Mem_Req_Ready,

    //Memory data response channel
    input  [31:0] Read_data,
    input  Read_data_Valid,
    output Read_data_Ready, 

    output [31:0]    cpu_perf_cnt_0,
    output [31:0]    cpu_perf_cnt_1,
    output [31:0]    cpu_perf_cnt_2,
    output [31:0]    cpu_perf_cnt_3,
    output [31:0]    cpu_perf_cnt_4,
    output [31:0]    cpu_perf_cnt_5,
    output [31:0]    cpu_perf_cnt_6,
    output [31:0]    cpu_perf_cnt_7,
    output [31:0]    cpu_perf_cnt_8,
    output [31:0]    cpu_perf_cnt_9,
    output [31:0]    cpu_perf_cnt_10,
    output [31:0]    cpu_perf_cnt_11,
    output [31:0]    cpu_perf_cnt_12,
    output [31:0]    cpu_perf_cnt_13,
    output [31:0]    cpu_perf_cnt_14,
    output [31:0]    cpu_perf_cnt_15

);

/* The following two signals are leveraged for behavioral simulation, 
* both of which are delivered to testbench.
*
* STUDENTS MUST CONTROL LOGICAL BEHAVIORS of BOTH SIGNALS.
*
* inst_retire_valid (1-bit): setting to 1 for one-cycle 
* when inst_retired_fifo_full from testbench is low,  
* indicating that one instruction is being retired from
* the WB stage. 
*
* inst_retired (70-bit): detailed information of the retired instruction,
* mainly including (in order) 
* { 
*   retired PC (32-bit), 
*   reg_file write-back enable (1-bit), 
*   reg_file write-back address (5-bit), 
*   reg_file write-back data (32-bit) 
* }
*
*/
`ifdef BHV_SIM
    wire        inst_retire_valid;
    wire [69:0] inst_retired;
`endif

    wire        inst_retire_valid_tmp;
    wire [69:0] inst_retired_tmp;

    wire        inst_retired_fifo_full_tmp;

    wire [`BR_WD - 1 : 0] br_info;

    wire [31:0] real_pc;

    wire cancle;
    wire id_allowin;
    wire exe_allowin;
    wire mem_allowin;
    wire wb_allowin;

    wire if_to_id_valid;
    wire id_to_exe_valid;
    wire exe_to_mem_valid;
    wire mem_to_wb_valid;

    wire [`IF_TO_ID_DATA_WD   - 1 : 0] if_to_id_data;
    wire [`ID_TO_EXE_DATA_WD  - 1 : 0] id_to_exe_data;
    wire [`EXE_TO_MEM_DATA_WD - 1 : 0] exe_to_mem_data;
    wire [`MEM_TO_WB_DATA_WD - 1 : 0] mem_to_wb_data;

    wire [`WB_TO_RF_DATA_WD - 1 : 0] wb_to_rf_data;

    wire [`EXE_TO_ID_FW_WD - 1 : 0] exe_to_id_fw_data;
    wire [`MEM_TO_ID_FW_WD - 1 : 0] mem_to_id_fw_data;
    wire [`WB_TO_ID_FW_WD  - 1 : 0] wb_to_id_fw_data;

    wire [31:0] Valid_inst_cnt;
    wire [31:0] Br_inst_cnt;
    wire [31:0] Cancle_cnt;
    wire [31:0] Mem_inst_cnt;

    //TODO: Please add your Turbo CPU code here
    //5 stages pipline : IF-ID-EXE-MEM-WB

    if_stage top_if(
        .clk            (clk)           ,
        .rst            (rst)           ,
        .pc             (PC)            ,
        .Inst_Req_Valid (Inst_Req_Valid),
        .Inst_Req_Ready (Inst_Req_Ready),
        .Inst_Valid     (Inst_Valid)    ,
        .Inst_Ready     (Inst_Ready)    ,
        .Instruction    (Instruction)   ,
        .br_info        (br_info)       ,
        .cancle         (cancle)        ,
        .real_pc        (real_pc)       ,
        .id_allowin     (id_allowin)    ,
        .if_to_id_valid (if_to_id_valid),
        .if_to_id_data  (if_to_id_data) ,
        .Cancle_cnt     (Cancle_cnt)
    );

    id_stage top_id(
        .clk               (clk)              ,
        .rst               (rst)              ,
        .br_info           (br_info)          ,
        .cancle            (cancle)           ,
        .if_to_id_valid    (if_to_id_valid)   ,
        .if_to_id_data     (if_to_id_data)    ,
        .exe_allowin       (exe_allowin)      ,
        .id_allowin        (id_allowin)       ,
        .id_to_exe_valid   (id_to_exe_valid)  ,
        .id_to_exe_data    (id_to_exe_data)   ,
        .wb_to_rf_data     (wb_to_rf_data)    ,
        .exe_to_id_fw_data (exe_to_id_fw_data),
        .mem_to_id_fw_data (mem_to_id_fw_data),
        .wb_to_id_fw_data  (wb_to_id_fw_data) 
    );

    exe_stage top_exe(
        .clk               (clk)              ,
        .rst               (rst)              ,
        .cancle            (cancle)           ,
        .real_pc           (real_pc)          ,
        .id_to_exe_valid   (id_to_exe_valid)  ,
        .id_to_exe_data    (id_to_exe_data)   ,
        .mem_allowin       (mem_allowin)      ,
        .exe_allowin       (exe_allowin)      ,
        .exe_to_mem_valid  (exe_to_mem_valid) ,
        .exe_to_mem_data   (exe_to_mem_data)  ,
        .exe_to_id_fw_data (exe_to_id_fw_data)
	);

    mem_stage top_mem(
        .clk               (clk)              ,
        .rst               (rst)              ,
        .Address           (Address)          ,
        .MemWrite          (MemWrite)         ,
        .MemRead           (MemRead)          ,
        .Mem_Req_Ready     (Mem_Req_Ready)    ,
        .Read_data_Ready   (Read_data_Ready)  ,
        .Read_data_Valid   (Read_data_Valid)  ,
        .Read_data         (Read_data)        ,
        .Write_data        (Write_data)       ,
        .Write_strb        (Write_strb)       ,
        .exe_to_mem_valid  (exe_to_mem_valid) ,
        .exe_to_mem_data   (exe_to_mem_data)  ,
        .wb_allowin        (wb_allowin)       ,
        .mem_allowin       (mem_allowin)      ,
        .mem_to_wb_valid   (mem_to_wb_valid)  ,
        .mem_to_wb_data    (mem_to_wb_data)   ,
        .mem_to_id_fw_data (mem_to_id_fw_data)
	);

    wb_stage top_wb(
        .clk                    (clk)                       ,
        .rst                    (rst)                       ,
        .mem_to_wb_valid        (mem_to_wb_valid)           ,
        .mem_to_wb_data         (mem_to_wb_data)            ,
        .wb_allowin             (wb_allowin)                ,
        .wb_to_rf_data          (wb_to_rf_data)             ,
        .wb_to_id_fw_data       (wb_to_id_fw_data)          ,
        .inst_retired_fifo_full (inst_retired_fifo_full_tmp),
        .inst_retire_valid      (inst_retire_valid_tmp)     ,  //remember to modify with BHV_SIM
        .inst_retired           (inst_retired_tmp)          ,
        .Valid_inst_cnt         (Valid_inst_cnt)            ,
        .Br_inst_cnt            (Br_inst_cnt)               ,
        .Mem_inst_cnt           (Mem_inst_cnt)  
	);

    reg [31:0] Cycle_cnt;

    always@(posedge clk) begin
        if(rst)
            Cycle_cnt <= 32'b0;
        else
            Cycle_cnt <= Cycle_cnt + 32'b1;
    end        

    assign cpu_perf_cnt_0 = Cycle_cnt; 

    assign cpu_perf_cnt_1 = Valid_inst_cnt;

    assign cpu_perf_cnt_2 = Br_inst_cnt;

    assign cpu_perf_cnt_3 = Cancle_cnt;

    assign cpu_perf_cnt_4 = Mem_inst_cnt;

`ifdef BHV_SIM
    assign inst_retire_valid = inst_retire_valid_tmp;
    assign inst_retired      = inst_retired_tmp;
`endif

`ifdef BHV_SIM
    assign inst_retired_fifo_full_tmp = inst_retired_fifo_full;
`endif

endmodule

