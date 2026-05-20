`timescale 1ns / 1ps

module decode(
    // decode stage inputs
    input wire [8:0] instruction,
    input wire clock, reset,

    // write back stage inputs
    input wire Wreg_write, Wflags_write, EXflags_write, MEMflags_write,
    input wire [1:0] reg_write0,
    input wire [8:0] reg_write_data, alu_flags_out, EXalu_flags_out, MEMalu_flags_out,

    // from register file
    output wire [8:0] rA_out, rB_out,
    output wire [1:0] rA, rB,
    
    // from control unit
    output wire reg_write_src, reg_write, stop, flags_write, reads_reg0, reads_reg1,
    output wire [1:0] mem_access, alu_src,
    output wire [2:0] alu_code,

    // from jump logic
    output wire [1:0] pc_src_final,
    output wire [8:0] sext_offset,
    output wire [8:0] sext_imm,
    output wire [8:0] zext_imm
    );

    wire reg_read0_src;
    wire [1:0] pc_src;
    wire [1:0] branch_cond;

    // control unit
    control control_unit(
        .reg_write(reg_write),
        .mem_access(mem_access),
        .reg_read0_src(reg_read0_src),
        .alu_src(alu_src),
        .flags_write(flags_write),
        .stop(stop),
        .reads_reg0(reads_reg0),
        .reads_reg1(reads_reg1),
        .reg_write_src(reg_write_src),
        .pc_src(pc_src),
        .branch_cond(branch_cond),
        .alu_code(alu_code),
        .opcode(instruction[8:6]),
        .func0(instruction[5]),
        .func1(instruction[4]),
        .noop(instruction[0])
    );

    // determine R or C type for register read
    assign rB = instruction[1:0];
    mux_2x1 reg_a(.out(rA), .in0(instruction[3:2]), .in1(instruction[4:3]), .select(reg_read0_src));
        
    // register file
    register_file register(
        .out0(rA_out), 
        .out1(rB_out), 
        .flags_out(current_flags_out),
        .clock(clock),
        .reset(reset),
        .enable(Wreg_write),
        .flags_write(Wflags_write),
        .write(reg_write0),
        .read0(rA),
        .read1(rB),
        .in(reg_write_data),
        .flags_in(alu_flags_out)
    );

    wire [8:0] current_flags_out;
    wire [8:0] reg_flags_out;
    assign reg_flags_out = EXflags_write ? EXalu_flags_out :
                           MEMflags_write ? MEMalu_flags_out :
                           current_flags_out;

    // sign-extended jump offset for fetch PC update path
    assign sext_offset = { {3{instruction[5]}}, instruction[5:0]};
    assign sext_imm = { {6{instruction[2]}}, instruction[2:0]};
    assign zext_imm = { {6{1'b0}}, instruction[2:0]};

    // jump decision: gate conditional jumps with current flags
    wire branch_taken = (branch_cond == 2'b00) |
                        (branch_cond == 2'b01 & ~(reg_flags_out[1] ^ reg_flags_out[3])) |
                        (branch_cond == 2'b10 & ~reg_flags_out[0]);

    // compute final pc source using muxes
    wire is_jr = (pc_src == 2'b10);
    wire offset_and_taken = (pc_src == 2'b01) & branch_taken;

    wire [1:0] pc_src_offset;
    mux_2x1 offset_mux(
        .out(pc_src_offset),
        .in0(2'b00),
        .in1(2'b01),
        .select(offset_and_taken)
    );
    
    mux_2x1 final_pc_mux(
        .out(pc_src_final),
        .in0(pc_src_offset),
        .in1(2'b10),
        .select(is_jr)
    );
endmodule
