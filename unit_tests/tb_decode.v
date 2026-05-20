`timescale 1ns / 1ps

module tb_decode();
    reg clock, reset;
    reg [8:0] instruction;
    reg Wreg_write, Wflags_write, EXflags_write, MEMflags_write;
    reg [1:0] reg_write0;
    reg [8:0] reg_write_data, alu_flags_out, EXalu_flags_out, MEMalu_flags_out;

    wire [8:0] rA_out, rB_out;
    wire [1:0] rA, rB;
    wire reg_write_src, reg_write, stop, flags_write, reads_reg0, reads_reg1;
    wire [1:0] mem_access, alu_src, pc_src_final;
    wire [2:0] alu_code;
    wire [8:0] sext_offset, sext_imm, zext_imm;
    integer failed;

    decode dut(
        .instruction(instruction),
        .clock(clock),
        .reset(reset),
        .Wreg_write(Wreg_write),
        .Wflags_write(Wflags_write),
        .EXflags_write(EXflags_write),
        .MEMflags_write(MEMflags_write),
        .reg_write0(reg_write0),
        .reg_write_data(reg_write_data),
        .alu_flags_out(alu_flags_out),
        .EXalu_flags_out(EXalu_flags_out),
        .MEMalu_flags_out(MEMalu_flags_out),
        .rA_out(rA_out),
        .rB_out(rB_out),
        .rA(rA),
        .rB(rB),
        .mem_access(mem_access),
        .reg_write(reg_write),
        .stop(stop),
        .flags_write(flags_write),
        .reads_reg0(reads_reg0),
        .reads_reg1(reads_reg1),
        .reg_write_src(reg_write_src),
        .alu_src(alu_src),
        .alu_code(alu_code),
        .pc_src_final(pc_src_final),
        .sext_offset(sext_offset),
        .sext_imm(sext_imm),
        .zext_imm(zext_imm)
    );

    parameter PERIOD = 10;
    initial clock = 1'b0;
    always #(PERIOD/2) clock = ~clock;

    task run_case (
        input integer case_num,
        input [8:0] in_instruction,
        input in_EXflags_write,
        input [8:0] in_EXalu_flags_out,
        input [1:0] exp_pc_src_final,
        input exp_reg_write,
        input [1:0] exp_mem_access,
        input [8:0] exp_sext_offset,
        input [8:0] exp_sext_imm,
        input [8:0] exp_zext_imm
    );
        begin
            instruction = in_instruction;
            EXflags_write = in_EXflags_write;
            EXalu_flags_out = in_EXalu_flags_out;

            @(posedge clock);
            #1;

            if (pc_src_final !== exp_pc_src_final) begin
                failed = 1;
                $display("FAIL (Case %0d): expected pc_src_final = %b, got %b",
                         case_num, exp_pc_src_final, pc_src_final);
            end

            if (reg_write !== exp_reg_write) begin
                failed = 1;
                $display("FAIL (Case %0d): expected reg_write = %b, got %b",
                         case_num, exp_reg_write, reg_write);
            end

            if (mem_access !== exp_mem_access) begin
                failed = 1;
                $display("FAIL (Case %0d): expected mem_access = %b, got %b",
                         case_num, exp_mem_access, mem_access);
            end

            if (sext_offset !== exp_sext_offset) begin
                failed = 1;
                $display("FAIL (Case %0d): expected sext_offset = %b, got %b",
                         case_num, exp_sext_offset, sext_offset);
            end

            if (sext_imm !== exp_sext_imm) begin
                failed = 1;
                $display("FAIL (Case %0d): expected sext_imm = %b, got %b",
                         case_num, exp_sext_imm, sext_imm);
            end

            if (zext_imm !== exp_zext_imm) begin
                failed = 1;
                $display("FAIL (Case %0d): expected zext_imm = %b, got %b",
                         case_num, exp_zext_imm, zext_imm);
            end

            #1;
        end
    endtask

    initial begin
        failed = 0;

        Wreg_write = 1'b0;
        Wflags_write = 1'b0;
        MEMflags_write = 1'b0;
        reg_write0 = 2'b00;
        reg_write_data = 9'b0;
        alu_flags_out = 9'b0;
        MEMalu_flags_out = 9'b0;
        instruction = 9'b0;
        EXflags_write = 1'b0;
        EXalu_flags_out = 9'b0;

        // Case 1: li r1, 3 -> reg write, immediate path, pc_src_final = 00
        run_case(1, 9'b010001011, 1'b0, 9'b0, 2'b00, 1'b1, 2'b00, 9'b000001011, 9'b000000011, 9'b000000011);

        // Case 2: j offset -> unconditional jump, pc_src_final = 01
        run_case(2, 9'b111000101, 1'b0, 9'b0, 2'b01, 1'b0, 2'b00, 9'b000000101, 9'b111111101, 9'b000000101);

        // Case 3: jr -> jump register, pc_src_final = 10
        run_case(3, 9'b100100000, 1'b0, 9'b0, 2'b10, 1'b0, 2'b00, 9'b111100000, 9'b000000000, 9'b000000000);

        // Case 4: jge taken when N==V in forwarded flags
        run_case(4, 9'b101000001, 1'b1, 9'b000001010, 2'b01, 1'b0, 2'b00, 9'b000000001, 9'b000000001, 9'b000000001);

        // Case 5: jge not taken when N!=V in forwarded flags
        run_case(5, 9'b101000001, 1'b1, 9'b000000010, 2'b00, 1'b0, 2'b00, 9'b000000001, 9'b000000001, 9'b000000001);

        if (!failed)
            $display("PASS: DECODE STAGE");
        $finish;
    end
endmodule
