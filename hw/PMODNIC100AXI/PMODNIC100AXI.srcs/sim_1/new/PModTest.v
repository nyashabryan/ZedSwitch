`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.10.2019 11:09:37
// Design Name: 
// Module Name: PModTest
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module PModTest();


    reg clk = 0;
    reg clk_line_rst = 1;
    wire pmod_mosi;
    wire pmod_ss;

    reg axi_clk = 0;
    reg axi_reset;

    reg awvalid;
    wire awready;
    reg[17:0] awaddr;

    reg wvalid;
    wire wready;
    reg[31:0] wdata;
    
    always #5 axi_clk = ~axi_clk;
    always #20 clk = ~clk;

    initial begin
        #100; // Wait for the global reset
    
        clk_line_rst = 0;
        axi_reset = 0;
        #10
        clk_line_rst = 1;
        axi_reset = 1;
        #10


        awvalid = 1;
        awaddr = 'b100000000000000000;

        #20
        wvalid = 1;
        wdata = 'h12345678;


    end
    
    initial begin
        #15000 $finish;
    end

    PMODNIC100 pmodnic(
        .clk_line(clk),
        .clk_line_rst(clk_line_rst),
        
        .IN_AXI_ACLK(axi_clk),
        .IN_AXI_ARESETN(axi_reset),

        .IN_AXI_AWVALID(awvalid),
        .IN_AXI_AWREADY(awready),
        .IN_AXI_AWADDR(awaddr),

        .IN_AXI_WVALID(wvalid),
        .IN_AXI_WREADY(wready),
        .IN_AXI_WDATA(wdata),

        .PMOD_MOSI(pmod_mosi),
        .PMOD_SS(pmod_ss)
    );
    
endmodule
