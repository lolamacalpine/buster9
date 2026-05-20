`timescale 1ns / 1ps

module tb_cpu_decode_write_read_gap3();
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
    always #(PERIOD/2) clock = (clock == 1'b0) ? 1'b1 : 1'b0;

    initial begin
        failed = 0;
        reset = 1'b1;

        // Program:
        // 0: li  r1, 4
        // 1: li  r2, 1
        // 2: li  r3, 2
        // 3: li  r0, 0
        // 4: add r2, r1      # r2 = 1 + 4 = 5
        // 5: stop
        dut.fetch_stage.rom.memory[0] = 9'b010001100;
        dut.fetch_stage.rom.memory[1] = 9'b010010001;
        dut.fetch_stage.rom.memory[2] = 9'b010011010;
        dut.fetch_stage.rom.memory[3] = 9'b010000000;
        dut.fetch_stage.rom.memory[4] = 9'b000111001;
        dut.fetch_stage.rom.memory[5] = 9'b000000000;

        #PERIOD;
        reset = 1'b0;

        wait(done == 1'b1);
        #PERIOD;

        if (dut.decode_stage.register.r1.out !== 9'd4) begin
            failed = 1;
            $display("FAIL: Write did not stick in r1. r1 = %0d, expected 4", dut.decode_stage.register.r1.out);
        end

        if (dut.decode_stage.register.r2.out !== 9'd5) begin
            failed = 1;
            $display("FAIL: Decode read/use after 3-instruction gap failed. r2 = %0d, expected 5", dut.decode_stage.register.r2.out);
        end

        if (!failed)
            $display("PASS: Decode stage correctly reads a register written exactly three instructions earlier.");

        $stop;
    end
endmodule
