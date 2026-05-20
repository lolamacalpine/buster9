`timescale 1ns / 1ps

module load_stall(
    input [1:0] IDEX_dest_reg, EXMEM_dest_reg, ID_rA, ID_rB,
    input IDEX_reg_write_src, EXMEM_reg_write_src,
    input ID_reads_reg0, ID_reads_reg1,
    output reg stall
    );
    always @(IDEX_dest_reg or EXMEM_dest_reg or ID_rA or ID_rB or
             IDEX_reg_write_src or EXMEM_reg_write_src or ID_reads_reg0 or ID_reads_reg1) begin
        stall = 1'b0;
        // IDEX load-use hazard. Detects a load instruction and if the dest register is an operand.
        if ((IDEX_reg_write_src == 1'b1) &
            ((ID_reads_reg0 & (IDEX_dest_reg == ID_rA)) |
             (ID_reads_reg1 & (IDEX_dest_reg == ID_rB))))
            stall = 1'b1;
        // EXMEM load-use hazard (load still pending one stage later due to cache).
        else if ((EXMEM_reg_write_src == 1'b1) &
                 ((ID_reads_reg0 & (EXMEM_dest_reg == ID_rA)) |
                  (ID_reads_reg1 & (EXMEM_dest_reg == ID_rB))))
            stall = 1'b1;
    end
endmodule