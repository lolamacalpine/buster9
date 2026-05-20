`timescale 1ns / 1ps

module tb_write_back();
    reg reg_write_src;
    reg [8:0] mem_out, alu_result;
    wire [8:0] reg_write_data;
    integer failed;

    write_back dut(
        .reg_write_src(reg_write_src),
        .mem_out(mem_out),
        .alu_result(alu_result),
        .reg_write_data(reg_write_data)
    );

    parameter PERIOD = 10;

    task run_case (
        input integer case_num,
        input in_reg_write_src,
        input [8:0] in_mem_out,
        input [8:0] in_alu_result,
        input [8:0] exp_reg_write_data
    );
        begin
            reg_write_src = in_reg_write_src;
            mem_out = in_mem_out;
            alu_result = in_alu_result;

            #PERIOD;

            if (reg_write_data !== exp_reg_write_data) begin
                failed = 1;
                $display("FAIL (Case %0d): expected reg_write_data = %b, got %b",
                         case_num, exp_reg_write_data, reg_write_data);
            end
        end
    endtask

    initial begin
        failed = 0;

        // Case 1: Write back ALU result
        run_case(1, 1'b0, 9'd12, 9'd34, 9'd34);

        // Case 2: Write back memory output
        run_case(2, 1'b1, 9'd12, 9'd34, 9'd12);

        if (!failed)
            $display("PASS: WRITEBACK STAGE");
        $finish;
    end
endmodule
