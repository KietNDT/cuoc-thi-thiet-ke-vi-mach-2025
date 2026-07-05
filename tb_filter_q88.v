`timescale 1ns/1ps

module tb_filter_q88;

    reg clk = 0;
    reg rst = 1;

    // Inputs (Q8.8)
    reg signed [15:0] din_pm;
    reg signed [15:0] din_temp;
    reg signed [15:0] din_hum;

    // Outputs (Q8.8)
    wire signed [15:0] dout_pm;
    wire signed [15:0] dout_temp;
    wire signed [15:0] dout_hum;

    // Scaled outputs (float)
    real dout_pm_scaled;
    real dout_temp_scaled;
    real dout_hum_scaled;

    // Files
    integer infile_pm, infile_temp, infile_hum;
    integer outfile_pm, outfile_temp, outfile_hum;
    integer outfile_pm_float, outfile_temp_float, outfile_hum_float;
    integer gold_pm, gold_temp, gold_hum;
    integer read_val, gold_val;
    integer ret;
    integer count;

    // MAE accumulators
    integer sum_abs_err_pm;
    integer sum_abs_err_temp;
    integer sum_abs_err_hum;
    real mae_pm, mae_temp, mae_hum;

    parameter N = 200;

    // DUT
    filter_top_q88 dut (
        .clk(clk),
        .rst(rst),
        .din_pm(din_pm),
        .din_temp(din_temp),
        .din_hum(din_hum),
        .dout_pm(dout_pm),
        .dout_temp(dout_temp),
        .dout_hum(dout_hum)
    );

    // 10ns clock
    always #5 clk = ~clk;

    initial begin
        // Open input files
        infile_pm   = $fopen("input_pm_q88.txt", "r");
        infile_temp = $fopen("input_temp_q88.txt", "r");
        infile_hum  = $fopen("input_hum_q88.txt", "r");

        // Open golden files
        gold_pm   = $fopen("gold_pm_q88.txt", "r");
        gold_temp = $fopen("gold_temp_q88.txt", "r");
        gold_hum  = $fopen("gold_hum_q88.txt", "r");

        // Open raw Q8.8 output files
        outfile_pm   = $fopen("output_pm_q88.txt", "w");
        outfile_temp = $fopen("output_temp_q88.txt", "w");
        outfile_hum  = $fopen("output_hum_q88.txt", "w");

        // Open float-scaled output files
        outfile_pm_float   = $fopen("output_pm_float.txt", "w");
        outfile_temp_float = $fopen("output_temp_float.txt", "w");
        outfile_hum_float  = $fopen("output_hum_float.txt", "w");

        // Reset DUT
        rst = 1;
        #20;
        rst = 0;

        sum_abs_err_pm   = 0;
        sum_abs_err_temp = 0;
        sum_abs_err_hum  = 0;

        // -------------------------------
        //         MAIN TEST LOOP
        // -------------------------------
        for (count = 0; count < N; count = count + 1) begin

            // Read input samples
            ret = $fscanf(infile_pm,   "%d\n", read_val); din_pm   = read_val;
            ret = $fscanf(infile_temp, "%d\n", read_val); din_temp = read_val;
            ret = $fscanf(infile_hum,  "%d\n", read_val); din_hum  = read_val;

            #10; // wait 1 cycle for DUT output

            // -----------------------------
            // Raw Q8.8 output
            // -----------------------------
            $fwrite(outfile_pm,   "%d\n", dout_pm);
            $fwrite(outfile_temp, "%d\n", dout_temp);
            $fwrite(outfile_hum,  "%d\n", dout_hum);

            // -----------------------------
            // Scaled float output
            // -----------------------------
            dout_pm_scaled   = dout_pm   / 256.0;
            dout_temp_scaled = dout_temp / 256.0;
            dout_hum_scaled  = dout_hum  / 256.0;

            $fwrite(outfile_pm_float,   "%f\n", dout_pm_scaled);
            $fwrite(outfile_temp_float, "%f\n", dout_temp_scaled);
            $fwrite(outfile_hum_float,  "%f\n", dout_hum_scaled);

            // -----------------------------
            // Compare against golden (MAE)
            // -----------------------------
            if (gold_pm != 0) begin
					 ret = $fscanf(gold_pm, "%d\n", gold_val);
					 if (ret == 1)
						  sum_abs_err_pm = sum_abs_err_pm +
												 ((dout_pm >= gold_val) ? (dout_pm - gold_val) : (gold_val - dout_pm));
				end

				if (gold_temp != 0) begin
					 ret = $fscanf(gold_temp, "%d\n", gold_val);
					 if (ret == 1)
						  sum_abs_err_temp = sum_abs_err_temp +
													((dout_temp >= gold_val) ? (dout_temp - gold_val) : (gold_val - dout_temp));
				end

				if (gold_hum != 0) begin
					 ret = $fscanf(gold_hum, "%d\n", gold_val);
					 if (ret == 1)
						  sum_abs_err_hum = sum_abs_err_hum +
												  ((dout_hum >= gold_val) ? (dout_hum - gold_val) : (gold_val - dout_hum));
				end

        end

        // -------------------------------
        // Compute MAE
        // -------------------------------
        if (gold_pm   != 0) mae_pm   = sum_abs_err_pm   / (N*256.0);
        if (gold_temp != 0) mae_temp = sum_abs_err_temp / (N*256.0);
        if (gold_hum  != 0) mae_hum  = sum_abs_err_hum  / (N*256.0);

        $display("PM2.5 MAE  = %f", mae_pm);
        $display("Temp  MAE = %f", mae_temp);
        $display("Hum   MAE = %f", mae_hum);

        // -------------------------------
        // Close files
        // -------------------------------
        $fclose(infile_pm);
        $fclose(infile_temp);
        $fclose(infile_hum);

        if (gold_pm)   $fclose(gold_pm);
        if (gold_temp) $fclose(gold_temp);
        if (gold_hum)  $fclose(gold_hum);

        $fclose(outfile_pm);
        $fclose(outfile_temp);
        $fclose(outfile_hum);

        $fclose(outfile_pm_float);
        $fclose(outfile_temp_float);
        $fclose(outfile_hum_float);

        #20;
        $stop;
    end

endmodule
