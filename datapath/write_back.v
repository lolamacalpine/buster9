`timescale 1ns / 1ps

module write_back (
    input reg_write_src,
    input [8:0] mem_out, alu_result,

    output [8:0] reg_write_data
    );

    // 0: ALU result, 1: memory
    mux_2x1 reg_wr(
        .out(reg_write_data),
        .in0(alu_result),
        .in1(mem_out),
        .select(reg_write_src)
    );
endmodule