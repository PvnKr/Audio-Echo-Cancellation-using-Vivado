module echo_cancellation #(
    parameter DATA_WIDTH = 16,
    parameter TAP_LENGTH = 64
)(
    input wire clk,
    input wire rst,
    input wire signed [DATA_WIDTH-1:0] input_signal,  // desired + echo
    input wire signed [DATA_WIDTH-1:0] echo_signal,   // echo only
    output reg signed [DATA_WIDTH-1:0] output_signal  // filtered output
);

    reg signed [DATA_WIDTH-1:0] weights [0:TAP_LENGTH-1];
    reg signed [DATA_WIDTH-1:0] delay_line [0:TAP_LENGTH-1];

    reg signed [31:0] sum;
    reg signed [15:0] estimated_echo;
    reg signed [15:0] error;
    reg signed [31:0] weight_update;

    // ? Final stable MU = 32 (Q1.15 format = 0.00097656)
    parameter signed [15:0] MU = 16'sd32;

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < TAP_LENGTH; i = i + 1) begin
                weights[i]    <= 0;
                delay_line[i] <= 0;
            end
            output_signal <= 0;
        end else begin
            // Shift delay line
            for (i = TAP_LENGTH-1; i > 0; i = i - 1)
                delay_line[i] <= delay_line[i-1];
            delay_line[0] <= echo_signal;

            // Compute estimated echo (sum of weights * delay_line)
            sum = 0;
            for (i = 0; i < TAP_LENGTH; i = i + 1)
                sum = sum + weights[i] * delay_line[i];

            // ? Clamp estimated echo
            if (sum[30:15] > 32767)
                estimated_echo = 32767;
            else if (sum[30:15] < -32768)
                estimated_echo = -32768;
            else
                estimated_echo = sum[30:15];

            // Calculate error
            error = input_signal - estimated_echo;

            // ? Clamp output signal to prevent overflow
            if (error > 32767)
                output_signal <= 32767;
            else if (error < -32768)
                output_signal <= -32768;
            else
                output_signal <= error;

            // LMS weight update
            for (i = 0; i < TAP_LENGTH; i = i + 1) begin
                weight_update = (MU * error * delay_line[i]) >>> 15;
                weights[i] <= weights[i] + weight_update[DATA_WIDTH-1:0];
            end
        end
    end
endmodule
