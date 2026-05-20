`timescale 1ns / 1ps

module tb_cache();
    reg clock, reset;
    reg enable, read_write;
    reg [8:0] address, write_data;
    wire [8:0] data;
    wire [8:0] out;
    wire ready;
    integer failed;

    assign data = (enable && read_write) ? write_data : 9'bz;
    assign out = data;

    cache dut(
        .ready(ready),
        .data(data),
        .clock(clock),
        .reset(reset),
        .enable(enable),
        .read_write(read_write),
        .address(address)
    );

    parameter PERIOD = 10;
    initial clock = 1'b0;
    always #(PERIOD/2) clock = ~clock;

    task run_read_case (
        input integer case_num,
        input [8:0] in_address,
        input exp_wait_ready,
        input [8:0] exp_out
    );
        begin
            @(posedge clock);
            enable <= 1'b1;
            read_write <= 1'b0;
            address <= in_address;

            @(posedge clock);
            if (exp_wait_ready) begin
                // Falling edge after the request is registered: ready has settled
                @(negedge clock);
                wait (ready == 1'b1);
            end

            @(posedge clock);
            #1;
            if (out !== exp_out) begin
                failed = 1;
                $display("FAIL (Case %0d): expected out = %0d, got %0d", case_num, exp_out, out);
            end

            @(posedge clock);
            enable <= 1'b0;
            @(posedge clock);
        end
    endtask

    task run_write_case (
        input integer case_num,
        input [8:0] in_address,
        input [8:0] in_write_data,
        input exp_wait_ready
    );
        begin
            @(posedge clock);
            enable <= 1'b1;
            read_write <= 1'b1;
            address <= in_address;
            write_data <= in_write_data;

            @(posedge clock);
            if (exp_wait_ready) begin
                @(negedge clock);
                wait (ready == 1'b1);
            end

            @(posedge clock);
            #1;
            if (ready !== 1'b1) begin
                failed = 1;
                $display("FAIL (Case %0d): expected ready = 1, got %b", case_num, ready);
            end

            @(posedge clock);
            enable <= 1'b0;
            @(posedge clock);
        end
    endtask

    initial begin
        failed = 0;
        reset = 1'b1;
        enable = 0;
        read_write = 0;
        address = 0;
        write_data = 0;

        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        reset = 1'b0;
        @(posedge clock);
        @(posedge clock);

        // Block 0 (RAM addresses 0 and 1)
        dut.ram.memory[1] = 9'd20;
        dut.ram.memory[0] = 9'd10;

        // Block 16 (RAM addresses 32 and 33)
        dut.ram.memory[33] = 9'd40;
        dut.ram.memory[32] = 9'd30;

        // Case 1: Compulsory read miss fetches RAM[0] offset 0
        run_read_case(1, 9'd0, 1'b1, 9'd10);

        // Case 2: Read hit returns offset 1 from cached line
        run_read_case(2, 9'd1, 1'b1, 9'd20);

        // Case 3: Write hit updates cached line and responds immediately
        run_write_case(3, 9'd0, 9'd99, 1'b1);

        // Case 4: Dirty eviction on miss writes back, then allocates address 32
        run_read_case(4, 9'd32, 1'b1, 9'd30);

        // Case 5: Verify write-back of evicted dirty block
        if (dut.ram.memory[1] !== 9'd20 || dut.ram.memory[0] !== 9'd99) begin
            failed = 1;
            $display("FAIL (Case 5): expected RAM[1:0] = {20, 99}, got {%0d, %0d}",
                     dut.ram.memory[1], dut.ram.memory[0]);
        end

        if (!failed)
            $display("PASS: CACHE");

        $finish;
    end
endmodule
