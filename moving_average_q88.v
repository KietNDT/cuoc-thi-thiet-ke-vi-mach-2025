// moving_average_q88.v
// Q8.8 signed fixed point, 16-bit input/output
// Parameter N must be power of 2. SHIFT = log2(N)
module moving_average_q88 #(
    parameter WIDTH = 16,
    parameter N = 4,
    parameter SHIFT = 2 // log2(N)
)(
    input  wire clk,
    input  wire rst,
    input  wire signed [WIDTH-1:0] din,
    output reg  signed [WIDTH-1:0] dout
);
    // buffer and sum width
    localparam SUMW = WIDTH + SHIFT; // enough to hold N*din
    reg signed [WIDTH-1:0] buffer [0:N-1];
    integer i;
    reg signed [SUMW-1:0] sum;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i=0;i<N;i=i+1) buffer[i] <= 0;
            sum <= 0;
            dout <= 0;
        end else begin
            // shift buffer
            for (i=N-1;i>0;i=i-1) buffer[i] <= buffer[i-1];
            buffer[0] <= din;

            // compute sum combinationally (simple)
            sum = 0;
            for (i=0;i<N;i=i+1) sum = sum + {{(SUMW-WIDTH){buffer[i][WIDTH-1]}}, buffer[i]};

            // divide by N using arithmetic shift right by SHIFT (only if N is power of 2)
            // Keep as signed arithmetic
            dout <= sum >>> SHIFT; // Q8.8 preserved
        end
    end
endmodule