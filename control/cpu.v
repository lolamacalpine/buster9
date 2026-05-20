`timescale 1ns / 1ps

module cpu(
    input wire clock,
    input wire reset,
    input wire forward_enable,
    output reg done,
    output reg [8:0] out
    );

    // IF stage output
    wire [8:0] IF_instruction;

    // IF/ID pipeline register output (input to decode)
    wire [8:0] IFID_instruction;

    // ID stage outputs
    wire [8:0] ID_rA_out;
    wire [8:0] ID_rB_out;
    wire [1:0] ID_rA;
    wire [1:0] ID_rB;
    wire [1:0] ID_mem_access;
    wire ID_reg_write_src;
    wire ID_reg_write;
    wire ID_stop;
    wire ID_flags_write;
    wire [1:0] ID_alu_src;
    wire [2:0] ID_alu_code;
    wire ID_reads_reg0;
    wire ID_reads_reg1;
    wire [1:0] ID_pc_src_final;
    wire [8:0] ID_sext_offset;
    wire [8:0] ID_sext_imm;
    wire [8:0] ID_zext_imm;

    // ID/EX pipeline register outputs
    wire [8:0] IDEX_rA_out;
    wire [8:0] IDEX_rB_out;
    wire [8:0] IDEX_sext_imm;
    wire [8:0] IDEX_zext_imm;
    wire [1:0] IDEX_rA;
    wire [1:0] IDEX_rB;
    wire [1:0] IDEX_mem_access;
    wire IDEX_reg_write;
    wire IDEX_stop;
    wire IDEX_flags_write;
    wire IDEX_reg_write_src;
    wire [1:0] IDEX_alu_src;
    wire [2:0] IDEX_alu_code;

    // EX stage outputs
    wire [8:0] EX_alu_result;
    wire [8:0] EX_alu_flags_out;

    // EX/MEM pipeline register outputs
    wire [8:0] EXMEM_rA_out;
    wire [8:0] EXMEM_rB_out;
    wire [1:0] EXMEM_rA;
    wire [1:0] EXMEM_mem_access;
    wire EXMEM_stop;
    wire EXMEM_reg_write;
    wire EXMEM_flags_write;
    wire EXMEM_reg_write_src;
    wire [8:0] EXMEM_alu_result;
    wire [8:0] EXMEM_alu_flags_out;

    // memory stage outputs
    wire [8:0] MEM_read_data;
    wire MEM_ready;

    // MEM/WB pipeline register outputs
    wire MEMWB_reg_write;
    wire MEMWB_flags_write;
    wire [1:0] MEMWB_rA;
    wire MEMWB_reg_write_src;
    wire [8:0] MEMWB_mem_out;
    wire [8:0] MEMWB_alu_result;
    wire [8:0] MEMWB_alu_flags_out;

    // write-back stage outputs
    wire [8:0] WB_reg_write_data;

    // forwarding unit wires
    wire [1:0] forward_a;
    wire [1:0] forward_b;
    wire [8:0] forward_rA_out;
    wire [8:0] forward_rB_out;

    // load-use hazard stall signal
    wire load_hazard_stall;
    
    // control hazard (branching) wires
    wire control_flush = (ID_pc_src_final != 2'b00); //flush when branch was taken

    fetch fetch_stage(
        .instruction(IF_instruction),
        .clock(clock),
        .reset(reset),
        .stop(ID_stop | load_hazard_stall | !MEM_ready),
        .pc_src(ID_pc_src_final),
        .pc_offset(ID_sext_offset),
        .pc_reg_target(ID_rA_out)
    );

    IFID_reg IFID_reg(
        .clock(clock),
        .reset(reset),
        .flush(control_flush),
        .enable(~load_hazard_stall & ~ID_stop & MEM_ready),
        .INinstruction(IF_instruction),
        .OUTinstruction(IFID_instruction)
    );

    decode decode_stage(
        .instruction(IFID_instruction),
        .clock(clock),
        .reset(reset),
        .Wreg_write(MEMWB_reg_write),
        .Wflags_write(MEMWB_flags_write),
        .EXflags_write(IDEX_flags_write),
        .MEMflags_write(EXMEM_flags_write),
        .EXalu_flags_out(EX_alu_flags_out),
        .MEMalu_flags_out(EXMEM_alu_flags_out),
        .alu_flags_out(MEMWB_alu_flags_out),
        .reg_write0(MEMWB_rA),
        .reg_write_data(WB_reg_write_data),
        .rA_out(ID_rA_out),
        .rB_out(ID_rB_out),
        .rA(ID_rA),
        .rB(ID_rB),
        .mem_access(ID_mem_access),
        .reg_write(ID_reg_write),
        .stop(ID_stop),
        .flags_write(ID_flags_write),
        .reg_write_src(ID_reg_write_src),
        .alu_src(ID_alu_src),
        .alu_code(ID_alu_code),
        .reads_reg0(ID_reads_reg0),
        .reads_reg1(ID_reads_reg1),
        .pc_src_final(ID_pc_src_final),
        .sext_offset(ID_sext_offset),
        .sext_imm(ID_sext_imm),
        .zext_imm(ID_zext_imm)
    );

    IDEX_reg IDEX_reg(
        .clock(clock),
        .reset(reset),
        .flush(load_hazard_stall & MEM_ready),
        .enable(MEM_ready),
        .INrA_out(ID_rA_out),
        .INrB_out(ID_rB_out),
        .INrA(ID_rA),
        .INrB(ID_rB),
        .INmem_access(ID_mem_access),
        .INreg_write(ID_reg_write),
        .INstop(ID_stop),
        .INflags_write(ID_flags_write),
        .INreg_write_src(ID_reg_write_src),
        .INalu_src(ID_alu_src),
        .INalu_code(ID_alu_code),
        .INsext_imm(ID_sext_imm),
        .INzext_imm(ID_zext_imm),
        .OUTrA_out(IDEX_rA_out),
        .OUTrB_out(IDEX_rB_out),
        .OUTrA(IDEX_rA),
        .OUTrB(IDEX_rB),
        .OUTmem_access(IDEX_mem_access),
        .OUTreg_write(IDEX_reg_write),
        .OUTstop(IDEX_stop),
        .OUTflags_write(IDEX_flags_write),
        .OUTreg_write_src(IDEX_reg_write_src),
        .OUTalu_src(IDEX_alu_src),
        .OUTalu_code(IDEX_alu_code),
        .OUTsext_imm(IDEX_sext_imm),
        .OUTzext_imm(IDEX_zext_imm)
    );    

    load_stall load_stall(
        .stall(load_hazard_stall),
        .IDEX_reg_write_src(IDEX_reg_write_src),
        .IDEX_dest_reg(IDEX_rA),
        .EXMEM_reg_write_src(EXMEM_reg_write_src),
        .EXMEM_dest_reg(EXMEM_rA),
        .ID_rA(ID_rA),
        .ID_rB(ID_rB),
        .ID_reads_reg0(ID_reads_reg0),
        .ID_reads_reg1(ID_reads_reg1)
    );
    
    forwarding forwarding_unit(
        .forward_enable(forward_enable),
        .EXMEM_reg_write(EXMEM_reg_write),
        .MEMWB_reg_write(MEMWB_reg_write),
        .IDEX_rA(IDEX_rA),         
        .IDEX_rB(IDEX_rB),
        .EXMEM_dest_reg(EXMEM_rA), 
        .MEMWB_dest_reg(MEMWB_rA),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    mux_4x1 forward_a_mux(
        .out(forward_rA_out),
        .in0(IDEX_rA_out),
        .in1(WB_reg_write_data),
        .in2(EXMEM_alu_result),
        .in3(9'b0),
        .select(forward_a)
    );
    
    mux_4x1 forward_b_mux(
        .out(forward_rB_out),
        .in0(IDEX_rB_out),
        .in1(WB_reg_write_data),
        .in2(EXMEM_alu_result),
        .in3(9'b0),
        .select(forward_b)
    );

    execute execute_stage(
        .rA_out(forward_rA_out),
        .rB_out(forward_rB_out),
        .sext_imm(IDEX_sext_imm),
        .zext_imm(IDEX_zext_imm),
        .alu_src(IDEX_alu_src),
        .alu_code(IDEX_alu_code),
        .alu_result(EX_alu_result),
        .alu_flags_out(EX_alu_flags_out)
    );

    EXMEM_reg EXMEM_reg(
        .clock(clock),
        .reset(reset),
        .enable(MEM_ready),
        .INrA_out(forward_rA_out),
        .INrB_out(forward_rB_out),
        .INrA(IDEX_rA),
        .INmem_access(IDEX_mem_access),
        .INstop(IDEX_stop),
        .INreg_write(IDEX_reg_write),
        .INflags_write(IDEX_flags_write),
        .INreg_write_src(IDEX_reg_write_src),
        .INalu_result(EX_alu_result),
        .INalu_flags(EX_alu_flags_out),
        .OUTrA_out(EXMEM_rA_out),
        .OUTrB_out(EXMEM_rB_out),
        .OUTrA(EXMEM_rA),
        .OUTmem_access(EXMEM_mem_access),
        .OUTstop(EXMEM_stop),
        .OUTreg_write(EXMEM_reg_write),
        .OUTflags_write(EXMEM_flags_write),
        .OUTreg_write_src(EXMEM_reg_write_src),
        .OUTalu_result(EXMEM_alu_result),
        .OUTalu_flags(EXMEM_alu_flags_out)
    );

    memory memory_stage(
        .clock(clock),
        .reset(reset),
        .rA_out(EXMEM_rA_out),
        .rB_out(EXMEM_rB_out),
        .mem_access(EXMEM_mem_access),
        .read_data(MEM_read_data),
        .ready(MEM_ready)
    );

    MEMWB_reg MEMWB_reg(
        .clock(clock),
        .reset(reset),
        .INreg_write(EXMEM_reg_write && MEM_ready),
        .INflags_write(EXMEM_flags_write),
        .INreg_write_src(EXMEM_reg_write_src),
        .INmem_out(MEM_read_data),
        .INalu_result(EXMEM_alu_result),
        .INalu_flags_out(EXMEM_alu_flags_out),
        .INrA(EXMEM_rA),
        .OUTreg_write(MEMWB_reg_write),
        .OUTflags_write(MEMWB_flags_write),
        .OUTreg_write_src(MEMWB_reg_write_src),
        .OUTmem_out(MEMWB_mem_out),
        .OUTalu_result(MEMWB_alu_result),
        .OUTalu_flags_out(MEMWB_alu_flags_out),
        .OUTrA(MEMWB_rA)
    );

    write_back write_back_stage(
        .reg_write_src(MEMWB_reg_write_src),
        .mem_out(MEMWB_mem_out),
        .alu_result(MEMWB_alu_result),
        .reg_write_data(WB_reg_write_data)
    );    

    // Set out to WB result when one exists; otherwise drive Xs.
    always @(posedge clock or posedge reset) begin
        if (reset)
            out <= 9'b0;
        else if (MEMWB_reg_write)
            out <= WB_reg_write_data;
        else
            out <= 9'bxxxxxxxxx;
    end
    
    //set done bit to 1 only when stop instruction is executed
    always @(posedge clock or posedge reset) begin
        if (reset)
            done <= 1'b0;
        else if (EXMEM_stop)
            done <= 1'b1;
    end
endmodule
