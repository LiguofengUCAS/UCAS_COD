`timescale 10 ns / 1 ns

`define DATA_WIDTH 32

`define AND 3'b000
`define OR  3'b001
`define ADD 3'b010
`define SUB 3'b110
`define SLT 3'b111

module alu(
    input [`DATA_WIDTH - 1:0]  A,
    input [`DATA_WIDTH - 1:0]  B,
    input [              2:0]  ALUop,
    output                     Overflow,
    output                     CarryOut,
    output                     Zero,
    output [`DATA_WIDTH - 1:0] Result
);
	
    wire                     ext_A;
    wire [`DATA_WIDTH    :0] A_tmp;
    wire [`DATA_WIDTH    :0] B_tmp;
    wire [`DATA_WIDTH - 1:0] and_result;
    wire [`DATA_WIDTH - 1:0] or_result;
    wire [`DATA_WIDTH - 1:0] add_result;
    wire [`DATA_WIDTH - 1:0] sub_result;
    wire [`DATA_WIDTH - 1:0] slt_result;

    assign and_result = A & B;

    assign or_result  = A | B;
    
    // How to prove this CarryOut is correct ?
    // The proof will be given in report.
    assign ext_A = ALUop == `SUB;

    assign A_tmp = {ext_A, A};
    
    // A - B is needed if ALUop == `SUB or `SLT
    assign B_tmp = (ALUop == `SUB || ALUop == `SLT) ? {1'b0, ~B} + 33'b1 : {1'b0, B};

    assign {CarryOut, add_result} = A_tmp + B_tmp;

    assign sub_result = add_result;

    assign slt_result[31:1] = 31'b0;
    
    // If A < 0 and B >= 0, A < B.
    // If A * B >= 0, A < B if and only if A - B < 0.
    assign slt_result[0] = (A[31] & ~B[31]) ||
                           (A[31] ~^ B[31]) && add_result[31];		  
    
    // If A > 0 and B > 0 but A + B < 0
    // If A < 0 and B < 0 but A + B > 0
    // If A > 0 and B < 0 but A - B < 0
    // If A < 0 and B > 0 but A - B > 0
    assign Overflow = !A[31] && !B[31] &&  add_result[31] && ALUop == `ADD ||
                       A[31] &&  B[31] && !add_result[31] && ALUop == `ADD ||
                      !A[31] &&  B[31] &&  sub_result[31] && ALUop == `SUB ||
                       A[31] && !B[31] && !sub_result[31] && ALUop == `SUB  ;

    assign Result = {32{ALUop == `AND}} & and_result |
                    {32{ALUop == `OR }} & or_result  |
                    {32{ALUop == `ADD}} & add_result |
                    {32{ALUop == `SUB}} & sub_result |
                    {32{ALUop == `SLT}} & slt_result ;

    assign Zero = Result == 32'b0;

endmodule
