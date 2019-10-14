`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.10.2019 00:48:58
// Design Name: 
// Module Name: PMODNIC100
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


module PMODNIC100 #(parameter
    STREAM_DATA_WIDTH = 32,
    MAX_PACKET_SIZE = (1520*8),
    BUFFER_SIZE = 128,
    METADATA_WIDTH = 57,
    CS_AXI_ADDR_WIDTH = 18
)(

    input[0:0] clk_line, // Clock used by SPI @ 25MHz
    input[0:0] clk_line_rst,

    //*********************************/
    // SPI BUS
    //*********************************/
    output[0:0]     PMOD_SCLK,
    output[0:0]     PMOD_MOSI,
    input[0:0]      PMOD_MISO,
    output[0:0]     PMOD_SS,


    //*********************************/
    // AXI4-Lite Slave Interface
    //*********************************/
    // AXI4-LITE Master Output to Ethernet PMOD Module
    input                                   IN_AXI_ACLK,
    input                                   IN_AXI_ARESETN,
    // Write Address Channel
    input                                   IN_AXI_AWVALID,
    output reg [0:0]                        IN_AXI_AWREADY,
    input [CS_AXI_ADDR_WIDTH-1:0]           IN_AXI_AWADDR,
    input[2:0]                              IN_AXI_AWPROT,
    // Write Data Channel
    input                                   IN_AXI_WVALID,
    output reg [0:0]                        IN_AXI_WREADY,
    input [STREAM_DATA_WIDTH-1:0]           IN_AXI_WDATA,
    input [(CS_AXI_ADDR_WIDTH/8)-1:0]       IN_AXI_WSTRB,
    // Write Response Channel
    input[0:0]                              IN_AXI_BREADY,
    output reg[0:0]                         IN_AXI_BVALID,
    output reg[1:0]                         IN_AXI_BRESP,
    // Read Address Channel
    output reg [0:0]                        IN_AXI_ARREADY,
    input [0:0]                             IN_AXI_ARVALID,
    input [CS_AXI_ADDR_WIDTH-1:0]           IN_AXI_ARADDR,
    input [2:0]                             IN_AXI_ARPROT,
    // Read Data Channel
    input [0:0]                             IN_AXI_RREADY,
    output reg [0:0]                        IN_AXI_RVALID,
    output reg [STREAM_DATA_WIDTH-1:0]      IN_AXI_RDATA,
    output reg [1:0]                        IN_AXI_RRESP
    );

    // PMod Wires
    wire pmod_miso; 
    wire pmod_mosi;
    wire pmod_sclk;
    wire pmod_ss;

    // Controller SPI wires
    wire        wr_valid;
    wire [7:0]  wr_data;
    wire        wr_done;
    wire        wr_got_byte;
    wire        rd_valid;
    wire        rd_stop;
    wire [7:0]  rd_data;

    assign pmod_miso = PMOD_MISO;
    assign pmod_mosi = PMOD_MOSI;
    assign PMOD_SCLK = clk_line;
    assign pmod_ss = PMOD_SS;

    // Data into controller
    reg [STREAM_DATA_WIDTH-1:0] DATA;

    wire busy; // Set when controller sending data
    reg[0:0] has_data;
    reg[0:0] rx_last; // Set when the module had picked the last transfer of packet

    SPI spi(
        .ss(pmod_ss),
        .pmod_miso(pmod_miso),
        .pmod_mosi(pmod_mosi),

        // Connect the WriteReadSPIBus
        .wr_valid(wr_valid),
        .wr_data(wr_data),
        .wr_done(wr_done),
        .wr_got_byte(wr_got_byte),
        .rd_valid(rd_valid),
        .rd_stop(rd_stop),
        .rd_data(rd_data),

        .clk(clk_line),
        .reset(clk_line_rst)
    );


    Controller controller(
        // Connect the WriteReadSPIBus
        .wr_valid(wr_valid),
        .wr_data(wr_data),
        .wr_done(wr_done),
        .wr_got_byte(wr_got_byte),
        .rd_valid(rd_valid),
        .rd_stop(rd_stop),
        .rd_data(rd_data),

        // Data lines into controller
        .DATA(DATA),

        // Connect clk and reset
        .clk(clk_line),
        .reset(clk_line_rst),

        // Busy wire
        .busy(busy),
        .rx_last(rx_last),
        .has_data(has_data)
    );
    
    
    
    /**************************************/
    // TAKE IN PACKET AS AXI4 LITE SLAVE
    /**************************************/

    integer state = 0;

    localparam state_idle   = 0;
    localparam state_rx     = 1;
    localparam state_tt     = 2;
    localparam state_tx     = 3;

    integer rx_state = 0;

    localparam rx_state_00 = 99;
    localparam rx_state_0 = 0;
    localparam rx_state_1 = 1;
    localparam rx_state_2 = 2;
    localparam rx_state_3 = 3;
    localparam rx_state_4 = 4;

    integer packet_length;
    integer data_index;

    integer i;

    always @(posedge IN_AXI_ACLK) begin
        
        if (IN_AXI_ARESETN == 0) begin // on reset

            state <= state_idle;
            rx_state <= rx_state_0;
            data_index <= 0;
            
        end else begin
            case (state)
                state_idle: begin
                   state <= state_rx; 
                   rx_state <= rx_state_00;
                   data_index <= 0;
                end

                state_rx: begin
                    case (rx_state)
                        rx_state_00: begin
                            if(~busy) begin
                                rx_state <= rx_state_0;
                            end
                        end

                        rx_state_0: begin // Ready for handshake
                                IN_AXI_AWREADY <= 1;
                                rx_state <= rx_state_1;
                        end

                        rx_state_1: begin
                            if(IN_AXI_AWREADY & IN_AXI_AWVALID) begin // Handshake. Both already up.Transmit add.
                                packet_length <= IN_AXI_AWADDR[16:6];
                                rx_last <= IN_AXI_AWADDR[17];
                                IN_AXI_AWREADY <= 0;
                                rx_state <= rx_state_2;
                                
                            end
                        end

                        rx_state_2: begin
                            IN_AXI_WREADY <= 1;
                            rx_state <= rx_state_3;
                            has_data <= 1;
                            
                        end

                        rx_state_3: begin
                            if (IN_AXI_WVALID & IN_AXI_WREADY) begin
                                DATA <= IN_AXI_WDATA;
                                rx_state <= rx_state_00;
                                IN_AXI_WREADY <= 0;
                                has_data <= 0;
                            end
                        end
                    endcase
                end

                state_tt: begin            // Transition wait for busy to be set
                    state <= state_tx;
                end

                state_tx: begin
                    if(~busy) begin
                        state <= state_idle;
                        rx_last <= 0;
                    end
                end

                default: begin
                    state <= state_idle;
                end
            endcase
        end

    end

endmodule
