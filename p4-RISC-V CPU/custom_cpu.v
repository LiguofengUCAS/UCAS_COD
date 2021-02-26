`timescale 10ns / 1ns

`define INIT  9'b000000001
`define IF    9'b000000010
`define IW    9'b000000100
`define ID    9'b000001000
`define EX    9'b000010000
`define ST    9'b000100000
`define LD    9'b001000000
`define RDW   9'b010000000
`define WB    9'b100000000

module custom_cpu(
	input  rst,
	input  clk,

	//Instruction request channel
	output reg [31:0] PC,
	output Inst_Req_Valid,
	input Inst_Req_Ack,

	//Instruction response channel
	input  [31:0] Instruction,
	input Inst_Valid,
	output Inst_Ack,

	//Memory request channel
	output [31:0] Address,
	output MemWrite,
	output [31:0] Write_data,
	output [3:0] Write_strb,
	output MemRead,
	input Mem_Req_Ack,

	//Memory data response channel
	input  [31:0] Read_data,
	input Read_data_Valid,
	output Read_data_Ack, 

    output [31:0]	cpu_perf_cnt_0,
    output [31:0]	cpu_perf_cnt_1,
    output [31:0]	cpu_perf_cnt_2,
    output [31:0]	cpu_perf_cnt_3,
    output [31:0]	cpu_perf_cnt_4,
    output [31:0]	cpu_perf_cnt_5,
    output [31:0]	cpu_perf_cnt_6,
    output [31:0]	cpu_perf_cnt_7,
    output [31:0]	cpu_perf_cnt_8,
    output [31:0]	cpu_perf_cnt_9,
    output [31:0]	cpu_perf_cnt_10,
    output [31:0]	cpu_perf_cnt_11,
    output [31:0]	cpu_perf_cnt_12,
    output [31:0]	cpu_perf_cnt_13,
    output [31:0]	cpu_perf_cnt_14,
    output [31:0]	cpu_perf_cnt_15

);

  	//TODO: Please add your RISC-V CPU code here
	reg [ 8:0] current_state;
	reg [ 8:0] next_state;

	wire			RF_wen;
	wire [4:0]		RF_waddr;
	wire [31:0]		RF_wdata;

	reg  [31:0] next_pc;
	wire [31:0] br_target;
	wire 		br_go;
	reg  [31:0] inst_reg;
	reg  [31:0] read_data_reg;

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

	wire        load;

	wire  		src1_is_pc;
	wire  		src2_is_4;
	wire  		src2_is_imm;
	wire  		u_extend;

	wire [31:0] alu_src1;
	wire [31:0] alu_src2;
	wire [31:0] alu_result;
	wire [31:0] rs1_value;
	wire [31:0] rs2_value;
	wire [ 3:0] addr_low;
	wire 		overflow;
	wire   		carryout;
	wire   		zero;

	wire [ 7:0] lb_lbu_origin;
	wire [15:0] lh_lhu_origin;
	wire [31:0] lw_result;
	wire [31:0] lb_result;
	wire [31:0] lbu_result;
	wire [31:0] lh_result;
	wire [31:0] lhu_result;
	wire [31:0] load_result;
	
	wire [31:0] s_type_imm;
	wire [31:0] i_type_imm;
	wire [31:0] b_type_imm;
	wire [31:0] u_type_imm;
	wire [31:0] j_type_imm;
	wire [31:0] final_imm;

	wire  		rs1_eq_rs2;
	wire  		rs1_ne_rs2;
	wire  		rs1_lt_rs2;
	wire  		rs1_ge_rs2;
	wire   		rs1_ltu_rs2;
	wire  		rs1_geu_rs2;

	always@(posedge clk) begin
		if(rst)
			current_state <= `INIT;
		else
			current_state <= next_state;
	end

	always@(*) begin
		case(current_state)
			`INIT  : begin
				if(rst)
					next_state = `INIT;
				else
					next_state = `IF;
			end

			`IF    : begin
				if(rst)
					next_state = `INIT;
				else begin
					if(Inst_Req_Valid & Inst_Req_Ack)
						next_state = `IW;
					else
						next_state = `IF;
				end
			end

			`IW    : begin
				if(rst)
					next_state = `INIT;
				else begin
					if(Inst_Ack & Inst_Valid)
						next_state = `ID;
					else
						next_state = `IW;
				end
			end

			`ID    : begin
				if(rst)
					next_state = `INIT;
				else
					next_state = `EX;
			end

			`EX : begin
				if(rst)
					next_state = `INIT;
				else begin
					if(b_type)
						next_state = `IF;
					else if(s_type)
						next_state = `ST;
					else if(load)
						next_state = `LD;
					else
						next_state = `WB;
				end
			end

			`ST    : begin
				if(rst)
					next_state = `INIT;
				else begin
					if(MemWrite & Mem_Req_Ack)
						next_state = `IF;
					else
						next_state = `ST;
				end
			end

			`LD    : begin
				if(rst)
					next_state = `INIT;
				else begin
					if(MemRead & Mem_Req_Ack)
						next_state = `RDW;
					else
						next_state = `LD;
				end
			end

			`RDW   : begin
				if(rst)
					next_state = `INIT;
				else begin
					if(Read_data_Ack & Read_data_Valid)
						next_state = `WB;
					else
						next_state = `RDW;
				end
			end

			`WB    : begin
				if(rst)
					next_state = `INIT;
				else
					next_state = `IF;
			end

			default : next_state = `INIT;
		endcase
	end

	always@(posedge clk) begin
		if(rst)
			next_pc <= 32'h00000000;
		else begin
			if(current_state == `ID) begin
				if(br_go)
					next_pc <= br_target;
				else
					next_pc <= PC + 4;
			end
		end
	end

	always@(posedge clk) begin
		if(rst)
			PC <= 32'h00000000;
		else
			if(next_state == `IF)
				PC <= next_pc;
	end

	always@(posedge clk) begin
		if(rst)
			inst_reg <= 32'h00000000;
		else
			if(current_state == `IW && Inst_Valid)
				inst_reg <= Instruction;
	end

	always@(posedge clk) begin
		if(rst)
			read_data_reg <= 32'h00000000;
		else
			if(current_state == `RDW && Read_data_Valid)
				read_data_reg <= Read_data;
	end

	assign Inst_Req_Valid = current_state == `IF;

	assign Inst_Ack = current_state == `INIT ? 1'b1 :
					  current_state == `IW   ? 1'b1 : 1'b0;

	assign Read_data_Ack = current_state == `RDW; 

    assign r_type = opcode ==7'b0110011;

    assign i_type =  opcode == 7'b1100111 ||
                     opcode == 7'b0000011 ||
                     opcode == 7'b0010011  ;

    assign s_type = opcode == 7'b0100011;

    assign b_type = opcode == 7'b1100011;

    assign u_type = opcode == 7'b0110111 ||
                    opcode == 7'b0010111  ;

    assign j_type = opcode == 7'b1101111;

	assign load = i_type && opcode == 7'b0000011;

    assign rs1    = inst_reg[19:15];
    assign rs2    = inst_reg[24:20];
    assign rd     = inst_reg[11: 7];
    assign opcode = inst_reg[ 6: 0];
    assign funct3 = inst_reg[14:12];
    assign funct7 = inst_reg[31:25];

    assign RF_wen = (r_type || i_type || u_type || j_type) && current_state == `WB;

	assign RF_waddr = rd;

    assign aluop[ 0] = r_type && funct3 == 3'b000 && funct7 == 7'b0000000 ||
                       i_type && opcode == 7'b1100111                     ||
                       i_type && opcode == 7'b0000011                     ||
                       i_type && opcode == 7'b0010011 && funct3 == 3'b000 ||
					   s_type  											  ||
					   j_type ;

    assign aluop[ 1] = r_type && funct3 == 3'b000 && funct7 == 7'b0100000;
                      
    assign aluop[ 2] = r_type && funct3 == 3'b111 && funct7 == 7'b0000000 ||
                       i_type && funct3 == 3'b111 ;

    assign aluop[ 3] = r_type && funct3 == 3'b110 && funct7 == 7'b0000000 ||
                       i_type && funct3 == 3'b110 ;

    assign aluop[ 4] = u_type && opcode == 7'b0010111;

    assign aluop[ 5] = r_type && funct3 == 3'b100 && funct7 == 7'b0000000 ||
                       i_type && funct3 == 3'b100 ;

    assign aluop[ 6] = r_type && funct3 == 3'b010 && funct7 == 7'b0000000 ||
                       i_type && funct3 == 3'b010 && opcode == 7'b0010011 ||
                       b_type && funct3 == 3'b100                         ||
                       b_type && funct3 == 3'b101 ;

    assign aluop[ 7] = r_type && funct3 == 3'b011 && funct7 == 7'b0000000 ||
                       i_type && funct3 == 3'b011 && opcode == 7'b0010011 ||
					   b_type && funct3 == 3'b110                         ||
					   b_type && funct3 == 3'b111 ;

    assign aluop[ 8] = r_type && funct3 == 3'b001 && funct7 == 7'b0000000 ||
                       i_type && funct3 == 3'b001 && funct7 == 7'b0000000  ;

    assign aluop[ 9] = r_type && funct3 == 3'b101 && funct7 == 7'b0000000 ||
                       i_type && funct3 == 3'b101 && funct7 == 7'b0000000  ;

    assign aluop[10] = r_type && funct3 == 3'b101 && funct7 == 7'b0100000 ||
                       i_type && funct3 == 3'b101 && funct7 == 7'b0100000  ;

    assign aluop[11] = u_type && opcode == 7'b0110111;  

    assign src1_is_pc = j_type ||
                        i_type && opcode == 7'b1100111 ||
                        u_type && opcode == 7'b0010111  ;

    assign src2_is_4 = j_type ||
                       i_type && opcode == 7'b1100111;
 
    assign src2_is_imm = i_type && opcode != 7'b1100111 ||
                         s_type 						||
						 u_type ;

    /* logic(1) or algorithm(0) */
    assign u_extend = (funct3 == 3'b100  ||
                       funct3 == 3'b110  ||
                       funct3 == 3'b111) && i_type;

	assign alu_src1 = src1_is_pc ? PC : rs1_value;

	assign alu_src2 = src2_is_imm ? final_imm :
					  src2_is_4   ? 32'h4     :
					  				rs2_value ;

    assign MemWrite = s_type && current_state == `ST;

    assign MemRead = load && current_state == `LD; 

	assign Address = {alu_result[31:2], 2'b0};   

	assign i_type_imm = {32{ u_extend}} & {{20{0}}, inst_reg[31:20]} |
						{32{~u_extend}} & {{20{inst_reg[31]}}, inst_reg[31:20]};

	assign s_type_imm = {{20{inst_reg[31]}}, 
							 inst_reg[31:25], 
							 inst_reg[11:7]};

	assign b_type_imm = {{20{inst_reg[31]}}, 
							 inst_reg[7], 
							 inst_reg[30:25], 
							 inst_reg[11:8], 
							 1'b0};

	assign u_type_imm = {{12{inst_reg[31]}},
						 inst_reg[31:12]};

	assign j_type_imm = {{12{inst_reg[31]}},
							 inst_reg[19:12],
							 inst_reg[20],
							 inst_reg[30:25],
							 inst_reg[24:21],
							 1'b0};

	assign final_imm = {32{i_type}} & i_type_imm |
					   {32{s_type}} & s_type_imm |
					   {32{b_type}} & b_type_imm |
					   {32{u_type}} & u_type_imm |
					   {32{j_type}} & j_type_imm ;

	assign RF_wdata = r_type 						 ? alu_result  :
					  i_type && opcode == 7'b0010011 ? alu_result  :
					  i_type && opcode == 7'b1100111 ? alu_result  :
					  i_type && opcode == 7'b0000011 ? load_result :
					  u_type                         ? alu_result  :
					  /* j_type */                     alu_result  ;

	assign addr_low[0] = alu_result[1:0] == 2'b00;
	assign addr_low[1] = alu_result[1:0] == 2'b01;
	assign addr_low[2] = alu_result[1:0] == 2'b10;
	assign addr_low[3] = alu_result[1:0] == 2'b11;

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

	assign load_result = {32{funct3 == 3'b000}} & lb_result  |
						 {32{funct3 == 3'b001}} & lh_result  |
						 {32{funct3 == 3'b010}} & lw_result  |
						 {32{funct3 == 3'b100}} & lbu_result |
						 {32{funct3 == 3'b101}} & lhu_result ;

	assign Write_data = {32{s_type && funct3 == 3'b000}} & {4{rs2_value[ 7:0]}} |
						{32{s_type && funct3 == 3'b001}} & {2{rs2_value[15:0]}} |
						{32{s_type && funct3 == 3'b010}} &    rs2_value         ;

	assign Write_strb = {4{s_type && funct3 == 3'b000}} & addr_low |
						{4{s_type && funct3 == 3'b010}}	& 4'b1111  |
						{4{s_type && funct3 == 3'b001}}	& {{2{addr_low[3] | addr_low[2]}}, {2{addr_low[1] | addr_low[0]}}};			

	assign rs1_eq_rs2 = rs1_value == rs2_value;

	assign rs1_ne_rs2 = !rs1_eq_rs2;

	assign rs1_lt_rs2 = alu_result[0];

	assign rs1_ge_rs2 = !rs1_lt_rs2;

	assign rs1_ltu_rs2 = alu_result[0];

	assign rs1_geu_rs2 = !rs1_ltu_rs2;

	assign br_go = b_type && funct3 == 3'b000 && rs1_eq_rs2  ||
				   b_type && funct3 == 3'b001 && rs1_ne_rs2  ||
				   b_type && funct3 == 3'b100 && rs1_lt_rs2  ||
				   b_type && funct3 == 3'b101 && rs1_ge_rs2  ||
				   b_type && funct3 == 3'b110 && rs1_ltu_rs2 ||
				   b_type && funct3 == 3'b111 && rs1_geu_rs2 ||
				   i_type && opcode == 7'b1100111            ||
				   j_type  									  ;

	assign br_target = (i_type && opcode == 7'b1100111) ? final_imm + rs1_value :
						/* b_type || j_type */            final_imm + PC        ;


	alu cpu_alu(
		.A       (alu_src1  ),
		.B       (alu_src2  ),
		.ALUop   (aluop     ),
		.Overflow(overflow  ),
		.CarryOut(carryout  ),
		.Zero    (zero      ),
		.Result  (alu_result)
	);

	reg_file registers(
		.clk   (clk     ),
		.rst   (rst     ),
		.waddr (RF_waddr),
		.raddr1(rs1     ),
		.raddr2(rs2     ),
		.wen   (RF_wen  ),
		.wdata (RF_wdata),
		.rdata1(rs1_value),
		.rdata2(rs2_value)
	);

endmodule

