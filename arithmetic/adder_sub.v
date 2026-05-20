`timescale 1ns / 1ps

module adder_sub(
    output wire [8:0] result,
    output wire cout, vout,
    input wire [8:0] a, b,
    input wire sub_mode //1 for subtraction, 0 for addition
    );

    wire [8:0] b_select;
    assign b_select = b ^ {9{sub_mode}}; //inverts b if sub_mode=1
    
    //add a+b
    adder arithmetic (.result(result), .cout(cout), .a(a), .b(b_select), .cin(sub_mode)); //add sub_mode as cin complete two's complement

    // Overflow logic
    assign vout = ~(a[8] ^ b_select[8]) & (a[8] ^ result[8]);
endmodule
