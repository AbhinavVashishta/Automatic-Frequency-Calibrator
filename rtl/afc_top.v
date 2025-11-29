`timescale 1ns/1ps
module afc_top #(
    parameter CODE_WIDTH  = 8,
    parameter COUNT_WIDTH = 16
)(
    input  wire refclk,
    input  wire rst_n,
    input  wire afctrigger,
    input  wire divclk,
    output wire [CODE_WIDTH-1:0] control_code_out,
    output wire                  afc_status
);

    reg [COUNT_WIDTH-1:0] ref_count;
    reg [COUNT_WIDTH-1:0] div_count;
    reg afctrigger_prev;
    
    reg afctrigger_sync1, afctrigger_sync2;
    reg afctrigger_prev_div;
    
    always @(posedge divclk or negedge rst_n) begin
        if (!rst_n) begin
            afctrigger_sync1 <= 0;
            afctrigger_sync2 <= 0;
        end else begin
            afctrigger_sync1 <= afctrigger;
            afctrigger_sync2 <= afctrigger_sync1;
        end
    end

    wire ref_fast, div_fast, eq;
    wire reset_counters;

    diff_compare #(.COUNT_WIDTH(COUNT_WIDTH), .THRESHOLD(2), .MIN_SAMPLES(50)) cmp (
        .clk(refclk),
        .rst_n(rst_n),
        .ref_count(ref_count),
        .div_count(div_count),
        .ref_faster(ref_fast),
        .div_faster(div_fast),
        .equal(eq)
    );

    binary_search_controller #(.CODE_WIDTH(CODE_WIDTH)) ctrl (
        .clk(refclk),
        .rst_n(rst_n),
        .afctrigger(afctrigger),
        .gt_flag(ref_fast),
        .lt_flag(div_fast),
        .eq_flag(eq),
        .control_code_out(control_code_out),
        .afc_status(afc_status),
        .reset_counters(reset_counters)
    );
    
    always @(posedge refclk or negedge rst_n) begin
        if (!rst_n) begin
            ref_count <= 0;
            afctrigger_prev <= 0;
        end else begin
            afctrigger_prev <= afctrigger;
            if ((afctrigger && !afctrigger_prev) || reset_counters)
                ref_count <= 0;
            else if (afctrigger)
                ref_count <= ref_count + 1;
        end
    end

    always @(posedge divclk or negedge rst_n) begin
        if (!rst_n) begin
            div_count <= 0;
            afctrigger_prev_div <= 0;
        end else begin
            afctrigger_prev_div <= afctrigger_sync2;
            if ((afctrigger_sync2 && !afctrigger_prev_div) || reset_counters)
                div_count <= 0;
            else if (afctrigger_sync2)
                div_count <= div_count + 1;
        end
    end

endmodule