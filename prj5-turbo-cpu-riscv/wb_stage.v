`include "parameter.v"

module wb_stage(
    input  clk,
    input  rst,

    //data from mem is valid
    input mem_to_wb_valid,
    input [`MEM_TO_WB_DATA_WD - 1 : 0] mem_to_wb_data,

    //wb is ready to accept data
    output wb_allowin,

    //pass data to register
    output [`WB_TO_RF_DATA_WD - 1 : 0] wb_to_rf_data,

    //data-foward path
    output [`WB_TO_ID_FW_WD - 1 : 0] wb_to_id_fw_data,

    //fifo is full and will not accept data
    input inst_retired_fifo_full,

    //inst retire
    output inst_retire_valid,
    output [`INST_RETIRE_WD - 1 : 0] inst_retired,

    //perf cnt
    output reg [31:0] Valid_inst_cnt,
    output reg [31:0] Br_inst_cnt,
    output reg [31:0] Mem_inst_cnt

);

    reg  wb_valid;
    wire wb_ready_go;
    reg  wb_update;

    wire [31:0] wb_pc;

    wire wb_is_br;
    wire wb_is_mem;

    reg [`MEM_TO_WB_DATA_WD - 1 : 0] mem_to_wb_data_reg;

    wire        wb_rf_wen;
    wire [ 4:0] wb_dest;

    wire [31:0] wb_rf_wdata;

    reg         inst_retire_valid_reg;

    reg         up_retire_valid;

    reg [ 4:0] wb_current_state;
    reg [ 4:0] wb_next_state;

    always@(posedge clk) begin
        if(rst)
            wb_current_state <= `INIT;
        else
            wb_current_state <= wb_next_state;
    end

    always@(*) begin
        case(wb_current_state)

            `INIT : begin
                wb_next_state = `GO;
            end

            `GO   : begin
                if(inst_retired_fifo_full)
                    wb_next_state = `WAIT;
                else
                    wb_next_state = `GO;
            end

            `WAIT : begin
                if(inst_retired_fifo_full)
                    wb_next_state = `WAIT;
                else
                    wb_next_state = `GO;
            end

        endcase
    end

    always@(posedge clk) begin
        if(rst)
            mem_to_wb_data_reg <= 0;
        else begin
            if(mem_to_wb_valid && wb_allowin)
                mem_to_wb_data_reg <= mem_to_wb_data;
        end
    end

    always@(posedge clk) begin
        if(rst)
            wb_valid <= 1'b0;
        else begin
            if(wb_allowin)
                wb_valid <= mem_to_wb_valid;
        end
    end

    
    always@(posedge clk) begin
        if(rst)
            wb_update <= 1'b0;
        else begin
            if(mem_to_wb_data != mem_to_wb_data_reg && mem_to_wb_valid && wb_allowin)
                wb_update <= 1'b1;
            else if(inst_retire_valid && !inst_retired_fifo_full)
                wb_update <= 1'b0;
        end
    end

    always@(posedge clk) begin
        if(rst)
            inst_retire_valid_reg <= 1'b0;
        else begin
            if(mem_to_wb_data != mem_to_wb_data_reg && !inst_retired_fifo_full)
                inst_retire_valid_reg <= 1'b1;
            else if(wb_update && !inst_retired_fifo_full)  
                inst_retire_valid_reg <= 1'b1;
            else
                inst_retire_valid_reg <= 1'b0;
        end
    end

    always@(posedge clk) begin
        if(mem_to_wb_data != mem_to_wb_data_reg)
            up_retire_valid <= 1'b1;
        else
            up_retire_valid <= 1'b0;
    end

    always@(posedge clk) begin
        if(rst)
            Valid_inst_cnt <= 1'b0;
        else begin
            if(inst_retire_valid)
                Valid_inst_cnt <= Valid_inst_cnt + 1;
        end     
    end

    always@(posedge clk) begin
        if(rst)
            Br_inst_cnt <= 1'b0;
        else begin
            if(inst_retire_valid && wb_is_br)
                Br_inst_cnt <= Br_inst_cnt + 1;
        end     
    end

    always@(posedge clk) begin
        if(rst)
            Mem_inst_cnt <= 1'b0;
        else begin
            if(inst_retire_valid && wb_is_mem)
                Mem_inst_cnt <= Mem_inst_cnt + 1;
        end
            
    end

    //always@(posedge clk) begin
    assign inst_retired = {wb_pc, wb_rf_wen, wb_dest, wb_rf_wdata};
    //end
    
    assign wb_ready_go = !inst_retired_fifo_full && wb_valid && wb_current_state == `GO;

    assign wb_allowin = !wb_valid || wb_ready_go;

    assign wb_to_rf_data = {wb_rf_wen, wb_dest, wb_rf_wdata};

    assign inst_retire_valid = inst_retire_valid_reg && wb_valid && wb_update; //&& !inst_retired_fifo_full;
    //assign inst_retire_valid = up_retire_valid && !inst_retired_fifo_full;
    //assign inst_retire_valid = inst_retired_fifo_full ? inst_retire_valid_reg & wb_update : 1'b1;

    assign {
            wb_is_mem,
            wb_is_br,
            wb_dest,
            wb_rf_wen,
            wb_rf_wdata,
            wb_pc
           } = mem_to_wb_data_reg;

    assign wb_to_id_fw_data = {wb_pc, wb_valid && wb_rf_wen, wb_dest, wb_rf_wdata};

endmodule