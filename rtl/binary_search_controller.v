`timescale 1ns/1ps
module binary_search_controller #(
    parameter CODE_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire afctrigger,
    input wire gt_flag,
    input wire lt_flag,
    input wire eq_flag,
    output reg [CODE_WIDTH-1:0] control_code_out,
    output reg afc_status,
    output reg reset_counters
);

    reg [CODE_WIDTH-1:0] low, high;
    reg [2:0] state;
    reg afctrigger_prev;
    reg [7:0] settle_counter;
    
    localparam IDLE   = 3'd0, 
               RUN    = 3'd1,
               SETTLE = 3'd2,
               FIN    = 3'd3;
    
    localparam SETTLE_CYCLES = 8'd100;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            low              <= {CODE_WIDTH{1'b0}};
            high             <= {CODE_WIDTH{1'b1}};
            control_code_out <= {1'b0, {(CODE_WIDTH-1){1'b1}}};
            state            <= IDLE;
            afc_status       <= 1'b0;
            afctrigger_prev  <= 1'b0;
            reset_counters   <= 1'b0;
            settle_counter   <= 8'd0;
        end else begin
            afctrigger_prev <= afctrigger;
            reset_counters  <= 1'b0;
            
            case (state)
                IDLE: begin
                    afc_status <= 1'b0;
                    if (afctrigger && !afctrigger_prev) begin
                        low              <= {CODE_WIDTH{1'b0}};
                        high             <= {CODE_WIDTH{1'b1}};
                        control_code_out <= {1'b0, {(CODE_WIDTH-1){1'b1}}};
                        state            <= SETTLE;
                        settle_counter   <= 8'd0;
                        reset_counters   <= 1'b1;
                    end
                end
                
                SETTLE: begin
                    settle_counter <= settle_counter + 1'b1;
                    if (settle_counter >= SETTLE_CYCLES) begin
                        state          <= RUN;
                        settle_counter <= 8'd0;
                    end
                end
                
                RUN: begin
                    if (eq_flag) begin
                        state      <= FIN;
                        afc_status <= 1'b1;
                    end else if (low >= high) begin
                        state      <= FIN;
                        afc_status <= 1'b1;
                    end else begin
                        if (gt_flag) begin
                            low <= control_code_out + 1'b1;
                        end else if (lt_flag) begin
                            high <= (control_code_out > 0) ? (control_code_out - 1'b1) : 0;
                        end
                        
                        control_code_out <= (low + high) >> 1;
                        state            <= SETTLE;
                        settle_counter   <= 8'd0;
                        reset_counters   <= 1'b1;
                    end
                end
                
                FIN: begin
                    afc_status <= 1'b1;
                    if (!afctrigger) begin
                        state      <= IDLE;
                        afc_status <= 1'b0;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule