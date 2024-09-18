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
	output   		loading,
	output   		done
    );

reg[15:0] startf;
reg[15:0] endf;
reg[15:0] len;

reg[15:0] count;

reg[2:0]	hstate;
reg[2:0]	fstate;

reg file_load;

reg ena_wr;

reg[20:0] adr;
reg[20:0] mem_adr;

reg[7:0]  data;
reg[7:0]  fmem_data;

assign done = load_done;
assign loading = loader_act | file_load;									//to switch sram A to the loader A
assign sram_a  = loader_act ? loader_ram_a[20:0] : adr[20:0];
assign sram_d  = loader_act ? loader_ram_do      : data;
assign sram_wr = loader_act ? loader_ram_wr      : ena_wr;

reg data_valid = 0;
reg load_done = 0;
reg[15:0] pulse_counter;

always @(posedge clk50 or posedge fileloader_wr) begin
	//get byte
	if (fileloader_wr) begin
		fmem_data <= fileloader_data;
		data_valid <= 1;
		pulse_counter <= pulse_counter + 1;
	end else begin
		if (reset) file_load <= 0;
		else begin
			//get file loading start
			if (fileloader_reset) begin 
				file_load <= 1;
				hstate <= 0;
				fstate <= 0;
				data_valid <= 0;
				mem_adr <= 0;
				adr <= 0;
				ena_wr <= 0;
				count <= 0;
				data <= 0;
				load_done <= 0;
				pulse_counter <= 0;
			end 
			else begin
				// load file header
				if (data_valid) begin
					case(hstate)
					0: begin
							if (fileloader_data != 8'hE6) begin
								startf[15:8] <= fmem_data;
								data_valid <= 0;
								hstate <= 1;
							end
							else data_valid <= 0;
						end
					1: begin
							startf[7:0] <= fmem_data;
							data_valid <= 0;
							hstate <= 2;
						end
					2: begin
							endf[15:8] <= fmem_data;
							data_valid <= 0;
							hstate <= 3;
						end
					3: begin
							endf[7:0] <= fmem_data;
							data_valid <= 0;
							mem_adr <= startf;
							hstate <= 4;
						end
					endcase
				end
				//----------------------
				//load file data
				if (data_valid && (hstate == 4)) begin
					len <= endf - startf + 1;
					case(fstate)
						0: begin adr <= mem_adr; data <= fmem_data; fstate <= 1; end
						1: begin ena_wr <= 1; mem_adr <= mem_adr + 1; count <= count + 1; fstate <= 2; end
						2: begin ena_wr <= 0;	data_valid <= 0; fstate <= 0;	end
						
						// clear memory up to file loading address
						3: begin mem_adr <= 0; data <= 8'b0; fstate <= 4; end
						4: begin adr <= mem_adr; fstate <= 5; end
						5: begin 
								if (mem_adr[15:0] == startf) begin file_load <= 0; if (pulse_counter > 0) load_done <= 1; end
								else begin ena_wr <= 1; mem_adr <= mem_adr + 1; fstate <= 6; end
							end
						6: begin ena_wr <= 0;fstate <= 4; end
					endcase
				end else
						if (len == count) begin data_valid <= 1; fstate <= 3; end // no need to wait for data during memory clearing process
			end																				    // also this ensures file_load = 0 if no data arrives after fileload_reset
		end
	end
end

endmodule
