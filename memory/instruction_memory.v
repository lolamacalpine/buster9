`timescale 1ns / 1ps

module instruction_memory(
    output wire [8:0] out,
    input wire [8:0] address
);

    reg [8:0] memory[511:0];

    initial begin
        // Insert program here
        memory[0]  = 9'b000000000;
    end

    assign out = memory[address];

endmodule
