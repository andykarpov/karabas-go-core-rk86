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
	input				reset,
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

reg[15:0] startf;
reg[15:0] endf;
reg[15:0] len;

reg[7:0] mark;
reg[7:0] header[0:7];
reg[15:0]count;

reg[2:0]	state;

reg file_load;

reg ena_wr;

assign loading = loader_act | file_load;									//to switch sram A to the loader A
assign sram_a  = loader_act ? loader_ram_a[20:0] : file_mem_adr[20:0];
assign sram_d  = loader_act ? loader_ram_do: fileloader_data;
assign sram_wr = loader_act ? loader_ram_wr : (fileloader_wr && ena_wr);

always @(posedge fileloader_wr or posedge fileloader_reset) begin
	if (fileloader_reset) begin
			file_mem_adr = 0;
			state = 0;
			file_load = 1;
			count = 0;
			state = 0;
			ena_wr = 0;
		end 
	else begin
		case(state)
		0: if (fileloader_data != 8'hE6)
			begin
				startf[15:8] = fileloader_data;
				state = 1;
			end
		1: begin
				startf[7:0] = fileloader_data;
				state = 2;
			end
		2: begin
				endf[15:8] = fileloader_data;
				state = 3;
			end
		3: begin
				endf[7:0] = fileloader_data;
				len <= endf - startf + 1;
				file_mem_adr = startf;
				state = 4;
			end
		4: begin
				if (count != 0) file_mem_adr = file_mem_adr + 1;
				ena_wr = 1;
				count = count + 1;
				if (count == len) file_load = 0;
			end
		endcase
	end	 
end
endmodule
