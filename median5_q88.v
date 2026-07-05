// median5_q88.v
// 5-element median filter for Q8.8 signed 16-bit
module median5_q88 (
    input  wire clk,
    input  wire rst,
    input  wire signed [15:0] din,
    output reg  signed [15:0] dout
);
    reg signed [15:0] buf0, buf1, buf2, buf3, buf4;
    reg signed [15:0] a,b,c,d,e;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf0 <= 0; buf1 <= 0; buf2 <= 0; buf3 <= 0; buf4 <= 0;
            dout <= 0;
        end else begin
            // shift in
            buf4 <= buf3;
            buf3 <= buf2;
            buf2 <= buf1;
            buf1 <= buf0;
            buf0 <= din;

            // load a..e
            a = buf0; b = buf1; c = buf2; d = buf3; e = buf4;

            // sorting network (series of compare-swap)
            if (a > b) {a,b} = {b,a};
            if (c > d) {c,d} = {d,c};
            if (a > c) {a,c} = {c,a};
            if (b > d) {b,d} = {d,b};
            if (b > c) {b,c} = {c,b};
            if (c > e) {c,e} = {e,c};
            if (b > c) {b,c} = {c,b};
            // now c is approximate median
            dout <= c;
        end
    end
endmodule
