`timescale 1ns / 1ps

module tb_instr_addi();
    reg clock;
    reg reset;
    wire done;
    wire [8:0] out;
    integer failed;

    cpu dut(
        .clock(clock),
        .reset(reset),
        .done(done),
        .out(out)
    );

    parameter PERIOD = 10;
    initial clock = 1'b0;
    always #(PERIOD/2) clock = ~clock;

    task run_case (
        input integer case_num,
        input [8:0] forced_instruction,
        input [8:0] set_r1,
        input [8:0] expected_r1,
        input [8:0] expected_out,
        input [8:0] expected_flags
    );
        begin
            reset = 1'b1;
            #PERIOD;
            reset = 1'b0;

            // Force the instruction to run
            force dut.IFID_instruction = forced_instruction;

            // Set register state for this case.
            dut.decode_stage.register.r1.out = set_r1;

            // Inject one instruction, then wait through WB latency.
            @(posedge clock);
            #1;
            release dut.IFID_instruction;

            repeat (3) begin
                @(posedge clock);
                #1;
            end

            if (dut.decode_stage.register.r1.out != expected_r1) begin
                failed = 1;
                $display("FAIL (ADDI case %0d): r1.out = %0d, expected %0d", case_num, dut.decode_stage.register.r1.out, expected_r1);
            end
            if (out != expected_out) begin
                failed = 1;
                $display("FAIL (ADDI case %0d): out = %0d, expected %0d", case_num, out, expected_out);
            end
            if (dut.decode_stage.register.flags_reg.out != expected_flags) begin
                failed = 1;
                $display("FAIL (ADDI case %0d): flags_reg = %b, expected %b", case_num, dut.decode_stage.register.flags_reg.out, expected_flags);
            end
        end
    endtask

    initial begin
        failed = 0;

        // Case 1: addi r1, 0 with r1=0 -> result 0, Z=1.
        // instr = 010 1 01 000
        run_case(1, 9'b010101000, 9'd0, 9'd0, 9'd0, 9'b000000001);

        // Case 2: addi r1, +3 with r1=5 -> result 8, no flags.
        // instr = 010 1 01 011
        run_case(2, 9'b010101011, 9'd5, 9'd8, 9'd8, 9'b000000000);

        // Case 3: addi r1, -1 with r1=5 -> result 4, carry set.
        // instr = 010 1 01 111
        run_case(3, 9'b010101111, 9'd5, 9'd4, 9'd4, 9'b000000100);

        // Case 4: overflow positive: 255 + 3 -> 0b100000010, N and V set.
        // instr = 010 1 01 011
        run_case(4, 9'b010101011, 9'b011111111, 9'b100000010, 9'b100000010, 9'b000001010);

        // Case 5: overflow negative: -256 + (-4) -> 0b011111100, C and V set.
        // instr = 010 1 01 100
        run_case(5, 9'b010101100, 9'b100000000, 9'b011111100, 9'b011111100, 9'b000001100);

        if (!failed)
            $display("PASS: ADDI");
        $stop;
    end
endmodule
