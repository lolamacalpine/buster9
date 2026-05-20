`timescale 1ns / 1ps

// Program 2: f = x*y - 4
module ram_prog2(
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
        
        // High-priority data for PROG2 - All data
        memory[0] = 9'b111111001; // y = -7
        memory[1] = 9'b000000011; // x = 3
        memory[2] = 9'b000000011; // Result write location = f
        memory[3] = 9'b000000000; // Available
        memory[4] = 9'b000000000; // Available
        memory[5] = 9'b000000000; // Available
        memory[6] = 9'b000000000; // Available
        memory[7] = 9'b000000000; // Available
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
