`timescale 1ns / 1ps

module alu(
    output wire [8:0] result,
    output wire [3:0] flags, // Z, N, C, V
    input wire [8:0] a, b,
    input wire [2:0] select
    );
    
    //add and sub instruction
    wire arith_carry;
    wire arith_overflow;
    wire [8:0] arith_result;
    cla arithmetic(.result(arith_result), .cout(arith_carry), .vout(arith_overflow), .a(a), .b(b), .sub_mode(select[0]));
    
    //and instruction
    wire [8:0] and_result;
    assign and_result = a & b;
    
    //not instruction
    wire [8:0] not_result;
    assign not_result = ~a;
    
    //or instruction
    wire [8:0] or_result;
    assign or_result = a | b;

    
    //sll and srl instructions
    reg [8:0] sll_result;
    reg [8:0] srl_result;
    always @(a or b) begin
        sll_result = a << b[2:0];
        srl_result = a >> b[2:0];
    end
    
    mux_8x1 choose_result(
        .out(result),
        .in0(arith_result),
        .in1(arith_result),
        .in2(and_result),
        .in3(not_result),
        .in4(or_result),
        .in5(sll_result),
        .in6(srl_result),
        .in7(b),
        .select(select)
    );
    
    // Zero flag
    assign flags[0] = ~(result[0] | result[1] | result[2] | result[3] | result[4] | result[5] | result[6] | result[7] | result[8]);
    
    // Negative flag
    assign flags[1] = result[8];
    
    // Carry flag - selected only for add/sub operations
    assign flags[2] = ~select[1] & ~select[2] & arith_carry;
    
    // Overflow flag - selected only for add/sub operations
    assign flags[3] = ~select[1] & ~select[2] & arith_overflow;
endmodule
