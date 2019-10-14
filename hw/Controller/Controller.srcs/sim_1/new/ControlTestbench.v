`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.10.2019 03:56:28
// Design Name: 
// Module Name: ControlTestbench
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


module ControlTestbench();
    
    // period = 10;
    reg clk_line = 1;
    reg clk_line_rst = 1;

    reg         s_axi_tvalid = 0;
    reg[31:0]   s_axi_data = 0;
    reg[3:0]    s_axi_tkeep = 0;
    reg         s_axi_tlast = 0;
    wire        s_axi_tready = 0;

    reg         metadata_valid = 0;
    reg[19:0]   metadata_data = 0;

    wire        out_axi_aclk;
    reg[0:0]    out_axi_awready = 0;

    reg         out_axi_wready = 0;
    wire[31:0]  out_axi_wdata;
    wire[16:0]  out_axi_awaddr;
    
    wire[15:0] head;
    wire[15:0] tail;
    
    integer i = 0;
    
    always #5 clk_line = ~clk_line; // Generate clock @ 100MHz

    initial begin

        /************************************************/
        // Test with a fill good packet full buffer size. 
        /************************************************/

        #100; // Wait for the global reset
    
        clk_line_rst = 0;
        #10
        clk_line_rst = 1;
        #10


        metadata_valid = 1;
        metadata_data = 'b00000000110111110000;
        s_axi_tvalid = 1;
        s_axi_data = 'h12345678;
        s_axi_tkeep = 'hf;
        #10
        s_axi_data = 'hffffffff;
        #3790
        s_axi_tlast = 1;
        #10 s_axi_tlast = 0;


        #10 // Reset
        s_axi_tvalid = 0;
        s_axi_data = 'h0;
        s_axi_tkeep = 'h0;
        s_axi_tlast = 0;
        
        metadata_valid = 1;
        metadata_data = 'b00000000100000100000;


        
        for (i=0; i< 400; i = i+ 1) begin
            #10
            out_axi_awready = 1;
            #10
            out_axi_awready = 0;
            #10 
            out_axi_wready = 1;
            #10
            out_axi_wready = 0;
            end
        
        #100
        
        /************************************************/
        // Test with a packet of Egress Port 'hF
        /************************************************/

        clk_line_rst = 0;
        #10
        clk_line_rst = 1;
        #10
        s_axi_tvalid = 1;
        s_axi_data = 'hdddddddd;
        s_axi_tkeep = 'hf;
        s_axi_tlast = 1;
        
        metadata_valid = 0;
        metadata_data = 'b0000111100000100000;
        #10
        s_axi_tlast = 0;

        #10
        s_axi_tvalid = 0;
        s_axi_data = 'h0;
        s_axi_tkeep = 'h0;
        s_axi_tlast = 0;
        
        metadata_valid = 1;
        metadata_data = 'b00000000100000100000;


        #40
        out_axi_awready = 1;
        #20
        out_axi_awready = 0;
        #50 
        out_axi_wready = 1;
        #20
        out_axi_wready = 0;



        /************************************************/
        // Test with additional packetno. 3
        /************************************************/

        #50
        metadata_valid = 1;
        metadata_data = 'b00000000100010000000;
        s_axi_tvalid = 1;
        s_axi_data = 'h87654321;
        s_axi_tkeep = 'hf;
        #10
        s_axi_data = 'heeeeeeeeee;
        s_axi_tlast = 1;

        #40
        out_axi_awready = 1;
        #20
        out_axi_awready = 0;
        #50 
        out_axi_wready = 1;
        #20
        out_axi_wready = 0;
        

    end

    initial begin
        #30000 $finish;
    end
        
    Controller control(
        .clk_line_rst(clk_line_rst),
        .clk_line(clk_line),
        .S_AXI_TVALID(s_axi_tvalid),
        .S_AXI_TDATA(s_axi_data),
        .S_AXI_TKEEP(s_axi_tkeep),
        .S_AXI_TLAST(s_axi_tlast),
        .S_AXI_TREADY(s_axi_tready),

        .metadata_valid(metadata_valid),
        .metadata_data(metadata_data),

        .OUT_AXI_ACLK(out_axi_aclk),
        .OUT_AXI_AWREADY(out_axi_awready),
        .OUT_AXI_WREADY(out_axi_wready),
        .OUT_AXI_WDATA(out_axi_wdata),
        .OUT_AXI_AWADDR(out_axi_awaddr),
        
        .head(head),
        .tail(tail)
    );
endmodule
