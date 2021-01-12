module ALU_control(funct,ALU_op,ALU_controls);
    input wire [5:0] funct;
    input wire [1:0] ALU_op;
    output reg [3:0] ALU_controls;

    reg [3:0] temp;
    //function codes are set according to the official MIPS inst set
    always @(*) begin
		case(funct[3:0])
			4'd0:  
				temp = 4'd2;	 		//* ADDITION
			4'd2: 
			 	temp = 4'd6;	 		//* SUBSTRACTION
			4'd5:  
				temp = 4'd1;	 		//* OR
			4'd10: 
				temp = 4'd7;	 		//* SLT
			default: 
				temp = 4'd0;			//* AND
		endcase

        case(ALU_op)
			2'd00: 
				ALU_controls = 4'd2;	//* ADDITION
			2'd1: 
				ALU_controls = 4'd6;	//* SUBSTRACTION
			2'd2: 
				ALU_controls = temp;	//* DEFAULT based on previous switch case 
			2'd3: 
				ALU_controls = 4'd2;	//* ADD
			default: 
				ALU_controls = 0;
		endcase
	end
endmodule