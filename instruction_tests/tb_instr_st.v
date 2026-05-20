`timescale 1ns / 1ps

module tb_instr_st();
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
        input [8:0] set_r1_addr,
        input [8:0] set_r2_data,
        input [8:0] start_mem_value,
        input [8:0] expected_mem_value
    );
        begin
            reset = 1'b1;
            #PERIOD;
            reset = 1'b0;

            // Overwrite instruction and register values
            force dut.IFID_instruction = forced_instruction;
            dut.decode_stage.register.r1.out = set_r1_addr;
            dut.decode_stage.register.r2.out = set_r2_data;
            
            // Initialize RAM
            dut.memory_stage.data_cache.ram.memory[set_r1_addr] = start_mem_value;

            @(posedge clock);
            #1;
            release dut.IFID_instruction;
            
            // let instruction advance to memory stage
            @(posedge clock);
            @(posedge clock);

            // Wait for cache to be ready
            wait(dut.memory_stage.data_cache.ready == 1'b1);
            
            @(posedge clock);
            #1;

            begin : probe_check
                integer index;
                integer off;
                reg [23:0] line;
                
                index = set_r1_addr[4:1];
                off = set_r1_addr[0];
                line = dut.memory_stage.data_cache.cache_array[index];

                // Check valid bit and dirty bit
                // Check that the data matches the expected value
                if (line[22] !== 1'b1 || line[23] !== 1'b1 || (off ? line[17:9] : line[8:0]) !== expected_mem_value) begin
                    failed = 1;
                    $display("FAIL (ST case %0d): ", case_num);
                    $display("Cache Line [%0d]: Valid=%b, Dirty=%b, Data={%0d, %0d}", index, line[22], line[23], line[17:9], line[8:0]);
                    $display("Expected Value: %0d at Offset: %b", expected_mem_value, off);
                end
            end

            // Verify CPU output
            if (out != 9'b000000000) begin
                failed = 1;
                $display("FAIL (ST case %0d): out changed to %0d", case_num, out);
            end
        end
    endtask

    initial begin
        failed = 0;

        // st (r1), r2: opcode 000, func 10, rA=r1, rB=r2
        // instr = 000 10 01 10

        run_case(1, 9'b000100110, 9'd2, 9'd7,         9'd0,         9'd7);
        run_case(2, 9'b000100110, 9'd0, 9'b111111001, 9'd3,         9'b111111001);
        run_case(3, 9'b000100110, 9'd7, 9'd0,         9'b111111111, 9'd0);

        if (!failed)
            $display("PASS: ST");
        $stop;
    end
endmodule