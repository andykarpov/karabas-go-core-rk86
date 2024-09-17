`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:19:28 09/17/2024 
// Design Name: 
// Module Name:    macros 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module macros (
    input   clk50,        
    input   loading,       
    output[7:0] sym,
    output  macros_act,
	 input enable
);
    localparam DELAY_1 = 1_000_000;
    localparam DELAY_2 = 5_000_000; 
    localparam [7:0] SYMBOLS [0:1] = {8'h0A, 8'h28}; 
    localparam NUM_SYMBOLS = 2; 

    reg [25:0] counter;
    reg [1:0] symbol_index; 
    reg waiting;
    reg sending;   
	 reg done; 
	 reg[7:0] symbol;
	 
	 assign sym = symbol;
	 assign macros_act = (waiting | sending) & enable;
	 
    always @(posedge clk50) begin
        if (loading) begin
            counter <= 0;
            symbol_index <= 0;
            symbol <= 8'b0;
            done <= 0;
            waiting <= 0;
            sending <= 0;
        end else if (!done && !waiting && !sending) begin
            waiting <= 1;
            counter <= 0;
        end else if (waiting) begin
            if (counter < DELAY_1) begin
                counter <= counter + 1;
            end else begin
                waiting <= 0;
                sending <= 1;
                counter <= 0;
                symbol_index <= 0;
            end
        end else if (sending) begin
            if (counter < DELAY_2) begin
                counter <= counter + 1;
            end else begin
                symbol <= SYMBOLS[symbol_index];
                counter <= 0;
                if (symbol_index < NUM_SYMBOLS) begin
                    symbol_index <= symbol_index + 1;
                end else begin
                    sending <= 0;
                    done <= 1;
                end
            end
        end
    end
endmodule
