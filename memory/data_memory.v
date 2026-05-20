`timescale 1ns / 1ps

module data_memory(
    output reg [17:0] out,
    input wire clock,
    input wire reset,
    input wire enable, // instruction needs to access memory
    input wire read_write, // 0 for read, 1 for write
    input wire [7:0] address,
    input wire [17:0] write_data
);

    // Physical memory is 512 x 9-bit words.
    // Logical accesses are still 256 x 18-bit blocks using the 8-bit address.
    reg [8:0] memory[511:0];

    wire [8:0] word0_address = {address, 1'b0};
    wire [8:0] word1_address = {address, 1'b1};

    integer i;

    initial begin
        for (i = 0; i < 512; i = i + 1) begin
            memory[i] = 9'd0;
        end
    end

    // one access completes per cycle while enable is held high.
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            out <= 18'b0;
        end else if (enable) begin
            if (read_write) begin
                memory[word1_address] <= write_data[17:9];
                memory[word0_address] <= write_data[8:0];
            end else begin
                out <= {memory[word1_address], memory[word0_address]};
            end
        end
    end
endmodule
