`timescale 1ns / 1ps

module tb_memory();
    reg clock, reset;
    reg [8:0] rA_out, rB_out;
    reg [1:0] mem_access;
    wire [8:0] read_data;
    wire ready;
    integer failed;

    memory dut(
        .read_data(read_data),
        .ready(ready),
        .clock(clock),
        .reset(reset),
        .rA_out(rA_out),
        .rB_out(rB_out),
        .mem_access(mem_access)
    );

    parameter PERIOD = 10;
    initial clock = 1'b0;
    always #(PERIOD/2) clock = ~clock;

    task run_read_case (
        input integer case_num,
        input [8:0] in_address,
        input exp_miss,
        input [8:0] exp_read_data
    );
        begin
            @(negedge clock);
            rA_out = 9'd0;
            rB_out = in_address;
            mem_access = 2'b01;

            if (exp_miss) begin
                wait (ready == 1'b0);
                wait (ready == 1'b1);
            end
            #1;

            if (read_data !== exp_read_data) begin
                failed = 1;
                $display("FAIL (Case %0d): expected read_data = %0d, got %0d",
                         case_num, exp_read_data, read_data);
            end

            @(negedge clock);
            mem_access = 2'b00;
            #1;
        end
    endtask

    task run_write_case (
        input integer case_num,
        input [8:0] in_address,
        input [8:0] in_write_data,
        input exp_miss
    );
        begin
            @(negedge clock);
            rA_out = in_address;
            rB_out = in_write_data;
            mem_access = 2'b10;

            if (exp_miss) begin
                wait (ready == 1'b0);
                wait (ready == 1'b1);
            end
            #1;

            if (ready !== 1'b1) begin
                failed = 1;
                $display("FAIL (Case %0d): expected ready = 1, got %b", case_num, ready);
            end

            @(negedge clock);
            mem_access = 2'b00;
            #1;
        end
    endtask

    initial begin
        failed = 0;
        reset = 1'b1;
        rA_out = 9'd0;
        rB_out = 9'd0;
        mem_access = 2'b00;

        #PERIOD;
        reset = 1'b0;
        #PERIOD;
        
        if (ready !== 1'b1) begin
            failed = 1;
            $display("FAIL: ready should be high in idle state after reset");
        end

        // Seed backing RAM blocks used by test addresses 1 and 40/41.
        dut.data_cache.ram.memory[0] = 9'd11;  // block 0, offset 0 (address 0)
        dut.data_cache.ram.memory[1] = 9'd23;  // block 0, offset 1 (address 1)
        dut.data_cache.ram.memory[40] = 9'd5;  // block 20, offset 0 (address 40)
        dut.data_cache.ram.memory[41] = 9'd6;  // block 20, offset 1 (address 41)

        // Case 1: Load path uses rB_out as address.
        run_read_case(1, 9'd1, 1'b1, 9'd23);

        // Case 2: Store path writes rB_out to address rA_out.
        run_write_case(2, 9'd40, 9'd77, 1'b1);

        // Case 3: Load back value from address written in Case 2.
        run_read_case(3, 9'd40, 1'b0, 9'd77);

        // Case 4: Store another value at address 41.
        run_write_case(4, 9'd41, 9'd155, 1'b0);

        // Case 5: Load from second written address.
        run_read_case(5, 9'd41, 1'b0, 9'd155);

        if (!failed)
            $display("PASS: MEMORY STAGE");
        $finish;
    end
endmodule
