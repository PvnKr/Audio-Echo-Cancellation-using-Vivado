module echo_cancellation_tb;

    parameter DATA_WIDTH = 16;
    parameter TAP_LENGTH = 64;
    parameter CLK_PERIOD = 10;
    parameter SAMPLE_COUNT = 14970;

    reg clk;
    reg rst;
    reg signed [DATA_WIDTH-1:0] input_signal;
    reg signed [DATA_WIDTH-1:0]  echo_signal;
    wire signed [DATA_WIDTH-1:0] output_signal;

    reg signed [DATA_WIDTH-1:0] input_mem [0:SAMPLE_COUNT-1];
    reg signed [DATA_WIDTH-1:0] echo_mem  [0:SAMPLE_COUNT-1];
    integer i, outfile;

    // DUT Instance
    echo_cancellation #(
        .DATA_WIDTH(DATA_WIDTH),
        .TAP_LENGTH(TAP_LENGTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .input_signal(input_signal),
        .echo_signal(echo_signal),
        .output_signal(output_signal)
    );

    // Clock generation: 100 MHz
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Simulation sequence
    initial begin
        rst = 1;
        input_signal = 0;
        echo_signal = 0;
        #100;
        rst = 0;

        // Load input memory files
        $readmemh("echo_plus_audio.mem", input_mem);
        $readmemh("echo_only.mem", echo_mem);

        // Open output file
        outfile = $fopen("output.mem", "w");
        if (outfile == 0) begin
            $display("ERROR: Could not open output.mem");
            $finish;
        end

        // Feed samples at 8 kHz
        for (i = 0; i < SAMPLE_COUNT; i = i + 1) begin
            input_signal = input_mem[i];
            echo_signal  = echo_mem[i];
            #125_000;

            if (output_signal < 0)
                $fwrite(outfile, "%04x\n", output_signal + 16'h10000);
            else
                $fwrite(outfile, "%04x\n", output_signal);
        end

        $fclose(outfile);
        $display("? Simulation done. Output written to output.mem");
        $finish;
    end

endmodule
