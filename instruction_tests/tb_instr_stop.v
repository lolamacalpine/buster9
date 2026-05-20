`timescale 1ns / 1ps

module tb_instr_stop();
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
        input [8:0] forced_instruction
    );
        begin
            reset = 1'b1;
            #PERIOD;
            reset = 1'b0;

            // Force the stop instruction to run
            force dut.IFID_instruction = forced_instruction;

            // Execute one instruction.
            @(posedge clock);
            #1;
            
            repeat (2) begin
                @(posedge clock);
                #1;
            end

            if (done != 1'b1) begin
                failed = 1;
                $display("FAIL (STOP case %0d): done = %0b, expected 1", case_num, done);
            end

            release dut.IFID_instruction;
            #1;
        end
    endtask

    initial begin
        failed = 0;

        // Case 1: stop with rA=r0, rB=r0 (fields are ignored by stop).
        // instr = 000 00 00 00
        run_case(1, 9'b000000000);

        if (!failed)
            $display("PASS: STOP");
        $stop;
    end
endmodule
