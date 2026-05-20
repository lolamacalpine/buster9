`timescale 1ns / 1ps


module execute(
    input [8:0] rA_out, rB_out,
    input [8:0] sext_imm, zext_imm,
    input [1:0] alu_src,
    input [2:0] alu_code,
    output [8:0] alu_result, alu_flags_out
    );
    
    wire [8:0] alu_b, alu_flags_out_ext;
    wire [3:0] flags_out;
    
    mux_4x1 alu_src_mux(
        .out(alu_b),
        .in0(rB_out),
        .in1(sext_imm),
        .in2(zext_imm),
        .in3(9'b0),
        .select(alu_src)
    );
    
    alu alu(
        .result(alu_result),
        .flags(flags_out),
        .a(rA_out),
        .b(alu_b),
        .select(alu_code)
    );
    
    assign alu_flags_out = {5'b00000, flags_out};
    
endmodule
