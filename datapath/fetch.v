`timescale 1ns / 1ps

module fetch(
    output wire [8:0] instruction,
    input wire clock, reset, stop,
    input wire [1:0] pc_src,
    input wire [8:0] pc_offset,
    input wire [8:0] pc_reg_target
    );

    wire [8:0] pc, next_pc, pc_inc, offset_pc;

    //instantiate program counter register
    //if stop==1, enable is turned off
    register pc_reg (.clock(clock), .reset(reset), .enable(~stop), .in(next_pc), .out(pc));

    //increment program counter
    cla increment (.result(pc_inc), .cout(), .a(pc), .b(9'b1), .sub_mode(1'b0));

    // add pc+1+offset
    // note PC is already PC+1 because of the pipeline
    cla offset (
        .result(offset_pc),
        .a(pc_offset),
        .b(pc),
        .sub_mode(1'b0)
    );

    //select next pc source
    mux_4x1 pc_mux(
        .out(next_pc),
        .in0(pc_inc),
        .in1(offset_pc),
        .in2(pc_reg_target),
        .in3(9'b0),
        .select(pc_src)
    );

    // Fetch the instruction (rom_prog1 | rom_prog2 | rom_prog3)
    instruction_memory rom(
        .address(pc),
        .out(instruction)
    );

endmodule