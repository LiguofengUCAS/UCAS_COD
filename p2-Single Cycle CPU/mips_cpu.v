`timescale 10ns / 1ns

module mips_cpu(
	input  rst,
	input  clk,

	output reg [31:0] PC,
	input  [31:0] Instruction,

	output [31:0] Address,
	output MemWrite,
	output [31:0] Write_data,
	output [3:0] Write_strb,

	input  [31:0] Read_data,
	output MemRead
);

	// THESE THREE SIGNALS ARE USED IN OUR TESTBENCH
	// PLEASE DO NOT MODIFY SIGNAL NAMES
	// AND PLEASE USE THEM TO CONNECT PORTS
	// OF YOUR INSTANTIATION OF THE REGISTER FILE MODULE
	wire			RF_wen;
	wire [4:0]		RF_waddr;
	wire [31:0]		RF_wdata;

	// TODO: PLEASE ADD YOUT CODE BELOW
	// IF
	wire [31:0] next_pc;
	wire [31:0] br_target;
	wire 		br_go;

	assign next_pc = br_go ? br_target : PC + 4;
	always@(posedge clk) begin
		if(rst)
			PC <= 32'b00000000;
		else
			PC <= next_pc;
	end

	// ID
	wire [5:0] opcode;
	wire [4:0] rs;
	wire [4:0] rt;
	wire [4:0] rd;
	wire [4:0] sa;
	wire [5:0] func;
	wire [15:0] imm;
	wire [31:0] ext_imm;
	wire [ 5:0] dest;

	assign opcode = Instruction[31:26];
	assign rs  	  = Instruction[25:21];
	assign rt	  = Instruction[20:16];
	assign rd	  = Instruction[15:11];
	assign sa 	  = Instruction[10:6 ];
	assign func   = Instruction[ 5:0 ];
	assign imm	  = Instruction[15:0 ];

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
	wire 		dest_is_r31;
	wire 		dest_is_rt;
	wire [31:0] rs_value;
	wire [31:0] rt_value;

	assign inst_addiu = opcode == 6'b001001;
	assign inst_addu  = opcode == 6'b0 && sa == 5'b0 && func == 6'b100001;
	assign inst_subu  = opcode == 6'b0 && sa == 5'b0 && func == 6'b100011;
	assign inst_and   = opcode == 6'b0 && sa == 5'b0 && func == 6'b100000;
	assign inst_andi  = opcode == 6'b001000;
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
	assign inst_jr    = opcode == 6'b0 && rt == 5'b0 && rd == 5'b0 && func == 6'b001001;
	assign inst_jalr  = opcode == 6'b0 && rt == 5'b0 && func == 6'b001001;

	assign inst_lb    = opcode == 6'b100000;
	assign inst_lh    = opcode == 6'h100001;
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

	assign RF_wen = inst_addiu | inst_addu  | inst_subu | inst_and  |
					inst_andi  | inst_nor   | inst_or   | inst_ori  |
					inst_xor   | inst_xori  | inst_slt  | inst_slti |
					inst_sltu  | inst_sltiu | inst_sll  | inst_sllv |
					inst_sra   | inst_srav  | inst_srl  | inst_srlv |
					inst_jal   | inst_jalr  | inst_lb   | inst_lh   |
					inst_lw    | inst_lbu   | inst_lhu  | inst_lwl  |
					inst_lwr   | inst_movn  | inst_movz | inst_lui  ;

	assign ALUop[0] = 

	assign RF_waddr = dest;
	assign RF_wdata = res_from_mem ? Read_data : alu_result;

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

