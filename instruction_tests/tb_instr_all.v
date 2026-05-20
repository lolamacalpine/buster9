`timescale 1ns / 1ps

module tb_instr_all();
    tb_instr_addi tb_addi();
    tb_instr_add  tb_add();
    tb_instr_sub  tb_sub();
    tb_instr_stop tb_stop();
    tb_instr_load tb_load();
    tb_instr_st   tb_st();
    tb_instr_and  tb_and();
    tb_instr_not  tb_not();
    tb_instr_cmp  tb_cmp();
    tb_instr_li   tb_li();
    tb_instr_ori  tb_ori();
    tb_instr_sll  tb_sll();
    tb_instr_srl  tb_srl();
    tb_instr_jr   tb_jr();
    tb_instr_jge  tb_jge();
    tb_instr_jnz  tb_jnz();
    tb_instr_j    tb_j();
endmodule
