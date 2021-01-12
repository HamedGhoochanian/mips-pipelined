module RegisterFile(clk, readAddress1, readAddress2, readData1, 
                        readData2, regWrite, writeAddress, writeData);

    input wire [31:0] writeData;
    input wire [4:0] readAddress2,readAddress1,writeAddress;
    input wire clk,regWrite;
    output wire [31:0] readData1,readData2;

    // internal values for loops and temporary data assignment
    integer i;
    reg [31:0] temp1,temp2;
    
    //32 registers for 32 words
    reg [31:0] registers [0:31];
    
    //fill all registers with 0
    initial 
    begin
        for(i=0;i<32;i=i+1)
            registers[i][31:0]=32'd0;
    end

    //write operation, will need clock
    always @(posedge clk)
    begin
        //prevents writing to a zero register so zer will always remain zero
        if(regWrite && writeAddress!=5'b00000)
        begin
            registers[writeAddress] <= writeData;    
        end
    end 

    //read operations
    //will happen on input change reagardless of clock
    always @(*) 
    begin
        if(readAddress1==5'b00000)
            temp1=32'd0;
        else if(regWrite && (readAddress1 == writeAddress))
            temp1=writeData;
        else 
            temp1=registers[readAddress1][31:0];

        if(readAddress2==5'b00000)
            temp2=32'd0;
        else if(regWrite && (readAddress2 == writeAddress))
            temp2=writeData;
        else 
            temp2=registers[readAddress2][31:0];
    end
endmodule