module InstructionMemory(clk,address,data);
		input wire	clk;
		input wire 	[31:0] 	address;
		output wire [31:0] 	data;

	parameter LENGTH = 128;   //! NUMBER OF INSTRUCIONS IN FILE
	parameter INSTRUCTIONS = "im_data.txt";  

	reg [31:0] mem [0:127];  //* INSTRUCTION MEMORY ARRAY

	initial begin
		$readmemh(INSTRUCTIONS, mem, 0, LENGTH-1);
	end

	assign data = mem[address[8:2]][31:0];
endmodule