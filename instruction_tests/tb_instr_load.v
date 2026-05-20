`timescale 1ns / 1ps

module tb_instr_load();
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
        input [8:0] set_r2_addr,
        input [8:0] set_mem_value,
        input [8:0] expected_r1,
        input [8:0] expected_out
    );
        begin
            reset = 1'b1;
            #PERIOD;
            reset = 1'b0;

            force dut.IFID_instruction = forced_instruction;

            dut.decode_stage.register.r2.out = set_r2_addr;
            dut.memory_stage.data_cache.ram.memory[set_r2_addr] = set_mem_value;

            @(posedge clock);
            #1;
            release dut.IFID_instruction;

            // wait for instruction to reach memory
            @(posedge clock);
            @(posedge clock);

            // wait for cache to finish
            wait(dut.memory_stage.data_cache.ready == 1'b1);
            
            // wait for data to get written back
            @(posedge clock);
            @(posedge clock);

            @(posedge clock);
            #1;

            if (dut.decode_stage.register.r1.out != expected_r1) begin
                failed = 1;
                $display("FAIL (LOAD case %0d): r1.out = %0d, expected %0d", case_num, dut.decode_stage.register.r1.out, expected_r1);
            end
            if (out != expected_out) begin
                failed = 1;
                $display("FAIL (LOAD case %0d): out = %0d, expected %0d", case_num, out, expected_out);
            end
            if (dut.decode_stage.register.flags_reg.out != 9'b000000000) begin
                failed = 1;
                $display("FAIL (LOAD case %0d): flags_reg changed to %b", case_num, dut.decode_stage.register.flags_reg.out);
            end
        end
    endtask

    initial begin
        failed = 0;

        // load r1, (r2): opcode 000, func 01, rA=r1, rB=r2
        // instr = 000 01 01 10

        run_case(1, 9'b000010110, 9'd1, 9'd3,         9'd3,         9'd3);
        run_case(2, 9'b000010110, 9'd0, 9'b111111001, 9'b111111001, 9'b111111001);
        run_case(3, 9'b000010110, 9'd7, 9'd0,         9'd0,         9'd0);

        if (!failed)
            $display("PASS: LOAD");
        $stop;
    end
endmodule
