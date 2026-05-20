`timescale 1ns / 1ps

module tb_instr_cmp();
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
        input [8:0] set_r2,
        input [8:0] expected_r1,
        input [8:0] expected_flags
    );
        begin
            reset = 1'b1;
            #PERIOD;
            reset = 1'b0;

            force dut.IFID_instruction = forced_instruction;

            dut.decode_stage.register.r1.out = set_r1;
            dut.decode_stage.register.r2.out = set_r2;

            @(posedge clock);
            #1;
            release dut.IFID_instruction;

            repeat (3) begin
                @(posedge clock);
                #1;
            end

            if (dut.decode_stage.register.r1.out != expected_r1) begin
                failed = 1;
                $display("FAIL (CMP case %0d): r1.out changed to %0d, expected %0d", case_num, dut.decode_stage.register.r1.out, expected_r1);
            end
            if (out != 9'b000000000) begin
                failed = 1;
                $display("FAIL (CMP case %0d): out changed to %0d", case_num, out);
            end
            if (dut.decode_stage.register.flags_reg.out != expected_flags) begin
                failed = 1;
                $display("FAIL (CMP case %0d): flags_reg = %b, expected %b", case_num, dut.decode_stage.register.flags_reg.out, expected_flags);
            end
        end
    endtask

    initial begin
        failed = 0;

        // cmp r1, r2: opcode 001, func 11, rA=r1, rB=r2
        // instr = 001 11 01 10

        run_case(1, 9'b001110110, 9'd5,         9'd5,         9'd5,         9'b000000101);
        run_case(2, 9'b001110110, 9'd3,         9'd8,         9'd3,         9'b000000010);
        run_case(3, 9'b001110110, 9'b011001000, 9'b110011100, 9'b011001000, 9'b000001010);

        if (!failed)
            $display("PASS: CMP");
        $stop;
    end
endmodule
