`timescale 1ns / 1ps

module bht(
    input wire clock, reset,
    input wire [8:0] pc,
    input wire outcome,
    input wire update_enable,
    output wire prediction // 0 = NT, 1 = T
    );

    parameter integer M = 64;
    parameter integer INDEX_BITS = $clog2(M);
    parameter integer N = 2;

    wire [INDEX_BITS-1:0] index = pc[INDEX_BITS-1:0];

    reg [N-1:0] bht [0:M-1];

    assign prediction = (N == 1) ? bht[index][0] : bht[index][1]; // Use MSB

    integer i;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            for (i = 0; i < M; i = i + 1)
                bht[i] <= (N==1) ? 1'b0 : 2'b01;
        end
        else if (update_enable) begin
            if (N==1) begin
                bht[index] <= outcome;
            end
            else begin
                if (outcome) begin
                    bht[index] <= (bht[index] == 2'b11) ? 2'b11 : (bht[index] + 1'b1);
                end
                else begin
                    bht[index] <= (bht[index] == 2'b00) ? 2'b00 : (bht[index] - 1'b1);
                end
            end
        end
    end
endmodule
