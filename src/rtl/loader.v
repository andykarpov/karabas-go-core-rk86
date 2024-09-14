`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:35:24 09/13/2024 
// Design Name: 
// Module Name:    loader 
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

module loader(
	input  			clk50,
	input 			loader_act,				
	input[31:0] 	loader_ram_a,
	input[7:0] 		loader_ram_do,
	input 			loader_ram_wr,
	input				fileloader_reset,
	input[31:0]		fileloader_addr,
	input[7:0] 		fileloader_data,
	input 			fileloader_wr,
	
	output[20:0]	sram_a,
	output 			sram_wr,
	output[7:0] 	sram_d,
	output   		loading
    );

reg[20:0] file_mem_adr;

reg[15:0] start;
reg[15:0] len;

reg[7:0] mark;
reg[7:0] header[0:3];
reg[1:0]	count;

reg[1:0]	state;

reg file_load;

assign loading = loader_act | file_load;									//to switch sram A to the loader A
assign sram_a  = loader_act ? loader_ram_a[20:0] : file_mem_adr[20:0];
assign sram_d  = loader_act ? loader_ram_do: fileloader_data;
assign sram_wr = loader_act ? loader_ram_wr : fileloader_wr;

always @(posedge clk50 or posedge fileloader_reset) begin
	if (fileloader_reset) 
		begin
			file_mem_adr <= 0;
			state <= 0;
			file_load <= 1;
			count <= 0;
			state <= 0;
		end 
	else 
		begin
        case(state)
		   0: if (fileloader_wr) 
				begin									
					if (fileloader_data == 8'hE6 & count == 0) 
						begin 
							mark <= fileloader_data;
						end
					else if (count <= 3) 
						begin
							count <= count + 1;
							header[count] <= fileloader_data;
							len <= {header[2],header[3]};
							if (count == 3) state <= 1;
						end
				end
			1: if (fileloader_wr) 
				begin
					if (len != 0) begin
						file_mem_adr <= file_mem_adr + 1;
						len <= len - 1;
					end
					else	file_load <= 0;
				end
		  endcase
		end
	end
endmodule
