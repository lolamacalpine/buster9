`timescale 1ns / 1ps

// Program 3: String Comparison
module ram_prog3(
    output reg [17:0] out,
    output reg ready,
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
    
    //FSM states
    parameter IDLE = 2'b00, WAIT = 2'b01, DONE = 2'b10;
    reg [1:0] state;
    reg [1:0] wait_count;
    integer i;
    
    initial begin
        // Default all 9-bit physical words to 0.
        for (i = 0; i < 512; i = i + 1) begin
            memory[i] = 9'd0;
        end
        
        // High-priority data for PROG3
        memory[0] = 9'd8;         // str1 start address
        memory[1] = 9'd23;        // str2 start address
        memory[2] = 9'h0AA;       // Constant 0xAA
        memory[3] = 9'b000000000; // Result write location
        memory[4] = 9'b000000000; // Available
        memory[5] = 9'b000000000; // Available
        memory[6] = 9'b000000000; // Available
        memory[7] = 9'b000000000; // Available

        // First string "PeasAndCarrots"
        memory[8]  = 9'b001010000; // P
        memory[9]  = 9'b001100101; // e
        memory[10] = 9'b001100001; // a
        memory[11] = 9'b001110011; // s
        memory[12] = 9'b001000001; // A
        memory[13] = 9'b001101110; // n
        memory[14] = 9'b001100100; // d
        memory[15] = 9'b001000011; // C
        memory[16] = 9'b001100001; // a
        memory[17] = 9'b001110010; // r
        memory[18] = 9'b001110010; // r
        memory[19] = 9'b001101111; // o
        memory[20] = 9'b001110100; // t
        memory[21] = 9'b001110011; // s
        memory[22] = 9'b000000000; // null terminator
    end
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            ready <= 1'b0;
            wait_count <= 2'b0;
            out <= 18'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    ready <= 1'b0;
                    if (enable) begin
                        state <= WAIT;
                        wait_count <= 2'b00;
                    end
                end
                WAIT: begin
                    ready <= 1'b0;
                    if (wait_count == 2'b01) begin
                        state <= DONE;
                    end
                    else begin
                        wait_count <= wait_count + 1; // wait for 2 cycles
                    end
                end
                DONE: begin
                    ready <= 1'b1;
                    if (read_write == 1) begin // write instruction
                        memory[word1_address] <= write_data[17:9];
                        memory[word0_address] <= write_data[8:0];
                    end
                    else begin //read instruction
                        out <= {memory[word1_address], memory[word0_address]};
                    end
                    state <= IDLE; // reset to idle
                end
            endcase
        end
    end
endmodule
