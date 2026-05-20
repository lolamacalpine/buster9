`timescale 1ns / 1ps

module memory(
    output [8:0] read_data,
    output ready,
    input clock,
    input reset,
    input [8:0] rA_out, rB_out,
    input [1:0] mem_access
    );
    
    wire [8:0] mem_address;
    wire mem_enable = (mem_access != 2'b00);
    wire mem_write = (mem_access == 2'b10);
    wire [8:0] cache_data;

    assign cache_data = (mem_enable && mem_write) ? rB_out : 9'bz;
    assign read_data = (mem_enable && !mem_write) ? cache_data : 9'b0;
    
    // determine if load or st instruction for memory
    mux_2x1 data_mem_addr(
        .out(mem_address),
        .in0(rB_out),
        .in1(rA_out),
        .select(mem_write)
    );
    
    // Cache-backed data memory.
    cache data_cache(
        .ready(ready),
        .data(cache_data),
        .clock(clock),
        .reset(reset),
        .enable(mem_enable),
        .read_write(mem_write),
        .address(mem_address)
    );
    
endmodule
