`timescale 1ns / 1ps

module control(
    output reg reg_write, reg_read0_src, flags_write, stop,
    output reg reads_reg0, reads_reg1,
    output reg reg_write_src,
    output reg [1:0] mem_access, pc_src, alu_src, branch_cond,
    output reg [2:0] alu_code,
    input wire [2:0] opcode,
    input wire func0, func1, noop
    );
    
    always @(opcode or func0 or func1 or noop) begin
        // defaults
        reg_write = 0;
        reg_write_src = 1'b0;
        mem_access = 2'b00;
        alu_src = 2'b00;
        reg_read0_src = 0;
        alu_code = 3'b000;
        pc_src = 2'b00;
        branch_cond = 2'b00;
        flags_write = 0;
        stop = 0;
        reads_reg0 = 1'b0;
        reads_reg1 = 1'b0;

        case (opcode)
            //j
            3'b111: begin
                pc_src = 2'b01;
            end
            
            //jnz
            3'b110: begin
                pc_src = 2'b01;
                branch_cond = 2'b10;
            end
            
            //jge
            3'b101: begin
                pc_src = 2'b01;
                branch_cond = 2'b01;
            end

            
            //jr, srl
            3'b100: begin
                case(func0)
                    //srl
                    1'b0: begin
                        reg_write = 1;
                        flags_write = 1;
                        reg_read0_src = 1;
                        alu_src = 2'b01;
                        alu_code = 3'b110;
                        reads_reg0 = 1'b1;
                    end
                    //jr
                    1'b1: begin
                        reg_read0_src = 1;
                        pc_src = 2'b10;
                        reads_reg0 = 1'b1;
                    end
                endcase
            end
            
            //ori, sll
            3'b011: begin
                case(func0)
                    //ori
                    1'b0: begin
                        reg_write = 1;
                        flags_write = 1;
                        reg_read0_src = 1;
                        alu_src = 2'b10;
                        alu_code = 3'b100;
                        reads_reg0 = 1'b1;
                    end
                    //sll
                    1'b1: begin
                        reg_write = 1;
                        flags_write = 1;
                        reg_read0_src = 1;
                        alu_src = 2'b01;
                        alu_code = 3'b101;
                        reads_reg0 = 1'b1;
                    end
                endcase
            end
            
            //addi, li
            3'b010: begin
                case(func0)
                    //li
                    1'b0: begin
                        reg_write = 1;
                        reg_read0_src = 1;
                        alu_src = 2'b10;
                        alu_code = 3'b111;
                    end
                    //addi
                    1'b1: begin
                        reg_write = 1;
                        flags_write = 1;
                        reg_read0_src = 1;
                        alu_src = 2'b01;
                        reads_reg0 = 1'b1;
                    end
                endcase
            end
            
            //sub, and, not, cmp
            3'b001: begin
                case({func0,func1})
                    //sub
                    2'b00: begin
                        reg_write = 1;
                        flags_write = 1;
                        alu_code = 3'b001;
                        reads_reg0 = 1'b1;
                        reads_reg1 = 1'b1;
                    end
                    //and
                    2'b01: begin
                        reg_write = 1;
                        flags_write = 1;
                        alu_code = 3'b010;
                        reads_reg0 = 1'b1;
                        reads_reg1 = 1'b1;
                    end
                    //not
                    2'b10: begin
                        reg_write = 1;
                        flags_write = 1;
                        alu_code = 3'b011;
                        reads_reg0 = 1'b1;
                    end
                    //cmp
                    2'b11: begin
                        flags_write = 1;
                        alu_code = 3'b001;
                        reads_reg0 = 1'b1;
                        reads_reg1 = 1'b1;
                    end
                endcase
            end
            
            //stop, load, st, add
            3'b000: begin
                case({func0,func1})
                    //stop
                    2'b00: begin
                        if (!noop) begin
                            stop = 1;
                        end
                        //if noop==1, default values (all zeroes)
                    end
                    //load
                    2'b01: begin
                        reg_write = 1;
                        reg_write_src = 1'b1;
                        mem_access = 2'b01;
                        reads_reg1 = 1'b1;
                    end
                    //st 
                    2'b10: begin
                        mem_access = 2'b10;
                        reads_reg0 = 1'b1;
                        reads_reg1 = 1'b1;
                    end
                    //add 
                    2'b11: begin
                        reg_write = 1;
                        flags_write = 1;
                        reads_reg0 = 1'b1;
                        reads_reg1 = 1'b1;
                    end
                endcase
            end
        endcase
    end
endmodule
