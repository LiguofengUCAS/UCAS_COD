`timescale 1ns / 1ps

module adder(
    input  [7:0] a    ,
    input  [7:0] b    ,
    output [7:0] sum  
);

    assign sum = a + b;

endmodule