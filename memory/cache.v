`timescale 1ns / 1ps

module cache(
    output reg ready,
    inout wire [8:0] data,
    input wire clock,
    input wire reset,
    input wire enable, // instruction needs to access memory
    input wire read_write, // 0 for read, 1 for write
    input wire [8:0] address
);

    // Preliminary entry format:
    // {dirty[1], valid[1], tag[3:0], data[17:0]}
    // data[17:9] = first word (offset 1), data[8:0] = second word (offset 0)
    reg [23:0] cache_array [15:0];

    // tag=4, index=4, offset=1
    wire [3:0] tag = address[8:5];
    wire [3:0] index = address[4:1];
    wire offset = address[0];

    // split cache line into components
    wire [23:0] cache_line = cache_array[index];
    wire cache_dirty = cache_line[23];
    wire cache_valid = cache_line[22];
    wire [3:0] cache_tag = cache_line[21:18];
    wire [17:0] cache_data = cache_line[17:0];
    wire [8:0] cache_word0 = cache_data[8:0];
    wire [8:0] cache_word1 = cache_data[17:9];
    wire [8:0] cache_word = offset ? cache_word1 : cache_word0;

    wire hit = cache_valid && (cache_tag == tag);
    wire write_back = cache_valid && cache_dirty && !hit;
    // Might be a better way to make this combinatorial
    wire ready_next = (state == IDLE) ? (!enable || hit) : 1'b0;
    wire drive_data = enable && !read_write && (state == IDLE) && hit;

    // data bus is driven by cache on read hit, driven by CPU on write
    assign data = drive_data ? cache_word : 9'bz;

    // FSM states
    parameter IDLE = 2'b00, WRITE = 2'b01, ALLOCATE = 2'b10;
    reg [1:0] state;

    always @(reset or state or enable or hit) begin
        if (reset) begin
            ready = 1'b1;
        end
        else begin
            ready = ready_next;
        end
    end

    //ram controls
    reg mem_enable, mem_read_write;
    reg [7:0] mem_address;
    reg [17:0] mem_write_data;
    reg wait_count;
    wire [17:0] mem_read_data;
    
    data_memory ram(
        .out(mem_read_data),
        .clock(clock),
        .reset(reset),
        .enable(mem_enable),
        .address(mem_address),
        .read_write(mem_read_write),
        .write_data(mem_write_data)
    );

    // initialize cache lines to 0
    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            cache_array[i] = 24'b0;
        end
    end
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            mem_enable <= 1'b0;
            mem_read_write <= 1'b0;
            for (i = 0; i < 16; i = i + 1) begin
                cache_array[i] <= 24'b0;
            end
        end
        else begin
            case (state)
                IDLE: begin
                    wait_count <= 1'b0;
                    if (!enable) begin
                        mem_enable <= 1'b0;
                    end
                    // hit
                    else if (hit) begin
                        if (read_write) begin
                            cache_array[index] <= offset
                                ? {1'b1, 1'b1, tag, data, cache_line[8:0]}
                                : {1'b1, 1'b1, tag, cache_line[17:9], data};
                        end
                    end
                    // miss
                    else begin
                        mem_enable <= 1'b1;
                        if (write_back) begin // dirty eviction
                            state <= WRITE;
                            mem_read_write <= 1'b1;
                            mem_address <= {cache_tag, index};
                            mem_write_data <= cache_data;
                        end
                        else begin // clean miss, allocate directly
                            state <= ALLOCATE;
                            mem_read_write <= 1'b0;
                            mem_address <= address[8:1];
                        end
                    end
                end
                WRITE: begin
                    if (wait_count == 1) begin
                        state <= ALLOCATE;
                        mem_enable <= 1'b1;
                        mem_read_write <= 1'b0;
                        mem_address <= address[8:1]; // update address
                    end
                    wait_count <= wait_count + 1;
                end
                ALLOCATE: begin
                    if (wait_count == 1) begin // memory finished
                        state <= IDLE;
                        mem_enable <= 1'b0;
                        if (read_write == 1) begin // write miss
                            cache_array[index] <= offset
                                ? {1'b1, 1'b1, tag, data, mem_read_data[8:0]}
                                : {1'b1, 1'b1, tag, mem_read_data[17:9], data};
                        end
                        else begin // read miss
                            cache_array[index] <= {1'b0, 1'b1, tag, mem_read_data};
                        end
                    end
                    wait_count <= wait_count + 1;
                end
            endcase
        end
    end
endmodule
