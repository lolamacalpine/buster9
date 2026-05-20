`timescale 1ns / 1ps


module forwarding(
    input forward_enable, EXMEM_reg_write, MEMWB_reg_write,
    input [1:0] IDEX_rA, IDEX_rB, EXMEM_dest_reg, MEMWB_dest_reg,
    output reg [1:0] forward_a, forward_b
    );
    always @(forward_enable or EXMEM_reg_write or MEMWB_reg_write or IDEX_rA or IDEX_rB or EXMEM_dest_reg or MEMWB_dest_reg) begin
        // default (no forwarding)
        forward_a = 2'b00;
        forward_b = 2'b00;
        
        /*
        forward_a/b = 00: no forwarding
        forward_a/b = 01: forward from mem/write back
        forward_a/b = 10: forward from memory
        */
        
        if (forward_enable) begin
            //forward detection for rA
            //opt. 1: forward from ex/memory - prioritize this
            if (EXMEM_reg_write & (EXMEM_dest_reg == IDEX_rA)) begin
                forward_a = 2'b10;
            end
            //opt. 2: forward from mem/write back if not memory
            else if (MEMWB_reg_write & (MEMWB_dest_reg == IDEX_rA)) begin
                forward_a = 2'b01;
            end

            //forward detection for rB
            //opt. 1: forward from ex/memory - prioritize this
            if (EXMEM_reg_write & (EXMEM_dest_reg == IDEX_rB)) begin
                forward_b = 2'b10;
            end
            //opt. 2: forward from mem/write back if not memory
            else if (MEMWB_reg_write & (MEMWB_dest_reg == IDEX_rB)) begin
                forward_b = 2'b01;
            end 
        end
    end
endmodule
