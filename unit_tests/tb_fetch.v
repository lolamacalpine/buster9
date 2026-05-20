`timescale 1ns / 1ps

module tb_fetch();
    reg clock, reset, stop;
    reg [1:0] pc_src;
    reg [8:0] pc_offset, pc_reg_target;
    wire [8:0] instruction;
    integer failed;

    fetch dut(
        .instruction(instruction),
        .clock(clock),
        .reset(reset),
        .stop(stop),
        .pc_src(pc_src),
        .pc_offset(pc_offset),
        .pc_reg_target(pc_reg_target)
    );

    parameter PERIOD = 10;
    initial clock = 1'b0;
    always #(PERIOD/2) clock = ~clock;

    task run_case (
        input integer case_num,
        input in_reset,
        input in_stop,
        input [1:0] in_pc_src,
        input [8:0] in_pc_offset,
        input [8:0] in_pc_reg_target,
        input [8:0] exp_instruction
    );
        begin
            reset = in_reset;
            stop = in_stop;
            pc_src = in_pc_src;
            pc_offset = in_pc_offset;
            pc_reg_target = in_pc_reg_target;

            @(posedge clock);
            #1;

            if (instruction !== exp_instruction) begin
                failed = 1;
                $display("FAIL (Case %0d): expected instruction = %b, got %b",
                         case_num, exp_instruction, instruction);
            end

            #1;
        end
    endtask

    initial begin
        failed = 0;

        // Override ROM words for deterministic unit test behavior
        dut.rom.memory[0] = 9'b111000001;
        dut.rom.memory[1] = 9'b111000010;
        dut.rom.memory[2] = 9'b111000011;
        dut.rom.memory[3] = 9'b111000100;
        dut.rom.memory[4] = 9'b111000101;

        // Reset to PC=0 and fetch first instruction
        run_case(1, 1'b1, 1'b0, 2'b00, 9'b0, 9'b0, 9'b111000001);

        // Release reset and increment PC to 1
        run_case(2, 1'b0, 1'b0, 2'b00, 9'b0, 9'b0, 9'b111000010);

        // Branch with offset: from PC=1 to PC=3
        run_case(3, 1'b0, 1'b0, 2'b01, 9'd2, 9'b0, 9'b111000100);

        // Jump register target to PC=4
        run_case(4, 1'b0, 1'b0, 2'b10, 9'b0, 9'd4, 9'b111000101);

        // Stop freezes PC and instruction
        run_case(5, 1'b0, 1'b1, 2'b00, 9'b0, 9'b0, 9'b111000101);

        if (!failed)
            $display("PASS: FETCH STAGE");
        $finish;
    end
endmodule
