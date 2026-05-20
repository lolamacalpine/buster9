`timescale 1ns / 1ps

module tb_cpu_prog3();
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
                $display("FAIL prog3: Addr %0d, Value 0x%h - Expected 0x%h", 
                          addr, actual, expected);
            end
        end
    endtask

    initial begin
        failed = 0;
        reset = 1'b1;

        // Program 3 (String Comparison):
        // li    r1, 0
        // load  r1, (r1)      # r1 = memory[0] = str1 start
        // li    r3, 1
        // load  r3, (r3)      # r3 = memory[1] = str2 start
        //
        // LOOP:
        // load  r0, (r1)      # r0 = str1 char
        // load  r2, (r3)      # r2 = str2 char
        // cmp   r0, r2
        // jnz   DONE
        // addi  r1, 1
        // addi  r3, 1
        // addi  r0, 0          # check null
        // jnz   LOOP
        //
        // li    r0, 2
        // load  r0, (r0)      # r0 = memory[2] = 0xAA
        // li    r1, 3
        // st    (r1), r0      # store 0xAA to memory[3]
        //
        // DONE:
        // stop
        dut.fetch_stage.rom.memory[0]  = 9'b010001000;
        dut.fetch_stage.rom.memory[1]  = 9'b000010101;
        dut.fetch_stage.rom.memory[2]  = 9'b010011001;
        dut.fetch_stage.rom.memory[3]  = 9'b000011111;
        dut.fetch_stage.rom.memory[4]  = 9'b000010001;
        dut.fetch_stage.rom.memory[5]  = 9'b000011011;
        dut.fetch_stage.rom.memory[6]  = 9'b001110010;
        dut.fetch_stage.rom.memory[7]  = 9'b110001000;
        dut.fetch_stage.rom.memory[8]  = 9'b010101001;
        dut.fetch_stage.rom.memory[9]  = 9'b010111001;
        dut.fetch_stage.rom.memory[10] = 9'b010100000;
        dut.fetch_stage.rom.memory[11] = 9'b110111000;
        dut.fetch_stage.rom.memory[12] = 9'b010000010;
        dut.fetch_stage.rom.memory[13] = 9'b000010000;
        dut.fetch_stage.rom.memory[14] = 9'b010001011;
        dut.fetch_stage.rom.memory[15] = 9'b000100100;
        dut.fetch_stage.rom.memory[16] = 9'b000000000;

        // Inject RAM data
        // mem[0] = str1 start, mem[1] = str2 start, mem[2] = 0x0AA
        dut.memory_stage.data_cache.ram.memory[0] = 9'd8;
        dut.memory_stage.data_cache.ram.memory[1] = 9'd23;
        dut.memory_stage.data_cache.ram.memory[2] = 9'h0AA;

        // str1 = "PeasAndCarrots" at [8-22]
        dut.memory_stage.data_cache.ram.memory[8]  = 9'b001010000;
        dut.memory_stage.data_cache.ram.memory[9]  = 9'b001100101;
        dut.memory_stage.data_cache.ram.memory[10] = 9'b001100001;
        dut.memory_stage.data_cache.ram.memory[11] = 9'b001110011;
        dut.memory_stage.data_cache.ram.memory[12] = 9'b001000001;
        dut.memory_stage.data_cache.ram.memory[13] = 9'b001101110;
        dut.memory_stage.data_cache.ram.memory[14] = 9'b001100100;
        dut.memory_stage.data_cache.ram.memory[15] = 9'b001000011;
        dut.memory_stage.data_cache.ram.memory[16] = 9'b001100001;
        dut.memory_stage.data_cache.ram.memory[17] = 9'b001110010;
        dut.memory_stage.data_cache.ram.memory[18] = 9'b001110010;
        dut.memory_stage.data_cache.ram.memory[19] = 9'b001101111;
        dut.memory_stage.data_cache.ram.memory[20] = 9'b001110100;
        dut.memory_stage.data_cache.ram.memory[21] = 9'b001110011;
        dut.memory_stage.data_cache.ram.memory[22] = 9'b000000000;

        // str2 = "PeasAndCarrots" at [23-37]
        dut.memory_stage.data_cache.ram.memory[23] = 9'b001010000;
        dut.memory_stage.data_cache.ram.memory[24] = 9'b001100101;
        dut.memory_stage.data_cache.ram.memory[25] = 9'b001100001;
        dut.memory_stage.data_cache.ram.memory[26] = 9'b001110011;
        dut.memory_stage.data_cache.ram.memory[27] = 9'b001000001;
        dut.memory_stage.data_cache.ram.memory[28] = 9'b001101110;
        dut.memory_stage.data_cache.ram.memory[29] = 9'b001100100;
        dut.memory_stage.data_cache.ram.memory[30] = 9'b001000011;
        dut.memory_stage.data_cache.ram.memory[31] = 9'b001100001;
        dut.memory_stage.data_cache.ram.memory[32] = 9'b001110010;
        dut.memory_stage.data_cache.ram.memory[33] = 9'b001110010;
        dut.memory_stage.data_cache.ram.memory[34] = 9'b001101111;
        dut.memory_stage.data_cache.ram.memory[35] = 9'b001110100;
        dut.memory_stage.data_cache.ram.memory[36] = 9'b001110011;
        dut.memory_stage.data_cache.ram.memory[37] = 9'b000000000;

        #PERIOD;
        reset = 1'b0;

        // wait for stop
        wait(done == 1'b1);
        
        @(posedge clock);
        wait(dut.memory_stage.ready == 1'b1);
        @(posedge clock);
        #1; 

        // check results in cache
        check_cache(9'd3, 9'h0AA);

        if (!failed)
            $display("PASS prog3: matching strings wrote 0xAA to address 3 in the cache");

        $stop;
    end
endmodule