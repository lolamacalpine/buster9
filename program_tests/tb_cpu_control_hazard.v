`timescale 1ns / 1ps

module tb_cpu_control_hazard();
    reg clock, reset;
    wire done;
    wire [8:0] out;
    integer failed;

    cpu dut(
        .clock(clock),
        .reset(reset),
        .forward_enable(1'b1),
        .done(done),
        .out(out)
    );

    parameter PERIOD = 10;
    initial clock = 1'b0;
    always #(PERIOD/2) clock = ~clock;

    initial begin
        failed = 0;
        reset = 1'b1;

        // Program:
        // 0: li  r1, 1
        // 1: cmp r1, r1      # set Zero and GE flags
        // 2: jge +1          # skip instruction 3
        // 3: li  r2, 5       # should be flushed
        // 4: li  r3, 7       # should be flushed
        // 5: li  r3, 6       # branch target
        // 6: stop
        dut.fetch_stage.rom.memory[0] = 9'b010001001;
        dut.fetch_stage.rom.memory[1] = 9'b001110101;
        dut.fetch_stage.rom.memory[2] = 9'b101000010;
        dut.fetch_stage.rom.memory[3] = 9'b010010101;
        dut.fetch_stage.rom.memory[4] = 9'b010011111;
        dut.fetch_stage.rom.memory[5] = 9'b010011110;
        dut.fetch_stage.rom.memory[6] = 9'b000000000;

        #PERIOD;
        reset = 1'b0;

        // Wait for the stop instruction to hit the end of the pipeline
        wait(done == 1'b1);
        #PERIOD;

        // Verify r2 is 0 (Instruction was successfully flushed)
        if (dut.decode_stage.register.r2.out !== 9'd0) begin
            failed = 1;
            $display("FAIL: Control Hazard Flush failed. r2 = %0d", dut.decode_stage.register.r2.out);
        end

        // Verify r3 is not 7 (Branch landed correctly)
        if (dut.decode_stage.register.r3.out == 9'd7) begin
            failed = 1;
            $display("FAIL: Branch failed to jump or land correctly. r3 = %0d, expected 6", dut.decode_stage.register.r3.out);
        end
        
        // Verify r3 is 6 (Branch landed correctly)
        if (dut.decode_stage.register.r3.out !== 9'd6) begin
            failed = 1;
            $display("FAIL: Branch failed to jump or land correctly. r3 = %0d, expected 6", dut.decode_stage.register.r3.out);
        end

        // Verify r1 is still 1 (Flags were correct)
        if (dut.decode_stage.register.r1.out !== 9'd1) begin
            failed = 1;
            $display("FAIL: General register not correct. r1 = %0d", dut.decode_stage.register.r1.out);
        end

        if (!failed)
            $display("PASS: Branch taken, instruction flushed, and flags forwarded.");

        $stop;
    end
endmodule
