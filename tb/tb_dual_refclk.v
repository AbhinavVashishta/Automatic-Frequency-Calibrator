`timescale 1ns/1ps
module tb_dual_refclk;

    localparam real REFCLK_FREQ_MHZ = 100.0;
    localparam real DIVCLK_START_FREQ_MHZ = 200.0;
    localparam real VCO_MIN_FREQ = 50.0;
    localparam real VCO_MAX_FREQ = 300.0;
    localparam real REFCLK_PERIOD = 1000.0 / REFCLK_FREQ_MHZ;
    localparam real DIVCLK_START_PERIOD = 1000.0 / DIVCLK_START_FREQ_MHZ;

    reg clk = 0;
    always #(REFCLK_PERIOD/2.0) clk = ~clk;

    reg rst_n;
    reg afctrigger;
    reg divclk = 0;

    wire refclk1, refclk2;
    wire [7:0] control_code;
    wire afc_status;

    refclk_generator refgen (
        .clk(clk),
        .rst_n(rst_n),
        .divclk(divclk),
        .afctrigger(afctrigger),
        .refclk1(refclk1),
        .refclk2(refclk2)
    );

    afc_top #(
        .CODE_WIDTH(8),
        .COUNT_WIDTH(16)
    ) dut (
        .refclk(clk),
        .rst_n(rst_n),
        .afctrigger(afctrigger),
        .divclk(divclk),
        .control_code_out(control_code),
        .afc_status(afc_status)
    );

    real period, freq_actual;
    initial begin
        divclk = 0;
        period = DIVCLK_START_PERIOD;
        forever begin
            freq_actual = VCO_MIN_FREQ + (control_code / 255.0) * (VCO_MAX_FREQ - VCO_MIN_FREQ);
            period = 1000.0 / freq_actual;
            #(period / 2.0);
            divclk = ~divclk;
        end
    end

    real t1, t2, freq;
    real lock_time;
    real expected_start_code;
    
    integer monitor_time;
    
    initial begin
        expected_start_code = ((DIVCLK_START_FREQ_MHZ - VCO_MIN_FREQ) / (VCO_MAX_FREQ - VCO_MIN_FREQ)) * 255.0;
        
        $dumpfile("tb_dual_refclk.vcd");
        $dumpvars(0, tb_dual_refclk);

        rst_n = 0;
        afctrigger = 0;
        #100;
        rst_n = 1;
        #50;

        $display("========================================");
        $display("=== AFC TEST START ===");
        $display("========================================");
        $display("Reference Clock    : %.1f MHz", REFCLK_FREQ_MHZ);
        $display("Starting Frequency : %.1f MHz", DIVCLK_START_FREQ_MHZ);
        $display("Expected Start Code: %.1f (actual controller starts at midpoint)", expected_start_code);
        $display("VCO Range          : %.1f - %.1f MHz", VCO_MIN_FREQ, VCO_MAX_FREQ);
        $display("----------------------------------------");
        
        monitor_time = 0;
        afctrigger = 1;
        
        $display("\n=== DEBUG (first 60 cycles) ===");
        repeat(60) begin
            @(posedge clk);
            monitor_time = monitor_time + 1;
            $display("T=%0d: code=%0d freq=%.1fMHz ref_cnt=%0d div_cnt=%0d ref_fast=%b div_fast=%b eq=%b state=%0d",
                     monitor_time, control_code, freq_actual,
                     dut.ref_count, dut.div_count,
                     dut.ref_fast, dut.div_fast, dut.eq,
                     dut.ctrl.state);
        end
        $display("========================================\n");

        wait(afc_status);
        lock_time = $realtime;
        #100;
        @(posedge divclk); t1 = $realtime;
        @(posedge divclk); t2 = $realtime;
        freq = 1000.0 / (t2 - t1);
        
        $display("[BINARY SEARCH]");
        $display("  Lock Time   : %.1f ns", lock_time);
        $display("  Final Freq  : %.3f MHz", freq);
        $display("  Final Code  : %0d (0x%02h)", control_code, control_code);
        $display("  Error       : %+.3f MHz (%.3f%%)", 
                 freq - REFCLK_FREQ_MHZ, 
                 ((freq - REFCLK_FREQ_MHZ) / REFCLK_FREQ_MHZ) * 100.0);
        $display("========================================");
        $display("=== TEST COMPLETE ===");
        
        #2000;
        $finish;
    end

    initial begin
        #500000;
        $display("========================================");
        $display("ERROR: Simulation timeout at %.1f ns", $realtime);
        $display("Status=%b, code=%d, freq=%.1f MHz", 
                 afc_status, control_code, freq_actual);
        $display("========================================");
        $finish;
    end

endmodule