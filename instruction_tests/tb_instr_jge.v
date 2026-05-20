`timescale 1ns / 1ps

module tb_instr_jge();
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
        input [8:0] set_flags,
        input [8:0] expected_pc
    );
        begin
            reset = 1'b1;
            #PERIOD;
            reset = 1'b0;

            force dut.IF_instruction = forced_instruction;
            dut.decode_stage.register.flags_reg.out = set_flags;

            // Wait for it to get to decode stage
            @(posedge clock);
            #1;
            @(posedge clock);
            #1;

            if (dut.fetch_stage.pc != expected_pc) begin
                failed = 1;
                $display("FAIL (JGE case %0d): pc = %0d, expected %0d", case_num, dut.fetch_stage.pc, expected_pc);
            end
            if (out != 9'b000000000) begin
                failed = 1;
                $display("FAIL (JGE case %0d): out changed to %0d", case_num, out);
            end

            release dut.IF_instruction;
            #1;

        end
    endtask

    initial begin
        failed = 0;

        // jge OFF: opcode 101

        // Case 1: N=0, V=0 -> take branch with +2 offset: pc = 0 + 1 + 2 = 3
        run_case(1, 9'b101000010, 9'b000000000, 9'd3);

        // Case 2: N=1, V=0 -> do not take: pc = 1
        run_case(2, 9'b101000010, 9'b000000010, 9'd2);

        // Case 3: N=1, V=1 -> take branch with -1 offset: pc = 0
        run_case(3, 9'b101111111, 9'b000001010, 9'd0);

        if (!failed)
            $display("PASS: JGE");
        $stop;
    end
endmodule
