`timescale 1ns / 1ps

module tb_execute();
    reg [8:0] rA_out, rB_out;
    reg [8:0] sext_imm, zext_imm;
    reg [1:0] alu_src;
    reg [2:0] alu_code;
    wire [8:0] alu_result, alu_flags_out;
    integer failed;

    execute dut(
        .rA_out(rA_out),
        .rB_out(rB_out),
        .sext_imm(sext_imm),
        .zext_imm(zext_imm),
        .alu_src(alu_src),
        .alu_code(alu_code),
        .alu_result(alu_result),
        .alu_flags_out(alu_flags_out)
    );

    parameter PERIOD = 10;

    task run_case (
        input integer case_num,
        input [8:0] in_rA_out,
        input [8:0] in_rB_out,
        input [8:0] in_sext_imm,
        input [8:0] in_zext_imm,
        input [1:0] in_alu_src,
        input [2:0] in_alu_code,
        input [8:0] exp_alu_result
    );
        begin
            rA_out = in_rA_out;
            rB_out = in_rB_out;
            sext_imm = in_sext_imm;
            zext_imm = in_zext_imm;
            alu_src = in_alu_src;
            alu_code = in_alu_code;

            #PERIOD;

            if (alu_result !== exp_alu_result) begin
                failed = 1;
                $display("FAIL (Case %0d): expected alu_result = %b, got %b",
                         case_num, exp_alu_result, alu_result);
            end
        end
    endtask

    initial begin
        failed = 0;

        // Case 1: add using rB source
        run_case(1, 9'd5, 9'd7, 9'd0, 9'd0, 2'b00, 3'b000, 9'd12);

        // Case 2: addi style add using sign-extended immediate
        run_case(2, 9'd10, 9'd0, 9'd3, 9'd0, 2'b01, 3'b000, 9'd13);

        // Case 3: ori style OR using zero-extended immediate
        run_case(3, 9'b100000001, 9'd0, 9'd0, 9'b000000110, 2'b10, 3'b100, 9'b100000111);

        // Case 4: sll using immediate shift amount
        run_case(4, 9'b000000011, 9'd0, 9'd2, 9'd0, 2'b01, 3'b101, 9'b000001100);

        // Case 5: li path through ALU select 111, zext immediate input
        run_case(5, 9'd0, 9'd0, 9'd0, 9'd5, 2'b10, 3'b111, 9'd5);

        if (!failed)
            $display("PASS: EXECUTE STAGE");
        $finish;
    end
endmodule
