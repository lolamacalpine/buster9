`timescale 1ns / 1ps

module tb_cpu_forwarding();
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
        // 0: li  r1, 3
        // 1: add r1, r1      # EX hazard, r1 should become 6
        // 2: li  r2, 0
        // 3: add r2, r1      # MEM hazard, r2 should become 6
        // 4: stop
        dut.fetch_stage.rom.memory[0] = 9'b010001011;
        dut.fetch_stage.rom.memory[1] = 9'b000110101;
        dut.fetch_stage.rom.memory[2] = 9'b010010000;
        dut.fetch_stage.rom.memory[3] = 9'b000111001;
        dut.fetch_stage.rom.memory[4] = 9'b000000000;

        #PERIOD;
        reset = 1'b0;

        wait(done == 1'b1);
        #PERIOD;
        
        // verify program
        if (dut.decode_stage.register.r1.out !== 9'd6) begin
            failed = 1;
            $display("FAIL: EX Hazard Forwarding failed. r1 = %0d, expected 6", dut.decode_stage.register.r1.out);
        end
        
        if (dut.decode_stage.register.r2.out !== 9'd6) begin
            failed = 1;
            $display("FAIL: MEM Hazard Forwarding failed. r2 = %0d, expected 6", dut.decode_stage.register.r2.out);
        end
        

        if (!failed)
            $display("PASS: Forwarding handled both EX and MEM data hazards.");

        $stop;
    end
endmodule
