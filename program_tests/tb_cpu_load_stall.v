`timescale 1ns / 1ps

module tb_cpu_load_stall();
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
        // 0: li   r1, 5
        // 1: li   r2, 0
        // 2: st   (r2), r1   # mem[0] = 5
        // 3: load r3, (r2)   # r3 = mem[0]
        // 4: add  r3, r3     # load-use hazard, r3 should become 10
        // 5: stop
        dut.fetch_stage.rom.memory[0] = 9'b010001101;
        dut.fetch_stage.rom.memory[1] = 9'b010010000;
        dut.fetch_stage.rom.memory[2] = 9'b000101001;
        dut.fetch_stage.rom.memory[3] = 9'b000011110;
        dut.fetch_stage.rom.memory[4] = 9'b000111111;
        dut.fetch_stage.rom.memory[5] = 9'b000000000;

        #PERIOD;
        reset = 1'b0;

        wait(done == 1'b1);
        #PERIOD;
        #PERIOD;
        
        if (dut.decode_stage.register.r3.out !== 9'd10) begin
            failed = 1;
            $display("FAIL: Load-Use Stall failed. r3 = %0d, expected 10", dut.decode_stage.register.r3.out);
        end

        if (!failed)
            $display("PASS: Load-Use Hazard detected, pipeline stalled, and memory forwarded.");

        $stop;
    end
endmodule
