`timescale 1ns/1ps
module refclk_generator (
    input  wire clk,
    input  wire rst_n,
    input  wire divclk,
    input  wire afctrigger,
    output wire refclk1,
    output wire refclk2
);

    reg [1:0] div_count;
    reg divclk_prev;
    reg afc_started;
    
    wire clk_0, clk_90, clk_180, clk_270;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            afc_started <= 0;
        end else if (afctrigger) begin
            afc_started <= 1;
        end else if (!afctrigger) begin
            afc_started <= 0;
        end
    end
    
    reg clk_div2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_div2 <= 0;
        else
            clk_div2 <= ~clk_div2;
    end
    
    assign clk_0   = clk_div2;
    assign clk_180 = ~clk_div2;
    
    reg clk_div4;
    always @(posedge clk_0 or negedge rst_n) begin
        if (!rst_n)
            clk_div4 <= 0;
        else
            clk_div4 <= ~clk_div4;
    end
    
    assign clk_90  = clk_div4;
    assign clk_270 = ~clk_div4;
    
    assign refclk1 = clk_0;
    assign refclk2 = clk_270;

endmodule