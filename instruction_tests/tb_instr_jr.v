`timescale 1ns / 1ps

module tb_instr_jr();
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
        input [8:0] set_r1_target,
        input [8:0] expected_pc
    );
        begin
            reset = 1'b1;
            #PERIOD;
            reset = 1'b0;

            force dut.IFID_instruction = forced_instruction;

            dut.decode_stage.register.r1.out = set_r1_target;

            @(posedge clock);
            #1;

            if (dut.fetch_stage.pc != expected_pc) begin
                failed = 1;
                $display("FAIL (JR case %0d): pc = %0d, expected %0d", case_num, dut.fetch_stage.pc, expected_pc);
            end
            if (out != 9'b000000000) begin
                failed = 1;
                $display("FAIL (JR case %0d): out changed to %0d", case_num, out);
            end

            release dut.IFID_instruction;
            #1;
        end
    endtask

    initial begin
        failed = 0;

        // jr r1: opcode 100, func 1, rA=r1
        // instr = 100 1 01 000

        run_case(1, 9'b100101000, 9'd0,   9'd0);
        run_case(2, 9'b100101000, 9'd5,   9'd5);
        run_case(3, 9'b100101000, 9'd255, 9'd255);

        if (!failed)
            $display("PASS: JR");
        $stop;
    end
endmodule
