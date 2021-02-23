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

module mips_cpu(
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

    output [31:0]	mips_perf_cnt_0,
    output [31:0]	mips_perf_cnt_1,
    output [31:0]	mips_perf_cnt_2,
    output [31:0]	mips_perf_cnt_3,
    output [31:0]	mips_perf_cnt_4,
    output [31:0]	mips_perf_cnt_5,
    output [31:0]	mips_perf_cnt_6,
    output [31:0]	mips_perf_cnt_7,
    output [31:0]	mips_perf_cnt_8,
    output [31:0]	mips_perf_cnt_9,
    output [31:0]	mips_perf_cnt_10,
    output [31:0]	mips_perf_cnt_11,
    output [31:0]	mips_perf_cnt_12,
    output [31:0]	mips_perf_cnt_13,
    output [31:0]	mips_perf_cnt_14,
    output [31:0]	mips_perf_cnt_15
);

  //TODO: Please add your MIPS CPU code here
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

	wire [ 5:0] opcode;
	wire [ 4:0] rs;
	wire [ 4:0] rt;
	wire [ 4:0] rd;
	wire [ 4:0] sa;
	wire [ 5:0] func;
	wire [15:0] imm;
	wire [ 5:0] dest;
	wire [25:0] jidx;

	assign opcode = inst_reg[31:26];
	assign rs  	  = inst_reg[25:21];
	assign rt	  = inst_reg[20:16];
	assign rd	  = inst_reg[15:11];
	assign sa 	  = inst_reg[10:6 ];
	assign func   = inst_reg[ 5:0 ];
	assign imm	  = inst_reg[15:0 ];
	assign jidx   = inst_reg[25:0 ];

	wire inst_addiu;
	wire inst_addu;
	wire inst_subu;
	wire inst_and;
	wire inst_andi;
	wire inst_nor;
	wire inst_or;
	wire inst_ori;
	wire inst_xor;
	wire inst_xori;
	wire inst_slt;
	wire inst_slti;
	wire inst_sltu;
	wire inst_sltiu;

	wire inst_sll;
	wire inst_sllv;
	wire inst_sra;
	wire inst_srav;
	wire inst_srl;
	wire inst_srlv;

	wire inst_bne;
	wire inst_beq;
	wire inst_bgez;
	wire inst_blez;
	wire inst_bltz;
	wire inst_j;
	wire inst_jal;
	wire inst_jr;
	wire inst_jalr;

	wire inst_lb;
	wire inst_lh;
	wire inst_lw;
	wire inst_lbu;
	wire inst_lhu;
	wire inst_lwl;
	wire inst_lwr;
	wire inst_sb;
	wire inst_sh;
	wire inst_sw;
	wire inst_swl;
	wire inst_swr;

	wire inst_movn;
	wire inst_movz;
	wire inst_lui;

	wire b_j;
	wire store;
	wire load;

	wire [31:0] alu_src1;
	wire [31:0] alu_src2;
	wire [31:0] alu_result;
	wire [11:0] aluop;
	wire        overflow;
	wire        carryout;
	wire        zero;
	wire 		src1_is_sa;
	wire 		src1_is_pc;
	wire        src2_is_imm;
	wire        src2_is_8;
	wire  		res_from_mem;
	wire  		move_to_reg;
	wire 		dest_is_r31;
	wire 		dest_is_rt;
	wire 		cond_br;
	wire 		is_logic;
	wire [31:0] rs_value;
	wire [31:0] rt_value;

	wire  		rs_eq_rt;
	wire        rs_neq_rt;
	wire        rs_eq_zero;
	wire        rs_less_zero;
	wire   		rt_eq_zero;

	wire [ 3:0] addr_low;
	wire [ 7:0] lb_lbu_origin;
	wire [15:0] lh_lhu_origin;
	wire [31:0] lw_result;
	wire [31:0] lb_result;
	wire [31:0] lbu_result;
	wire [31:0] lh_result;
	wire [31:0] lhu_result;
	wire [31:0] lwl_result;
	wire [31:0] lwr_result;

	wire 		swl_0;
	wire   		swl_1;
	wire  		swl_2;
	wire  		swl_3;
	wire 		swr_0;
	wire   		swr_1;
	wire   		swr_2;
	wire  		swr_3;

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
					if(b_j) begin
						if(inst_jal || inst_jalr)
							next_state = `WB;
						else
							next_state = `IF;
					end
					else if(store)
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

	assign Inst_Req_Valid = current_state == `IF ? 1'b1 : 1'b0;

	assign Inst_Ack = (current_state == `INIT || current_state == `IW) ? 1'b1 : 1'b0;

	assign inst_addiu = opcode == 6'b001001;
	assign inst_addu  = opcode == 6'b0 && sa == 5'b0 && func == 6'b100001;
	assign inst_subu  = opcode == 6'b0 && sa == 5'b0 && func == 6'b100011;
	assign inst_and   = opcode == 6'b0 && sa == 5'b0 && func == 6'b100100;
	assign inst_andi  = opcode == 6'b001100;
	assign inst_nor   = opcode == 6'b0 && sa == 5'b0 && func == 6'b100111;
	assign inst_or    = opcode == 6'b0 && sa == 5'b0 && func == 6'b100101;
	assign inst_ori   = opcode == 6'b001101;
	assign inst_xor   = opcode == 6'b0 && sa == 5'b0 && func == 6'b100110;
	assign inst_xori  = opcode == 6'b001110;
	assign inst_slt   = opcode == 6'b0 && sa == 5'b0 && func == 6'b101010;
	assign inst_slti  = opcode == 6'b001010;
	assign inst_sltu  = opcode == 6'b0 && sa == 5'b0 && func == 6'b101011;
	assign inst_sltiu = opcode == 6'b001011;

	assign inst_sll   = opcode == 6'b0 && rs == 5'b0 && func == 6'b0;
	assign inst_sllv  = opcode == 6'b0 && sa == 5'b0 && func == 6'b000100;
	assign inst_sra   = opcode == 6'b0 && rs == 5'b0 && func == 6'b000011;
	assign inst_srav  = opcode == 6'b0 && sa == 5'b0 && func == 6'b000111;
	assign inst_srl   = opcode == 6'b0 && rs == 5'b0 && func == 6'b000010;
	assign inst_srlv  = opcode == 6'b0 && sa == 5'b0 && func == 6'b000110;

	assign inst_bne   = opcode == 6'b000101;
	assign inst_beq   = opcode == 6'b000100;
	assign inst_bgez  = opcode == 6'b000001 && rt == 5'b00001;
	assign inst_blez  = opcode == 6'b000110 && rt == 5'b0;
	assign inst_bltz  = opcode == 6'b000001 && rt == 5'b0;
	assign inst_j     = opcode == 6'b000010;
	assign inst_jal   = opcode == 6'b000011;
	assign inst_jr    = opcode == 6'b0 && rt == 5'b0 && rd == 5'b0 && func == 6'b001000;
	assign inst_jalr  = opcode == 6'b0 && rt == 5'b0 && func == 6'b001001;

	assign inst_lb    = opcode == 6'b100000;
	assign inst_lh    = opcode == 6'b100001;
	assign inst_lw    = opcode == 6'b100011;
	assign inst_lbu   = opcode == 6'b100100;
	assign inst_lhu   = opcode == 6'b100101;
	assign inst_lwl   = opcode == 6'b100010;
	assign inst_lwr   = opcode == 6'b100110;
	assign inst_sb    = opcode == 6'b101000;
	assign inst_sh    = opcode == 6'b101001;
	assign inst_sw    = opcode == 6'b101011;
	assign inst_swl   = opcode == 6'b101010;
	assign inst_swr   = opcode == 6'b101110;

	assign inst_movn  = opcode == 6'b0 && sa == 5'b0 && func == 6'b001011;
	assign inst_movz  = opcode == 6'b0 && sa == 5'b0 && func == 6'b001010;
	assign inst_lui   = opcode == 6'b001111 && rs == 5'b0;

	assign b_j = inst_bne  | inst_beq | inst_bgez | inst_blez |
				 inst_bltz | inst_j   | inst_jal  | inst_jr   |
				 inst_jalr;

	assign store = inst_sb | inst_sh | inst_sw | inst_swl |
				   inst_swr;

	assign load  = inst_lb  | inst_lh  | inst_lw | inst_lbu |
				   inst_lhu | inst_lwl | inst_lwr;

	assign RF_wen = (inst_addiu | inst_addu  | inst_subu   | inst_and  |
					 inst_andi  | inst_nor   | inst_or     | inst_ori  |
					 inst_xor   | inst_xori  | inst_slt    | inst_slti |
					 inst_sltu  | inst_sltiu | inst_sll    | inst_sllv |
				  	 inst_sra   | inst_srav  | inst_srl    | inst_srlv |
				 	 inst_jal   | inst_jalr  | inst_lb     | inst_lh   |
				 	 inst_lw    | inst_lbu   | inst_lhu    | inst_lwl  |
				 	 inst_lwr   | inst_lui   | move_to_reg ) && current_state == `WB;

	assign aluop[ 0] = inst_addiu | inst_addu | inst_lw  | inst_sw  |
					   inst_jal   | inst_jalr | inst_lb  | inst_lbu |
					   inst_lh    | inst_lhu  | inst_sb  | inst_sh  |
					   inst_lwl   | inst_lwr  | inst_swl | inst_swr ;
	assign aluop[ 1] = inst_subu;
	assign aluop[ 2] = inst_and   | inst_andi ;
	assign aluop[ 3] = inst_or    | inst_ori  ;
	assign aluop[ 4] = inst_nor   ;
	assign aluop[ 5] = inst_xor   | inst_xori ;
	assign aluop[ 6] = inst_slt   | inst_slti ;
	assign aluop[ 7] = inst_sltu  | inst_sltiu;
	assign aluop[ 8] = inst_sll   | inst_sllv ;
	assign aluop[ 9] = inst_srl   | inst_srlv ;
	assign aluop[10] = inst_sra   | inst_srav ;
	assign aluop[11] = inst_lui   ;

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

	assign lwl_result = ({32{addr_low[0]}} & {read_data_reg[7:0 ], rt_value[23:0 ]}) |
						({32{addr_low[1]}} & {read_data_reg[15:0], rt_value[15:0 ]}) |
						({32{addr_low[2]}} & {read_data_reg[23:0], rt_value[ 7:0 ]}) |
						({32{addr_low[3]}} &  read_data_reg                        ) ;

	assign lwr_result = ({32{addr_low[0]}} &  read_data_reg                         ) |
						({32{addr_low[1]}} & {rt_value[31:24], read_data_reg[31:8 ]}) |
						({32{addr_low[2]}} & {rt_value[31:16], read_data_reg[31:16]}) |
						({32{addr_low[3]}} & {rt_value[31:8 ], read_data_reg[31:24]}) ;

	assign res_from_mem = inst_lb | inst_lbu | inst_lh  | inst_lhu |
						  inst_lw | inst_lwl | inst_lwr ;

	assign move_to_reg = inst_movn & !rt_eq_zero |
						 inst_movz &  rt_eq_zero ;

	assign RF_waddr = dest;

	assign RF_wdata = move_to_reg ? rs_value  :
					  inst_lb     ? lb_result :
					  inst_lbu    ? lbu_result:
					  inst_lh     ? lh_result :
					  inst_lhu    ? lhu_result:
					  inst_lw     ? lw_result :
					  inst_lwl    ? lwl_result:
					  inst_lwr    ? lwr_result:
					  				alu_result;

	assign src1_is_sa = inst_sll | inst_srl | inst_sra ;

	assign src1_is_pc = inst_jal | inst_jalr ;

	assign src2_is_imm = inst_addiu | inst_lui  | inst_lw  | inst_slti |
						 inst_sltiu | inst_andi | inst_ori | inst_xori |
						 inst_lb    | inst_lbu  | inst_lh  | inst_lhu  |
						 inst_sb    | inst_sh   | inst_sw  | inst_lwl  | 
						 inst_lwr   | inst_swl  | inst_swr ;

	assign src2_is_8 = inst_jal | inst_jalr;

	assign is_logic = inst_and | inst_andi | inst_or   | inst_ori |
					  inst_nor | inst_xor  | inst_xori ;

	assign alu_src1 = src1_is_sa ? {27'b0, imm[10:6]} :
					  src1_is_pc ? PC                 :
					  			   rs_value           ;

	assign alu_src2 = (src2_is_imm &&  is_logic) ? {16'b0, imm}         :
					  (src2_is_imm && !is_logic) ? {{16{imm[15]}}, imm} :
					   src2_is_8                 ? 32'd8                :
					   							   rt_value             ;

	assign dest_is_r31 = inst_jal | inst_jalr;

	assign dest_is_rt = inst_addiu | inst_lui  | inst_lw  | inst_slti |
						inst_sltiu | inst_andi | inst_ori | inst_xori |
						inst_lb    | inst_lbu  | inst_lh  | inst_lhu  |
						inst_lwl   | inst_lwr  ;

	assign MemWrite = (inst_sw | inst_sb | inst_sh | inst_swl |
					   inst_swr) && current_state == `ST;

	assign MemRead  = (inst_lw  | inst_lb  | inst_lbu | inst_lh |
					   inst_lhu | inst_lwl | inst_lwr) && current_state == `LD;

	assign Read_data_Ack = current_state == `RDW;				   

	assign Address = {alu_result[31:2], 2'b0};

	assign swl_0 = inst_swl & addr_low[0];
	assign swl_1 = inst_swl & addr_low[1];
	assign swl_2 = inst_swl & addr_low[2];
	assign swl_3 = inst_swl & addr_low[3];
	assign swr_0 = inst_swr & addr_low[0];
	assign swr_1 = inst_swr & addr_low[1];
	assign swr_2 = inst_swr & addr_low[2];
	assign swr_3 = inst_swr & addr_low[3];


	assign Write_strb = ({4{inst_sw}} & 4'hf    ) |
						({4{inst_sb}} & addr_low) |
						({4{swl_0  }} & 4'h1    ) |
						({4{swl_1  }} & 4'h3    ) |
						({4{swl_2  }} & 4'h7    ) |
						({4{swl_3  }} & 4'hf    ) |
						({4{swr_0  }} & 4'hf    ) |
						({4{swr_1  }} & 4'he    ) |
						({4{swr_2  }} & 4'hc    ) |
						({4{swr_3  }} & 4'h8    ) |
						({4{inst_sh}} & {{2{addr_low[3] | addr_low[2]}}, {2{addr_low[1] | addr_low[0]}}});

	assign Write_data = ({32{inst_sb}} & {     4{rt_value[ 7:0 ]}}) |
						({32{inst_sh}} & {     2{rt_value[15:0 ]}}) |
						({32{swl_0  }} & {     4{rt_value[31:24]}}) |
						({32{swl_1  }} & {     2{rt_value[31:16]}}) |
						({32{swl_2  }} & {8'h00, rt_value[31:8 ]} ) |
						({32{swr_1  }} & {rt_value[23:0], 8'h00}  ) |
						({32{swr_2  }} & {     2{rt_value[15:0 ]}}) |
						({32{swr_3  }} & {     4{rt_value[ 7:0 ]}}) |
						({32{inst_sw | swl_3 | swr_0}} & rt_value)  ;

	assign dest = dest_is_r31 ? 5'd31 :
				  dest_is_rt  ? rt    :
				  				rd    ;

	assign rs_eq_rt     = rs_value == rt_value;
	assign rs_neq_rt    = !rs_eq_rt;
	assign rs_eq_zero   = rs_value == 32'b0;
	assign rs_less_zero = rs_value[31];
	assign rt_eq_zero   = rt_value == 32'b0;

	assign cond_br = inst_beq | inst_bne | inst_bgez  | inst_blez | inst_bltz;

	assign br_go = inst_bne  &  rs_neq_rt |
				   inst_beq  &  rs_eq_rt  | 
				   inst_bgez & !rs_less_zero | 
				   inst_blez & (rs_eq_zero   | rs_less_zero) |
				   inst_bltz &  rs_less_zero |
				   inst_j    | inst_jal   | inst_jr    | inst_jalr ;

	assign br_target = cond_br              ? (PC + {{14{imm[15]}}, imm, 2'b0} + 4)   :
					  (inst_jr | inst_jalr) ? rs_value 								  :
					  /*inst_jal | inst_j*/   {PC[31:28], jidx, 2'b0};

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
		.raddr1(rs      ),
		.raddr2(rt      ),
		.wen   (RF_wen  ),
		.wdata (RF_wdata),
		.rdata1(rs_value),
		.rdata2(rt_value)
	);

endmodule

