`timescale 1ns / 1ps

module tb_bht;

    parameter integer M_VAL = 16; // 16, 32, or 64
    parameter integer N_VAL = 2; // 1 or 2

    // inputs
    reg clock;
    reg reset;
    reg [8:0] pc;
    reg outcome;
    reg update_enable;

    // output
    wire prediction;

    integer infile, status;
    integer total_branches = 0;
    integer correct_predictions = 0;
    reg [9:0] file_pc; // pc from the input file

    bht #(
        .M(M_VAL),
        .N(N_VAL)
    ) uut (
        .clock(clock),
        .reset(reset),
        .pc(pc),
        .outcome(outcome),
        .update_enable(update_enable),
        .prediction(prediction)
    );

    parameter PERIOD = 10; // clock period
    initial clock = 1'b0;
    always #(PERIOD/2) clock = ~clock;

    initial begin
        // initial values
        reset = 1;
        update_enable = 0;
        pc = 0;
        outcome = 0;

        // open file
        infile = $fopen("out2.txt", "r");

        // reset
        #PERIOD
        reset = 0;

        // read file
        while (!$feof(infile)) begin
            // read pc and outcome
            status = $fscanf(infile, "%d\n", file_pc);
            status = $fscanf(infile, "%d\n", outcome);

            total_branches = total_branches + 1;
            pc = file_pc[8:0];

            // compare prediction and outcome
            if (prediction == outcome) begin
                correct_predictions = correct_predictions + 1;
            end

            // update bht
            update_enable = 1;
            @(posedge clock);
            update_enable = 0;
        end

        // results
        $display("Total branches: %d", total_branches);
        $display("Correct predictions: %d", correct_predictions);
        $display("Accuracy: %f%%", (correct_predictions * 100.0) / total_branches);

        $fclose(infile);
        $finish;
    end

endmodule
