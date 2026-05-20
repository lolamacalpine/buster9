`timescale 1ns / 1ps

module tb_instr_j();
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
        input [8:0] expected_pc
    );
        begin
            reset = 1'b1;
            #PERIOD;
            reset = 1'b0;

            force dut.IF_instruction = forced_instruction;

            // Wait for it to get to decode stage
            @(posedge clock);
            #1;
            @(posedge clock);
            #1;

            if (dut.fetch_stage.pc != expected_pc) begin
                failed = 1;
                $display("FAIL (J case %0d): pc = %0d, expected %0d", case_num, dut.fetch_stage.pc, expected_pc);
            end
            if (out != 9'b000000000) begin
                failed = 1;
                $display("FAIL (J case %0d): out changed to %0d", case_num, out);
            end

            release dut.IF_instruction;
            #1;

        end
    endtask

    initial begin
        failed = 0;

        // j OFF: opcode 111

        run_case(1, 9'b111000000, 9'd1);   // +0
        run_case(2, 9'b111000010, 9'd3);   // +2
        run_case(3, 9'b111111111, 9'd0);   // -1
        run_case(4, 9'b111111110, 9'd511); // -2 wraps to 511

        if (!failed)
            $display("PASS: J");
        $stop;
    end
endmodule
