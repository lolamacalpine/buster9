`timescale 1ns / 1ps

module tb_control();
    reg [2:0] opcode; 
    reg func0, func1, noop; 
    integer failed;

    wire reg_write, reg_write_src, reg_read0_src, flags_write, stop; 
    wire reads_reg0, reads_reg1;
    wire [1:0] mem_access, pc_src; 
    wire [1:0] alu_src, branch_cond; 
    wire [2:0] alu_code; 

    control SUT( 
        .opcode(opcode), 
        .func0(func0), 
        .func1(func1),
        .noop(noop), 
        .reads_reg0(reads_reg0),
        .reads_reg1(reads_reg1),
        .reg_write(reg_write), 
        .reg_write_src(reg_write_src), 
        .mem_access(mem_access), 
        .reg_read0_src(reg_read0_src), 
        .alu_src(alu_src), 
        .alu_code(alu_code), 
        .branch_cond(branch_cond), 
        .pc_src(pc_src), 
        .flags_write(flags_write), 
        .stop(stop)
    ); 

    parameter PERIOD = 10;    

    task check_control(
        input [2:0] in_opcode,
        input in_func0,
        input in_func1, 
        input exp_reg_write,
        input exp_reg_write_src,
        input [1:0] exp_mem_access,
        input exp_reg_read0_src, 
        input [1:0] exp_alu_src, 
        input [2:0] exp_alu_code,
        input [1:0] exp_branch_cond,
        input [1:0] exp_pc_src,
        input exp_flags_write,
        input exp_stop,
        input in_noop
    );
        begin 
            opcode = in_opcode; func0 = in_func0; func1 = in_func1; noop = in_noop;
            #PERIOD;
            if (reg_write !== exp_reg_write) begin failed = 1; $display("reg_write failed for opcode %b func0 %b func1 %b. Got %b, expected %b", in_opcode, in_func0, in_func1, reg_write, exp_reg_write); end
            if (reg_write_src !== exp_reg_write_src) begin failed = 1; $display("reg_write_src failed for opcode %b func0 %b func1 %b. Got %b, expected %b", in_opcode, in_func0, in_func1, reg_write_src, exp_reg_write_src); end
            if (mem_access !== exp_mem_access) begin failed = 1; $display("mem_access failed for opcode %b func0 %b func1 %b. Got %b, expected %b", in_opcode, in_func0, in_func1, mem_access, exp_mem_access); end
            if (reg_read0_src !== exp_reg_read0_src) begin failed = 1; $display("reg_read0_src failed for opcode %b func0 %b func1 %b. Got %b, expected %b", in_opcode, in_func0, in_func1, reg_read0_src, exp_reg_read0_src); end
            if (alu_src !== exp_alu_src) begin failed = 1; $display("alu_src failed for opcode %b func0 %b func1 %b. Got %b, expected %b", in_opcode, in_func0, in_func1, alu_src, exp_alu_src); end
            if (alu_code !== exp_alu_code) begin failed = 1; $display("alu_code failed for opcode %b func0 %b func1 %b. Got %b, expected %b", in_opcode, in_func0, in_func1, alu_code, exp_alu_code); end
            if (branch_cond !== exp_branch_cond) begin failed = 1; $display("branch_cond failed for opcode %b func0 %b func1 %b. Got %b, expected %b", in_opcode, in_func0, in_func1, branch_cond, exp_branch_cond); end
            if (pc_src !== exp_pc_src) begin failed = 1; $display("pc_src failed for opcode %b func0 %b func1 %b. Got %b, expected %b", in_opcode, in_func0, in_func1, pc_src, exp_pc_src); end
            if (flags_write !== exp_flags_write) begin failed = 1; $display("flags_write failed for opcode %b func0 %b func1 %b. Got %b, expected %b", in_opcode, in_func0, in_func1, flags_write, exp_flags_write); end
            if (stop !== exp_stop) begin failed = 1; $display("stop failed for opcode %b func0 %b func1 %b noop %b. Got %b, expected %b", in_opcode, in_func0, in_func1, noop, stop, exp_stop); end
        
        end 
    endtask
    
    initial begin 
        failed = 0;
        check_control(3'b000, 0, 0, 0, 1'b0, 2'b00, 0, 2'b00, 3'b000, 2'b00, 2'b00, 0, 1, 0); //stop (noop=0)
        check_control(3'b000, 0, 0, 0, 1'b0, 2'b00, 0, 2'b00, 3'b000, 2'b00, 2'b00, 0, 0, 1); //noop (noop=1)
        check_control(3'b000, 0, 1, 1, 1'b1, 2'b01, 0, 2'b00, 3'b000, 2'b00, 2'b00, 0, 0, 0); //load
        check_control(3'b000, 1, 0, 0, 1'b0, 2'b10, 0, 2'b00, 3'b000, 2'b00, 2'b00, 0, 0, 0); //st
        check_control(3'b000, 1, 1, 1, 1'b0, 2'b00, 0, 2'b00, 3'b000, 2'b00, 2'b00, 1, 0, 0); //add
        check_control(3'b001, 0, 0, 1, 1'b0, 2'b00, 0, 2'b00, 3'b001, 2'b00, 2'b00, 1, 0, 0); //sub
        check_control(3'b001, 0, 1, 1, 1'b0, 2'b00, 0, 2'b00, 3'b010, 2'b00, 2'b00, 1, 0, 0); //and
        check_control(3'b001, 1, 0, 1, 1'b0, 2'b00, 0, 2'b00, 3'b011, 2'b00, 2'b00, 1, 0, 0); //not
        check_control(3'b001, 1, 1, 0, 1'b0, 2'b00, 0, 2'b00, 3'b001, 2'b00, 2'b00, 1, 0, 0); //cmp
        check_control(3'b010, 0, 0, 1, 1'b0, 2'b00, 1, 2'b10, 3'b111, 2'b00, 2'b00, 0, 0, 0); //li
        check_control(3'b010, 1, 0, 1, 1'b0, 2'b00, 1, 2'b01, 3'b000, 2'b00, 2'b00, 1, 0, 0); //addi
        check_control(3'b011, 0, 0, 1, 1'b0, 2'b00, 1, 2'b10, 3'b100, 2'b00, 2'b00, 1, 0, 0); //ori
        check_control(3'b011, 1, 0, 1, 1'b0, 2'b00, 1, 2'b01, 3'b101, 2'b00, 2'b00, 1, 0, 0); //sll
        check_control(3'b100, 0, 0, 1, 1'b0, 2'b00, 1, 2'b01, 3'b110, 2'b00, 2'b00, 1, 0, 0); //srl
        check_control(3'b100, 1, 0, 0, 1'b0, 2'b00, 1, 2'b00, 3'b000, 2'b00, 2'b10, 0, 0, 0); //jr
        check_control(3'b101, 0, 0, 0, 1'b0, 2'b00, 0, 2'b00, 3'b000, 2'b01, 2'b01, 0, 0, 0); //jge
        check_control(3'b110, 0, 0, 0, 1'b0, 2'b00, 0, 2'b00, 3'b000, 2'b10, 2'b01, 0, 0, 0); //jnz
        check_control(3'b111, 0, 0, 0, 1'b0, 2'b00, 0, 2'b00, 3'b000, 2'b00, 2'b01, 0, 0, 0); //j
        if (!failed) begin
            $display("PASS control unit");
        end
        $finish; 
    end 
endmodule
