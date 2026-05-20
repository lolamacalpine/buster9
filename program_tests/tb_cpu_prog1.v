`timescale 1ns / 1ps

module tb_cpu_prog1();
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
                $display("FAIL: Addr %0d | Cache Index [%0d] Offset %b | Value %d, Expected %d", 
                          addr, index, offset, actual, expected);
            end
        end
    endtask

    initial begin
        failed = 0;
        reset = 1'b1;

        // Program 1 (Bubble Sort):
        // li    r3, 7      # r3 = &A[-1] = 7
        //
        // OUTER_LOOP:
        // li    r2, 0      # r2 = &A[0] = 0
        //
        // INNER_LOOP:
        // load  r0, (r2)   # r0 = A[j]
        // addi  r2, 1
        // load  r1, (r2)   # r1 = A[j+1]
        // cmp   r0, r1
        // jge   SKIP_SWAP  # if r0 >= r1, do not swap
        //
        // addi  r2, -1     # swap
        // st    (r2), r1
        // addi  r2, 1
        // st    (r2), r0
        //
        // SKIP_SWAP:
        // cmp   r2, r3
        // jnz   INNER_LOOP # if r2 equals r3, break inner
        //
        // addi  r3, -1     # r3 = &A[i-1]
        // jnz   OUTER_LOOP # if r3 equals 0, break outer
        // stop
        
        // inject instructions into rom
        dut.fetch_stage.rom.memory[0]  = 9'b010011111;
        dut.fetch_stage.rom.memory[1]  = 9'b010010000;
        dut.fetch_stage.rom.memory[2]  = 9'b000010010;
        dut.fetch_stage.rom.memory[3]  = 9'b010110001;
        dut.fetch_stage.rom.memory[4]  = 9'b000010110;
        dut.fetch_stage.rom.memory[5]  = 9'b001110001;
        dut.fetch_stage.rom.memory[6]  = 9'b101000100;
        dut.fetch_stage.rom.memory[7]  = 9'b010110111;
        dut.fetch_stage.rom.memory[8]  = 9'b000101001;
        dut.fetch_stage.rom.memory[9]  = 9'b010110001;
        dut.fetch_stage.rom.memory[10] = 9'b000101000;
        dut.fetch_stage.rom.memory[11] = 9'b001111011;
        dut.fetch_stage.rom.memory[12] = 9'b110110101;
        dut.fetch_stage.rom.memory[13] = 9'b010111111;
        dut.fetch_stage.rom.memory[14] = 9'b110110010;
        dut.fetch_stage.rom.memory[15] = 9'b000000000;

        //inject unsorted data into RAM
        dut.memory_stage.data_cache.ram.memory[0] = 9'd19;
        dut.memory_stage.data_cache.ram.memory[1] = 9'd26;
        dut.memory_stage.data_cache.ram.memory[2] = 9'd74;
        dut.memory_stage.data_cache.ram.memory[3] = 9'd10;
        dut.memory_stage.data_cache.ram.memory[4] = 9'd8;
        dut.memory_stage.data_cache.ram.memory[5] = 9'd9;
        dut.memory_stage.data_cache.ram.memory[6] = 9'd24;
        dut.memory_stage.data_cache.ram.memory[7] = 9'd36;

        #PERIOD;
        reset = 1'b0;

        // wait for program completion
        wait(done == 1'b1);

        // verfiy results are in descending order
        check_cache(9'd0, 9'd74);
        check_cache(9'd1, 9'd36);
        check_cache(9'd2, 9'd26);
        check_cache(9'd3, 9'd24);
        check_cache(9'd4, 9'd19);
        check_cache(9'd5, 9'd10);
        check_cache(9'd6, 9'd9);
        check_cache(9'd7, 9'd8);

        if (!failed)
            $display("PASS prog1: array sorted descending in cache");

        $stop;
    end
endmodule
