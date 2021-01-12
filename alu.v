module ALU(controls,a,b,out,zero);
	
	input [3:0]	controls;
	input [31:0] a, b;
	output reg [31:0] out;
	output	zero;

	wire overFlow_substraction, overFlow_addition, overFlow, slt;
	wire [31:0] substract_abs, add_abs;

	assign substract_abs = a - b;
	assign add_abs = a + b;
	assign overFlow_addition = (a[31] == b[31] && add_abs[31] != a[31]) ? 1 : 0;
	assign overFlow_substraction = (a[31] == b[31] && substract_abs[31] != a[31]) ? 1 : 0;
	assign zero = (out == 0);
	assign oflow = (controls == 4'b0010) ? overFlow_addition : overFlow_substraction;
	assign slt = overFlow_substraction ? ~(a[31]) : a[31];

	//at input change or clock assign the proper values to output
	//values are calculated beforehand
	always @(*)
	begin
		case (controls)
			4'b0000:
				out <= a & b;
			4'b0001:
				out <=a | b;
			4'b0010: 
				out <= add_abs;
			4'b0101:  
				out <= substract_abs;
			4'b0111:  
				out <= {{31{1'b0}}, slt};	
			4'b1100:
				out <= ~(a | b);
			4'b1101:
				out <= a ^ b;
			default: 
				out <= 0;
		endcase
	end
endmodule