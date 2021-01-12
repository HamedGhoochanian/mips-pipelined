module ControlUnit(
                input wire [5:0] opcode,
                output reg branchEqual,
                output reg branchNotEqual,
                output reg [1:0] ALU_op,
                output reg memRead,
                output reg memWrite,
                output reg memToReg,
                output reg regDst,
                output reg regWrite,
                output reg ALU_source,
                output reg jump);

    always @(*)
    begin
        //* RTYPE BY DEFAULT
        jump <= 1'b0;
        regWrite <= 1'b1;
        regDst <= 1'b1;
        memWrite <= 1'b0;
        memToReg <= 1'b0;
        memRead <= 1'b0;
        branchEqual <= 1'b0;
        branchNotEqual <= 1'b0;
        ALU_source <= 1'b0;
        ALU_op [1:0] <= 2'b0;

        case(opcode)
            6'b000000:  //* R-type operations 
            begin
                // no changes necessary 
                // the default values are R type values
			end

            6'b000010:  //* JUMP 
            begin	
				jump <= 1'b1;
			end

            6'b000100:  //* BRANCH EQUAL 
            begin	
				ALU_op[0]  <= 1'b1;
				ALU_op[1]  <= 1'b0;
				branchEqual <= 1'b1;
				regWrite  <= 1'b0;
			end

            6'b000101:  //* BRANCH NOT EQUAL
            begin
				ALU_op[0]  <= 1'b1;
				ALU_op[1]  <= 1'b0;
				branchNotEqual <= 1'b1;
				regWrite  <= 1'b0;
			end
            
            6'b001000:  //* ADD IMMEDIATE 
            begin	
				regDst   <= 1'b0;
				ALU_op[1] <= 1'b0;
				ALU_source   <= 1'b1;
			end
            
            6'b100011:  //* LOAD WORD
            begin
                memRead  <= 1'b1;
				regDst  <= 1'b0;
				memToReg <= 1'b1;
				ALU_op[1] <= 1'b0;
				ALU_source   <= 1'b1;
            end

            6'b101011:  //* STORE WORD
            begin
				memWrite <= 1'b1;
				ALU_op[1] <= 1'b0;
				ALU_source   <= 1'b1;
				regWrite <= 1'b0;
			end
        endcase
    end
endmodule