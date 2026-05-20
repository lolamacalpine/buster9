`timescale 1ns / 1ps

module tb_load_stall();
    reg clock;
    reg [1:0] IDEX_dest_reg, IFID_rA, IFID_rB;
    reg IDEX_reg_write_src;
    reg IFID_reads_reg0, IFID_reads_reg1;
    wire stall;
    integer failed;

    load_stall dut(
        .IDEX_dest_reg(IDEX_dest_reg),
        .IFID_rA(IFID_rA),
        .IFID_rB(IFID_rB),
        .IDEX_reg_write_src(IDEX_reg_write_src),
        .IFID_reads_reg0(IFID_reads_reg0),
        .IFID_reads_reg1(IFID_reads_reg1),
        .stall(stall)
    );

    parameter PERIOD = 10;
    initial clock = 1'b0;
    always #(PERIOD/2) clock = ~clock;

    task run_case (
        input integer case_num,
        input in_IDEX_reg_write_src,
        input [1:0] in_IDEX_dest_reg,
        input [1:0] in_IFID_rA,
        input [1:0] in_IFID_rB,
        input in_reads_reg0,
        input in_reads_reg1,
        input exp_stall
    );
        begin
            IDEX_reg_write_src = in_IDEX_reg_write_src;
            IDEX_dest_reg = in_IDEX_dest_reg;
            IFID_rA = in_IFID_rA;
            IFID_rB = in_IFID_rB;
            IFID_reads_reg0 = in_reads_reg0;
            IFID_reads_reg1 = in_reads_reg1;

            @(posedge clock);
            #1;

            if (stall !== exp_stall) begin
                failed = 1;
                $display("FAIL (Case %0d): expected stall = %b, got %b", 
                         case_num, exp_stall, stall);
            end
            
            #1;
        end
    endtask

    initial begin
        failed = 0;

        // Case 1: ALU instruction (write_src == 0), registers match. Should not stall.
        run_case(1, 1'b0, 2'b01, 2'b01, 2'b10, 1'b1, 1'b1, 1'b0);

        // Case 2: Load instruction (write_src == 1), but registers don't match. Should not stall.
        run_case(2, 1'b1, 2'b00, 2'b01, 2'b10, 1'b1, 1'b1, 1'b0);

        // Case 3: Load instruction, matches rA and read0 used. Should stall.
        run_case(3, 1'b1, 2'b01, 2'b01, 2'b10, 1'b1, 1'b1, 1'b1);

        // Case 4: Load instruction, matches rB and read1 used. Should stall.
        run_case(4, 1'b1, 2'b10, 2'b01, 2'b10, 1'b1, 1'b1, 1'b1);

        // Case 5: Load instruction, matches both rA and rB, both reads used. Should stall.
        run_case(5, 1'b1, 2'b11, 2'b11, 2'b11, 1'b1, 1'b1, 1'b1);

        // Case 6: Load matches rA bits but instruction does not use read0 (e.g. li opcode field). No stall.
        run_case(6, 1'b1, 2'b01, 2'b01, 2'b10, 1'b0, 1'b1, 1'b0);

        // Case 7: Load matches rB bits but instruction does not use read1 (e.g. addi). No stall.
        run_case(7, 1'b1, 2'b10, 2'b01, 2'b10, 1'b1, 1'b0, 1'b0);

        if (!failed)
            $display("PASS: LOAD STALL");
        $finish;
    end
endmodule