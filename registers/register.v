`timescale 1ns / 1ps

module register(
    output reg [8:0] out,
    input wire clock, enable, reset,
    input wire [8:0] in
    );
    
    always @(posedge clock or posedge reset) begin //execute when clock or reset changes 0 -> 1
        if (reset) 
            out <= 9'b0; //set output as 0 if reset if high
        else if (enable)
            out <= in; //set output as input if enable is high and reset is low
    end

    
endmodule
