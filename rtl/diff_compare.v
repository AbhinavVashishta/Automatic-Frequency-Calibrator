`timescale 1ns/1ps
module diff_compare #(
    parameter COUNT_WIDTH = 16,
    parameter THRESHOLD   = 2,
    parameter MIN_SAMPLES = 50
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [COUNT_WIDTH-1:0] ref_count,
    input  wire [COUNT_WIDTH-1:0] div_count,
    output reg  ref_faster,
    output reg  div_faster,
    output reg  equal
);

    reg [3:0] stable_cnt;
    wire signed [COUNT_WIDTH:0] diff;
    wire signed [COUNT_WIDTH:0] abs_diff;
    
    assign diff = $signed({1'b0, ref_count}) - $signed({1'b0, div_count});
    assign abs_diff = (diff < 0) ? -diff : diff;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ref_faster <= 0;
            div_faster <= 0;
            equal      <= 0;
            stable_cnt <= 0;
        end else begin
            if (ref_count < MIN_SAMPLES) begin
                ref_faster <= 0;
                div_faster <= 0;
                equal      <= 0;
                stable_cnt <= 0;
            end else if (diff > $signed(THRESHOLD)) begin
                ref_faster <= 1;
                div_faster <= 0;
                equal      <= 0;
                stable_cnt <= 0;
            end else if (diff < -$signed(THRESHOLD)) begin
                ref_faster <= 0;
                div_faster <= 1;
                equal      <= 0;
                stable_cnt <= 0;
            end else begin
                ref_faster <= 0;
                div_faster <= 0;
                
                if (stable_cnt >= 4'd4) begin
                    equal <= 1;
                end else begin
                    stable_cnt <= stable_cnt + 1;
                    equal <= 0;
                end
            end
        end
    end
endmodule