// median3_q88.v
// 3-element median filter for Q8.8 signed 16-bit
module median3_q88 (
    input  wire clk,
    input  wire rst,
    input  wire signed [15:0] din,
    output reg  signed [15:0] dout
);
    reg signed [15:0] r0, r1, r2;
    reg signed [15:0] a, b, c;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r0 <= 0; r1 <= 0; r2 <= 0; dout <= 0;
        end else begin
            r2 <= r1;
            r1 <= r0;
            r0 <= din;
            // sort network for 3
            a = r0; b = r1; c = r2;
            // ensure a <= b
            if (a > b) begin
                {a, b} = {b, a};
            end
            // ensure b <= c
            if (b > c) begin
                {b, c} = {c, b};
            end
            // ensure a <= b (again)
            if (a > b) begin
                {a, b} = {b, a};
            end
            dout <= b; // median
        end
    end
endmodule
