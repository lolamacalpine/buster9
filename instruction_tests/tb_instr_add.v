`timescale 1ns / 1ps

module tb_instr_add();
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
            dut.decode_stage.register.r2.out = set_r2;

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
                $display("FAIL (ADD case %0d): r1.out = %0d, expected %0d", case_num, dut.decode_stage.register.r1.out, expected_r1);
            end
            if (out != expected_out) begin
                failed = 1;
                $display("FAIL (ADD case %0d): out = %0d, expected %0d", case_num, out, expected_out);
            end
            if (dut.decode_stage.register.flags_reg.out != expected_flags) begin
                failed = 1;
                $display("FAIL (ADD case %0d): flags_reg = %b, expected %b", case_num, dut.decode_stage.register.flags_reg.out, expected_flags);
            end
        end
    endtask

    initial begin
        failed = 0;

        // All cases use add r1, r2.
        // instr = 000 11 01 10

        // Case 1: add r1, r2 with r1=0, r2=0 -> result 0, Z=1.
        run_case(1, 9'b000110110, 9'd0, 9'd0, 9'd0, 9'd0, 9'b000000001);

        // Case 2: add r1, r2 with r1=3, r2=5 -> result 8, no flags.
        run_case(2, 9'b000110110, 9'd3, 9'd5, 9'd8, 9'd8, 9'b000000000);

        // Case 3: positive overflow: 200 + 100 -> 9'b100101100 (300 wraps into negative), N and V set.
        run_case(3, 9'b000110110, 9'b011001000, 9'b001100100, 9'b100101100, 9'b100101100, 9'b000001010);

        // Case 4: -1 + 1 -> result 0, Z and C set (carry out with no borrow).
        run_case(4, 9'b000110110, 9'b111111111, 9'b000000001, 9'b000000000, 9'b000000000, 9'b000000101);

        // Case 5: -256 + (-1) -> 9'b011111111 (255), C and V set (both negative, result positive).
        run_case(5, 9'b000110110, 9'b100000000, 9'b111111111, 9'b011111111, 9'b011111111, 9'b000001100);

        if (!failed)
            $display("PASS: ADD");
        $stop;
    end
endmodule
