`timescale 1ns / 1ps

module tb_cpu_cache();
    reg clock, reset;
    wire done;
    wire [8:0] out;
    reg saw_mem_not_ready;
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

    // Record at least one cache-miss stall at CPU level.
    always @(posedge clock or posedge reset) begin
        if (reset)
            saw_mem_not_ready <= 1'b0;
        else if (dut.MEM_ready == 1'b0)
            saw_mem_not_ready <= 1'b1;
    end

    initial begin
        failed = 0;
        saw_mem_not_ready = 1'b0;
        reset = 1'b1;

        // Program:
        // 0: li  r1, 0      # addr A = 0
        // 1: li  r2, 7      # data = 7
        // 2: st  (r1), r2   # cache line(index 0, tag 0) becomes dirty
        // 3: load r3, (r1)  # read-hit on same line
        // 4: li  r1, 1
        // 5: sll r1, 5      # r1 = 32 (same index 0, different tag)
        // 6: load r3, (r1)  # conflict miss, must evict dirty line for addr 0
        // 7: li  r1, 0
        // 8: load r2, (r1)  # fetch addr 0 again, should observe write-back value 7
        // 9: stop
        dut.fetch_stage.rom.memory[0] = 9'b010001000;
        dut.fetch_stage.rom.memory[1] = 9'b010010111;
        dut.fetch_stage.rom.memory[2] = 9'b000100110;
        dut.fetch_stage.rom.memory[3] = 9'b000011101;
        dut.fetch_stage.rom.memory[4] = 9'b010001001;
        dut.fetch_stage.rom.memory[5] = 9'b011101101;
        dut.fetch_stage.rom.memory[6] = 9'b000011101;
        dut.fetch_stage.rom.memory[7] = 9'b010001000;
        dut.fetch_stage.rom.memory[8] = 9'b000011001;
        dut.fetch_stage.rom.memory[9] = 9'b000000000;

        // address 0  -> RAM word0 index 0
        // address 32 -> RAM word0 index 32
        dut.memory_stage.data_cache.ram.memory[0] = 9'd1;
        dut.memory_stage.data_cache.ram.memory[1] = 9'd2;
        dut.memory_stage.data_cache.ram.memory[32] = 9'd3;
        dut.memory_stage.data_cache.ram.memory[33] = 9'd4;

        #PERIOD;
        reset = 1'b0;

        wait(done == 1'b1);
        #PERIOD;
        #PERIOD;

        // CPU should have observed at least one cache miss stall.
        if (saw_mem_not_ready !== 1'b1) begin
            failed = 1;
            $display("FAIL: Cache miss stall was not observed at CPU level (MEM_ready never low).");
        end

        // Dirty eviction must write back address 0 line to backing memory.
        if (dut.memory_stage.data_cache.ram.memory[0] !== 9'd7) begin
            failed = 1;
            $display("FAIL: Dirty line write-back failed. RAM[0]=%0d, expected 7", dut.memory_stage.data_cache.ram.memory[0]);
        end

        // Final reload from address 0 should restore 7 into r2.
        if (dut.decode_stage.register.r2.out !== 9'd7) begin
            failed = 1;
            $display("FAIL: Reload after eviction failed. r2=%0d, expected 7", dut.decode_stage.register.r2.out);
        end

        // Access to address 32 should load into r3.
        if (dut.decode_stage.register.r3.out !== 9'd3) begin
            failed = 1;
            $display("FAIL: Conflict-miss allocate/load failed. r3=%0d, expected 3", dut.decode_stage.register.r3.out);
        end

        if (!failed)
            $display("PASS: CPU cache functionality (hit, miss stall, dirty write-back, reload).");

        $stop;
    end
endmodule
