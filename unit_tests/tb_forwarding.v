`timescale 1ns / 1ps

module tb_forwarding();
    reg clock;
    reg forward_enable, EXMEM_reg_write, MEMWB_reg_write;
    reg [1:0] IDEX_rA, IDEX_rB, EXMEM_dest_reg, MEMWB_dest_reg;
    wire [1:0] forward_a, forward_b;
    integer failed;

    forwarding dut(
        .forward_enable(forward_enable),
        .EXMEM_reg_write(EXMEM_reg_write),
        .MEMWB_reg_write(MEMWB_reg_write),
        .IDEX_rA(IDEX_rA),
        .IDEX_rB(IDEX_rB),
        .EXMEM_dest_reg(EXMEM_dest_reg),
        .MEMWB_dest_reg(MEMWB_dest_reg),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    parameter PERIOD = 10;
    initial clock = 1'b0;
    always #(PERIOD/2) clock = ~clock;

    task run_case (
        input integer case_num,
        input in_forward_enable,
        input exp_EXMEM_reg_write,
        input exp_MEMWB_reg_write,
        input [1:0] in_IDEX_rA,
        input [1:0] in_IDEX_rB,
        input [1:0] exp_EXMEM_dest_reg,
        input [1:0] exp_MEMWB_dest_reg,
        input [1:0] exp_forward_a,
        input [1:0] exp_forward_b
    );
        begin
            forward_enable = in_forward_enable;
            EXMEM_reg_write = exp_EXMEM_reg_write;
            MEMWB_reg_write = exp_MEMWB_reg_write;
            IDEX_rA = in_IDEX_rA;
            IDEX_rB = in_IDEX_rB;
            EXMEM_dest_reg = exp_EXMEM_dest_reg;
            MEMWB_dest_reg = exp_MEMWB_dest_reg;

            @(posedge clock);
            #1;

            if (forward_a !== exp_forward_a || forward_b !== exp_forward_b) begin
                failed = 1;
                $display("FAIL (Case %0d): expected A/B = %b/%b, got %b/%b", 
                         case_num, exp_forward_a, exp_forward_b, forward_a, forward_b);
            end
            
            #1;
        end
    endtask

    initial begin
        failed = 0;

        // Case 1: No hazard
        run_case(1, 1'b1, 1'b0, 1'b0, 2'b00, 2'b01, 2'b10, 2'b11, 2'b00, 2'b00);

        // Case 2: EX/MEM hazard on rA (Outputs 10 on A)
        run_case(2, 1'b1, 1'b1, 1'b0, 2'b00, 2'b01, 2'b00, 2'b11, 2'b10, 2'b00);

        // Case 3: MEM/WB hazard on rB (Outputs 01 on B)
        run_case(3, 1'b1, 1'b0, 1'b1, 2'b00, 2'b01, 2'b10, 2'b01, 2'b00, 2'b01);

        // Case 4: Double hazard on rA (EX/MEM must win, Outputs 10 on A)
        run_case(4, 1'b1, 1'b1, 1'b1, 2'b11, 2'b01, 2'b11, 2'b11, 2'b10, 2'b00);

        // Case 5: Double hazard on rB (EX/MEM must win, Outputs 10 on B)
        run_case(5, 1'b1, 1'b1, 1'b1, 2'b00, 2'b10, 2'b10, 2'b10, 2'b00, 2'b10);

        // Case 6: Forwarding disabled, but hazards present
        run_case(6, 1'b0, 1'b1, 1'b1, 2'b00, 2'b01, 2'b00, 2'b01, 2'b00, 2'b00);

        if (!failed)
            $display("PASS: FORWARDING");
        $finish;
    end
endmodule