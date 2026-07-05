// outlier_q88_soft.v
// Soft Outlier detection: if |din - prev| > THRESH, move output partially toward din.
// Q8.8 signed

module outlier_q88 #(
    parameter WIDTH = 16,
    parameter THRESH = 16'd1536,  // 6.0 in Q8.8
    parameter SOFT_SHIFT = 2      // fraction of jump to allow: 1/4 by default
)(
    input  wire clk,
    input  wire rst,
    input  wire signed [WIDTH-1:0] din,
    output reg  signed [WIDTH-1:0] dout
);

    reg signed [WIDTH-1:0] prev;
    reg first_valid;  

    wire signed [WIDTH-1:0] diff;
    wire [WIDTH-1:0] absdiff;
    assign diff = din - prev;
    assign absdiff = (diff[WIDTH-1]) ? -diff : diff;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prev <= 0;
            dout <= 0;
            first_valid <= 0;      
        end else begin
            // first sample: accept it ALWAYS
            if (!first_valid) begin
                prev <= din;
                dout <= din;
                first_valid <= 1;
            end else begin
                if (absdiff > THRESH) begin
                    // soft outlier: move output partially toward din
                    dout <= prev + (diff >>> SOFT_SHIFT);
                    prev <= dout;  // update reference gradually
                end else begin
                    dout <= din;  // normal case
                    prev <= din;  
                end
            end
        end
    end
endmodule
