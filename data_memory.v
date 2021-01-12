module DataMemory(clk,address,memRead,memWrite,writeData,readData);
    input wire clk, memRead, memWrite;
    input wire [6:0] address;
    output wire [31:0] readData;
    input wire [31:0] writeData;

    //256 4 byte words     
    reg [31:0] memory [127:0];

    always @(posedge clk)
    begin
      if(memWrite)
      begin
          memory[address] <= writeData;
      end
    end

    //read will be combinational 
    assign readData = memWrite ? writeData : memory[address][31:0];

endmodule 
