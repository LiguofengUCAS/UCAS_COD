`timescale 10 ns / 1 ns

`define DATA_WIDTH   32
`define DOUBLE_WIDTH 64
`define OP_WIDTH     12

module alu(
    input [`DATA_WIDTH - 1:0]  A,
    input [`DATA_WIDTH - 1:0]  B,
    input [`OP_WIDTH   - 1:0]  ALUop,
    output                     Overflow,
    output                     CarryOut,
    output                     Zero,
    output [`DATA_WIDTH - 1:0] Result
);
    
    wire                      op_add;
    wire                      op_sub;
    wire                      op_and;
    wire                      op_or;
    wire                      op_auipc;
    wire                      op_xor;
    wire                      op_slt;
    wire                      op_sltu;
    wire                      op_sll;
    wire                      op_srl;
    wire                      op_sra;
    wire                      op_lui;

    wire                       ext_A;
    wire [`DATA_WIDTH      :0] A_tmp;
    wire [`DATA_WIDTH      :0] B_tmp;
    wire [`DATA_WIDTH   - 1:0] and_result;
    wire [`DATA_WIDTH   - 1:0] or_result;
    wire [`DATA_WIDTH   - 1:0] add_result;
    wire [`DATA_WIDTH   - 1:0] sub_result;
    wire [`DATA_WIDTH   - 1:0] auipc_result;
    wire [`DATA_WIDTH   - 1:0] xor_result;
    wire [`DATA_WIDTH   - 1:0] slt_result;
    wire [`DATA_WIDTH   - 1:0] sltu_result;
    wire [`DATA_WIDTH   - 1:0] sll_result;
    wire [`DATA_WIDTH   - 1:0] srl_result;
    wire [`DATA_WIDTH   - 1:0] sra_result;
    wire [`DATA_WIDTH   - 1:0] lui_result;
    wire [`DOUBLE_WIDTH - 1:0] sra_64;

    assign op_add   = ALUop[ 0];
    assign op_sub   = ALUop[ 1];
    assign op_and   = ALUop[ 2];
    assign op_or    = ALUop[ 3];
    assign op_auipc = ALUop[4];  
    assign op_xor   = ALUop[ 5];
    assign op_slt   = ALUop[ 6];
    assign op_sltu  = ALUop[ 7];
    assign op_sll   = ALUop[ 8];
    assign op_srl   = ALUop[ 9];
    assign op_sra   = ALUop[10];
    assign op_lui   = ALUop[11];
    
    assign ext_A = op_sub | op_slt | op_sltu ? 1'b1 : 1'b0;
    assign A_tmp = {ext_A, A};
    assign B_tmp = op_sub | op_slt | op_sltu ? {1'b0, ~B} + 33'b1 : {1'b0, B};
    assign {CarryOut, add_result} = A_tmp + B_tmp;
    assign sub_result = add_result;

    assign and_result = A & B;

    assign or_result  = A | B; 

    assign xor_result = A ^ B;

    assign slt_result[31:1] = 31'b0;
    assign slt_result[0] = (A[31] & ~B[31]) ||
                           (A[31] ~^ B[31]) && add_result[31];          
    assign sltu_result = {31'b0, CarryOut};
    
    assign sll_result = A << B[4:0];
    assign srl_result = A >> B[4:0];
    assign sra_64     = {{32{A[31]}}, A} >> B[4:0];
    assign sra_result = sra_64[31:0];

    assign lui_result = {B[19:0], 12'b0};

    assign auipc_result = A + lui_result;

    assign Overflow = !A[31] && !B[31] &&  add_result[31] && op_add ||
                       A[31] &&  B[31] && !add_result[31] && op_add ||
                      !A[31] &&  B[31] &&  sub_result[31] && op_sub ||
                       A[31] && !B[31] && !sub_result[31] && op_sub  ;

    assign Result = ({32{op_add} }   & add_result )   |
                    ({32{op_sub} }   & sub_result )   |
                    ({32{op_and} }   & and_result )   |
                    ({32{op_or } }   & or_result  )   |
                    ({32{op_auipc} } & auipc_result ) |
                    ({32{op_xor} }   & xor_result )   |
                    ({32{op_slt} }   & slt_result )   |
                    ({32{op_sltu}}   & sltu_result)   |
                    ({32{op_sll} }   & sll_result )   |
                    ({32{op_srl} }   & srl_result )   |
                    ({32{op_sra} }   & sra_result )   |
                    ({32{op_lui} }   & lui_result )   ;
    
    assign Zero = Result == 32'b0 ? 1'b1 : 1'b0;

endmodule