`timescale 1ns / 1ps

module tb_cpu_prog2();
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

    task check_cache(input [8:0] addr, input [8:0] expected);
        reg [3:0] index;
        reg offset;
        reg [23:0] line;
        reg [8:0] actual;
        begin
            index = addr[4:1];
            offset = addr[0];
            line = dut.memory_stage.data_cache.cache_array[index];
            actual = offset ? line[17:9] : line[8:0];

            if (actual !== expected) begin
                failed = 1;
                $display("FAIL prog2: Addr %0d | Value %b (%0d), Expected %b (%0d)", 
                          addr, actual, $signed(actual), expected, $signed(expected));
            end
        end
    endtask

    initial begin
        failed = 0;
        reset = 1'b1;

        // Program 2 (f = x*y - 4):
        // li    r3, 0
        // load  r1, (r3)      # r1 = mem[0] = y
        // li    r3, 1
        // load  r2, (r3)      # r2 = mem[1] = x
        // addi  r0, -4        # f = -4
        // addi  r2, 0
        // li    r3, 2
        // jge   CHECK_POS      # if x >= 0, check if pos
        //
        // NEG_LOOP:
        // sub   r0, r1        # f = f + y
        // addi  r2, 1          # x = x + 1
        // jnz   NEG_LOOP       # if x is not 0, loop
        // j     DONE           # if x = 0, DONE
        //
        // POS_LOOP:
        // add   r0, r1        # f = f + y
        // addi  r2, -1         # x = x - 1
        // CHECK_POS:
        // jnz   POS_LOOP       # if x is not 0, loop
        //
        // DONE:
        // st    (r3), r0      # mem[2] = f
        // stop
        dut.fetch_stage.rom.memory[0]  = 9'b010011000;
        dut.fetch_stage.rom.memory[1]  = 9'b000010111;
        dut.fetch_stage.rom.memory[2]  = 9'b010011001;
        dut.fetch_stage.rom.memory[3]  = 9'b000011011;
        dut.fetch_stage.rom.memory[4]  = 9'b010100100;
        dut.fetch_stage.rom.memory[5]  = 9'b010110000;
        dut.fetch_stage.rom.memory[6]  = 9'b010011010;
        dut.fetch_stage.rom.memory[7]  = 9'b101000110;
        dut.fetch_stage.rom.memory[8]  = 9'b001000001;
        dut.fetch_stage.rom.memory[9]  = 9'b010110001;
        dut.fetch_stage.rom.memory[10] = 9'b110111101;
        dut.fetch_stage.rom.memory[11] = 9'b111000011;
        dut.fetch_stage.rom.memory[12] = 9'b000110001;
        dut.fetch_stage.rom.memory[13] = 9'b010110111;
        dut.fetch_stage.rom.memory[14] = 9'b110111101;
        dut.fetch_stage.rom.memory[15] = 9'b000101100;
        dut.fetch_stage.rom.memory[16] = 9'b000000000;

        // inject RAM data
        // y = mem[0] = -7, x = mem[1] = 3, f stored to mem[2]
        dut.memory_stage.data_cache.ram.memory[0] = 9'b111111001;
        dut.memory_stage.data_cache.ram.memory[1] = 9'b000000011;
        dut.memory_stage.data_cache.ram.memory[2] = 9'b000000011;

        #PERIOD;
        reset = 1'b0;

        // wait for stop instruction
        wait(done == 1'b1);

        wait(dut.memory_stage.data_cache.ready == 1'b1);

        @(posedge clock);
        #1; 

        check_cache(9'd2, 9'b111100111);

        if (!failed)
            $display("PASS prog2: f = x*y - 4 stored correctly in cache");

        $stop;
    end
endmodule