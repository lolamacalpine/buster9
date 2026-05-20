`timescale 1ns / 1ps

module register_file(
    output wire [8:0] out0, out1, flags_out,
    input wire clock, reset, enable, flags_write,
    input wire [1:0] write, read0, read1,
    input wire [8:0] in, flags_in
    );
    
    wire [3:0] select;
    wire [8:0] iout0, iout1, iout2, iout3;
    wire [8:0] flags_reg_out;
    
    decoder_2x4 write_decode(.out(select), .in(write), .enable(enable)); //determine the register to write to
    
    // write to appropriate register on the main clock edge.
    register r0 (.clock(clock),.reset(reset), .enable(select[0]), .in(in), .out(iout0));
    register r1 (.clock(clock),.reset(reset), .enable(select[1]), .in(in), .out(iout1));
    register r2 (.clock(clock),.reset(reset), .enable(select[2]), .in(in), .out(iout2));
    register r3 (.clock(clock),.reset(reset), .enable(select[3]), .in(in), .out(iout3));
    
    //read from appropriate register
    wire [8:0] read0_data;
    wire [8:0] read1_data;
    mux_4x1 result0 (.out(read0_data),.in0(iout0),.in1(iout1),.in2(iout2),.in3(iout3),.select(read0));
    mux_4x1 result1 (.out(read1_data),.in0(iout0),.in1(iout1),.in2(iout2),.in3(iout3),.select(read1));
    
    // internal forwarding for same-cycle write/read hazards
    assign out0 = (enable && (write == read0)) ? in : read0_data;
    assign out1 = (enable && (write == read1)) ? in : read1_data;

    //write the updated value of the flag register
    register flags_reg (.clock(clock),.reset(reset), .enable(flags_write), .in(flags_in), .out(flags_reg_out));

    // internal forwarding for same-cycle flag write/read hazards
    assign flags_out = flags_write ? flags_in : flags_reg_out;
endmodule
