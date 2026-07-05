// Top module running all 3 filters independently
// PM2.5: Median3 → MA8
// Temperature: MA8
// Humidity: Outlier(raw) → MA8

module filter_top_q88 (
    input  wire clk,
    input  wire rst,
    input  wire signed [15:0] din_pm,
    input  wire signed [15:0] din_temp,
    input  wire signed [15:0] din_hum,
    output wire signed [15:0] dout_pm,
    output wire signed [15:0] dout_temp,
    output wire signed [15:0] dout_hum
);

    // -------------------------------
    // PM2.5 Path: Median3 -> MA8
    // -------------------------------
    wire signed [15:0] med3_pm;
    median3_q88 MED3_PM (
        .clk(clk),
        .rst(rst),
        .din(din_pm),
        .dout(med3_pm)
    );

    moving_average_q88 #(.WIDTH(16), .N(4), .SHIFT(2)) MA_PM (
        .clk(clk),
        .rst(rst),
        .din(med3_pm),
        .dout(dout_pm)
    );


    // -------------------------------
    // Temperature Path: MA8
    // -------------------------------
    moving_average_q88 #(.WIDTH(16), .N(8), .SHIFT(3)) MA_TEMP (
        .clk(clk),
        .rst(rst),
        .din(din_temp),
        .dout(dout_temp)
    );


    // -------------------------------
    // Humidity Path: Outlier -> MA8
    // -------------------------------
    wire signed [15:0] outlier_hum;
    outlier_q88 #(.WIDTH(16), .THRESH(16'd2048)) OUT_HUM (
        .clk(clk),
        .rst(rst),
        .din(din_hum),
        .dout(outlier_hum)
    );

    moving_average_q88 #(.WIDTH(16), .N(8), .SHIFT(3)) MA_HUM (
        .clk(clk),
        .rst(rst),
        .din(outlier_hum),
        .dout(dout_hum)
    );

endmodule
