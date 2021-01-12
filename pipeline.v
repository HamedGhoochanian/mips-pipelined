`include "register_file.v"
`include "alu.v"
`include "alu_control.v"
`include "data_memory.v"
`include "control_unit.v"
`include "reg.v"
`include "instruction_memory.v"


module pipeline(clk);
    input wire clk;
    parameter LENGTH = 20;  // number in instruction memory
	parameter INSTRUCTIONS = "instructions.txt";
    // *in name_s2 s2 shows that this registers belongs to the second stage

	wire regWrite_s5;
	wire [4:0] writeReg_s5;
	wire [31:0]	writeData_s5;
	reg stall_s1_s2;
    
	// {{{ flush control
	reg flush_s1, flush_s2, flush_s3;
	always @(*) 
	begin
		flush_s1 <= 1'b0;
		flush_s2 <= 1'b0;
		flush_s3 <= 1'b0;
		if (pcSource | jump_s4) 
		begin
			flush_s1 <= 1'b1;
			flush_s2 <= 1'b1;
			flush_s3 <= 1'b1;
		end
	end
	// }}}

    //* STAGE 1
    //* INSTRUCTION FETCH
    
    reg  [31:0] pc;
	wire [31:0] pcPlus4;
	initial 
    begin
		pc <= 32'd0;
	end   
    assign pcPlus4 = pc+4;
    
    always @(posedge clk)
    begin
        //on stall,don't change pc
        if (stall_s1_s2) 
			pc <= pc;
		else if (pcSource == 1'b1)
			pc <= branchAddress_s4;
		else if (jump_s4 == 1'b1)
			pc <= jumpAdress_s4;
		else
			pc <= pcPlus4;
	end
    
    wire [31:0] pcPlus4_s2;
    //* this will pass the pc value to the next stage
    CustomRegister #(.N(32)) reg1(Clk, flush_s1, stall_s1_s2, pcPlus4, pcPlus4_s2);

    //*memory access
	wire [31:0] instruction;
	wire [31:0] instruction_s2;
    InstructionMemory #(.LENGTH(LENGTH), .INSTRUCTIONS(INSTRUCTIONS)) instructionMemory(clk, pc, instruction);
    CustomRegister #(.N(32)) reg2(clk, flush_s1, stall_s1_s2, instruction, instruction_s2);
    // * END OF STAGE 1



    //* STAGE 2
    //* INSTRUCTION DECODE
    wire [5:0]  opCode;
	wire [4:0]  rs;
	wire [4:0]  rt;
	wire [4:0]  rd;
	wire [15:0] imm;
	wire [4:0]  shamt;
	wire [31:0] jumpAddress_s2;
	wire [31:0] extendedImmidiate;
    //* Deconstructing the binary instuction
    assign opCode = instruction_s2[31:26];
	assign rs = instruction_s2[25:21];
	assign rt = instruction_s2[20:16];
	assign rd = instruction_s2[15:11];
	assign imm = instruction_s2[15:0];
	assign shamt = instruction_s2[10:6];
	assign jumpAddress_s2 = {pc[31:28], instruction_s2[25:0], {2{1'b0}}};
	assign extendedImmidiate = {{16{instruction_s2[15]}}, instruction_s2[15:0]};
    
	//* Register file access
	wire [31:0] data1, data2;
    RegisterFile registerFile(clk, rs, rt, data1, data2, regWrite_s5, writeReg_s5, writeData_s5);
    
	//* forward rs to stage3
    wire [4:0] rs_s3;
    CustomRegister #(.N(5)) reg3(clk, 1'b0, stall_s1_s2, rs, rs_s3);
    
	//* move data 1 and 2 to stage 3 
    wire [31:0]	data1_s3, data2_s3;
	CustomRegister #(.N(64)) reg4(clk, flush_s2, stall_s1_s2, {data1, data2}, {data1_s3, data2_s3});
    
	//* move extendedImmidiate, rt, and rd to stage 3
	wire [31:0] extendedImmidiate_s3;
	wire [4:0] 	rt_s3;
	wire [4:0] 	rd_s3;
	CustomRegister #(.N(32)) reg5(clk, flush_s2, stall_s1_s2, extendedImmidiate, extendedImmidiate_s3);
	CustomRegister #(.N(10)) reg6(clk, flush_s2, stall_s1_s2, {rt, rd}, {rt_s3, rd_s3});
    
	//* move pcPlus4 to stage 3
    wire [31:0] pcPlus4_s3;
	CustomRegister #(.N(32)) reg7(clk, 1'b0, stall_s1_s2, pcPlus4_s2, pcPlus4_s3);
    
	//* evaluating control signals
    wire regdst;
	wire branchEqual_s2;
	wire branchNotEqual_s2;
	wire memRead;
	wire memWrite;
	wire memToReg;
	wire [1:0] aluop;
	wire regWrite;
	wire alusrc;
	wire jump_s2;
    ControlUnit controlUnit(opCode, 
				branchEqual_s2, 
				branchNotEqual_s2, 
				aluop, 
				memRead, 
				memWrite,
            	memToReg, 
				regdst,
				regWrite, 
				alusrc, 
				jump_s2);

    //* shift immediate left 2 bits
	wire [31:0] extendedImmediateShifted;
	assign extendedImmediateShifted = {extendedImmidiate[29:0], 2'b0};
    
	//* branch
    wire [31:0] branchAddress_s2;
	assign branchAddress_s2 = pcPlus4_s2 + extendedImmediateShifted;
    
	//* moving to control signals to stage 3
    wire		regDst_s3;
	wire		memRead_s3;
	wire		memWrite_s3;
	wire		memToReg_s3;
	wire [1:0]	aluop_s3;
	wire		regWrite_s3;
	wire		alusrc_s3;
	
	//* NOOP is  setting all controls to zero
	CustomRegister #(.N(8)) reg8(clk, stall_s1_s2, 1'b0,
			{regdst, memRead, memWrite, memToReg, aluop, regWrite, alusrc},
			{regDst_s3, memRead_s3, memWrite_s3, memToReg_s3, aluop_s3, memWrite_s3, alusrc_s3});

	wire branchEqual_s3, beanchNotEqual_s3;
	CustomRegister #(.N(2)) reg9(clk, flush_s2, 1'b0,
				{branchEqual_s2, branchNotEqual_s2},
				{branchEqual_s3, beanchNotEqual_s3});

	wire [31:0] branchAddress_s3;
	CustomRegister #(.N(32)) reg10(clk, flush_s2, 1'b0, branchAddress_s2, branchAddress_s3);

	wire jump_s3;
	CustomRegister #(.N(1)) reg11(clk, flush_s2, 1'b0, jump_s2, jump_s3);

	wire [31:0] jumpAddress_s3;
	CustomRegister #(.N(32)) reg12(clk, flush_s2, 1'b0, jumpAddress_s2, jumpAddress_s3);
    //* END OF STAGE 2 (ID)


	//* STAGE 3
	//* EXECUTION

	//* moving required control signals to stage 4
	wire memWrite_s4;
	wire memToReg_s4;
	wire memRead_s4;
	wire regWrite_s4;
	CustomRegister #(.N(4)) reg13(clk, flush_s2, 1'b0,
				{memWrite_s3, memToReg_s3, memRead_s3,memWrite_s3},
				{memWrite_s4, memToReg_s4, memRead_s4,memWrite_s4});

	//* deciding whether the alu input 2 comes from immediate or reg file
	wire [31:0] alusrc_data2;
	assign alusrc_data2 = alusrc_s3 ? extendedImmidiate_s3 : forward_data2_s3;
	
	//* ALU control 
	wire [3:0] ALUcontrol;
	wire [5:0] funct;
	assign funct = extendedImmidiate_s3[5:0];
	ALU_control alu_ctl(funct, aluop_s3, ALUcontrol);
	
	//* ALU operation
	wire [31:0]	ALU_result;
	reg [31:0] forward_data1_s3;
	
	always @(*)
	case (forward_a)
			2'b01: forward_data1_s3 = ALU_result_s4;
			2'b10: forward_data1_s3 = writeData_s5;
		 default: forward_data1_s3 = data1_s3;
	endcase

	wire zero_s3;
	ALU alu(ALUcontrol, forward_data1_s3, alusrc_data2, ALU_result, zero_s3);
	
	//* pass result and zero to next stage
	wire zero_s4;
	wire [31:0]	ALU_result_s4;
	CustomRegister #(.N(1)) reg14(clk, 1'b0, 1'b0, zero_s3, zero_s4);
	CustomRegister #(.N(32)) reg15(clk, flush_s3, 1'b0, {ALU_result}, {ALU_result_s4});
	
	//* pass data2 to stage 4
	wire [31:0] data2_s4;
	reg [31:0] forward_data2_s3;
	always @(*)
	case (forward_b)
			2'b01: forward_data2_s3 = ALU_result_s4;
			2'b10: forward_data2_s3 = writeData_s5;
		 default: forward_data2_s3 = data2_s3;
	endcase
	CustomRegister #(.N(32)) reg16(clk, flush_s3, 1'b0, forward_data2_s3, data2_s4);
	
	// write register
	wire [4:0]	writeReg;
	wire [4:0]	writeReg_s4;
	assign writeReg = (regDst_s3) ? rd_s3 : rt_s3;
	
	//* pass to stage 4
	CustomRegister #(.N(5)) reg17(clk, flush_s3, 1'b0, writeReg, writeReg_s4);

	wire branchEqual_s4, beanchNotEqual_s4;
	CustomRegister #(.N(2)) reg18(clk, flush_s3, 1'b0, {branchEqual_s3, beanchNotEqual_s3},{branchEqual_s4, beanchNotEqual_s4});

	wire [31:0] branchAddress_s4;
	CustomRegister #(.N(32)) reg19(clk, flush_s3, 1'b0,branchAddress_s3, branchAddress_s4);

	wire jump_s4;
	CustomRegister #(.N(1)) reg20(clk, flush_s3, 1'b0,jump_s3,jump_s4);

	wire [31:0] jumpAdress_s4;
	CustomRegister #(.N(32)) reg21(clk, flush_s3, 1'b0, jumpAddress_s3, jumpAdress_s4);
	//* end of stage 3

	//* STAGE 4, MEMORY ACCESS
	//* pass regWrite and memToReg to stage 5
	wire memToReg_s5;
	CustomRegister #(.N(2)) reg22(clk, 1'b0, 1'b0, {memWrite_s4, memToReg_s4},{ regWrite_s5, memToReg_s5});
	
	//* data memory
	wire [31:0] readData;
	DataMemory dataMemory(clk, ALU_result_s4[8:2], memRead_s4, memWrite_s4, data2_s4, readData);
	
	//* pass read data to stage 5
	wire [31:0] readData_s5;
	CustomRegister #(.N(32)) reg23(clk, 1'b0, 1'b0, readData, readData_s5);
	
	//* pass ALU_result to stage 5
	wire [31:0] ALU_result_s5;
	CustomRegister #(.N(32)) reg24(clk, 1'b0, 1'b0, ALU_result_s4, ALU_result_s5);
	
	//* pass writeReg to stage 5
	CustomRegister #(.N(5)) reg25(clk, 1'b0, 1'b0, writeReg_s4, writeReg_s5);
	
	//* branch
	reg pcSource;
	always @(*) begin
		case (1'b1)
			branchEqual_s4: pcSource <= zero_s4;
			beanchNotEqual_s4: pcSource <= ~(zero_s4);
			default: pcSource <= 1'b0;
		endcase
	end
	//* END OF STAGE 4

	//* STAGE 5, WRITE BACK
	//* input choice
	assign writeData_s5 = (memToReg_s5 == 1'b1) ? readData_s5 : ALU_result_s5;

	//* FORWARDING IF NECCESSARY
	reg [1:0] forward_a;
	reg [1:0] forward_b;
	always @(*) 
	begin
		//* forward if stage4 was write and we need a read.

		//* data1 input to ALU
		if ((memWrite_s4 == 1'b1) && (writeReg_s4 == rs_s3)) 
		begin
			forward_a <= 2'd1;  // stage 4
		end 
		else if ((regWrite_s5 == 1'b1) && (writeReg_s5 == rs_s3)) 
		begin
			forward_a <= 2'd2;  // stage 5
		end 
		else
			forward_a <= 2'd0;  // no forwarding

		// data2 input to ALU
		if ((memWrite_s4 == 1'b1) & (writeReg_s4 == rt_s3)) 
		begin
			forward_b <= 2'd1;  // stage 4
		end 
		else if ((regWrite_s5 == 1'b1) && (writeReg_s5 == rt_s3)) 
		begin
			forward_b <= 2'd2;  // stage 5
		end 
		else
			forward_b <= 2'd0;  // no forwarding
	end
	//* END OF STAGE 5 AND PIPELINE

	//* STALL UNIT
	always @(*) 
	begin
		if (memRead_s3 == 1'b1 && ((rt == rt_s3) || (rs == rt_s3)) ) 
		//* preform a stall which was explained before
		begin
			stall_s1_s2 <= 1'b1;
		end 
		else
			//* continue
			stall_s1_s2 <= 1'b0;   
	end
endmodule
