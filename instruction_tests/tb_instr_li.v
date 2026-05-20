`timescale 1ns / 1ps

module tb_instr_li();
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
        input [8:0] expected_r1,
        input [8:0] expected_out,
        input [8:0] expected_flags
    );
        begin
            reset = 1'b1;
            #PERIOD;
            reset = 1'b0;

            force dut.IFID_instruction = forced_instruction;

            @(posedge clock);
            #1;
            release dut.IFID_instruction;

            repeat (3) begin
                @(posedge clock);
                #1;
            end

            if (dut.decode_stage.register.r1.out != expected_r1) begin
                failed = 1;
                $display("FAIL (LI case %0d): r1.out = %0d, expected %0d", case_num, dut.decode_stage.register.r1.out, expected_r1);
            end
            if (out != expected_out) begin
                failed = 1;
                $display("FAIL (LI case %0d): out = %0d, expected %0d", case_num, out, expected_out);
            end
            if (dut.decode_stage.register.flags_reg.out != expected_flags) begin
                failed = 1;
                $display("FAIL (LI case %0d): flags_reg = %b, expected %b", case_num, dut.decode_stage.register.flags_reg.out, expected_flags);
            end
        end
    endtask

    initial begin
        failed = 0;

        // li r1, CON: opcode 010, func 0, rA=r1
        // base instr = 010 0 01 CON

        run_case(1, 9'b010001000, 9'd0, 9'd0, 9'b000000000);
        run_case(2, 9'b010001011, 9'd3, 9'd3, 9'b000000000);
        run_case(3, 9'b010001111, 9'd7, 9'd7, 9'b000000000);

        if (!failed)
            $display("PASS: LI");
        $stop;
    end
endmodule
