`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.10.2019 22:23:09
// Design Name: 
// Module Name: Controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: ++1
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Controller #(parameter
    STREAM_DATA_WIDTH = 32,
    MAX_PACKET_SIZE = (1520*8),
    BUFFER_SIZE = 128,
    METADATA_WIDTH = 52,
    CS_AXI_ADDR_WIDTH = 17

)(

    // Clock and Clock Line reset
    input clk_line,
    input clk_line_rst,


    // AXI4 Stream Input Interface 
    input [0:0]                             S_AXI_TVALID,
    output reg [0:0]                        S_AXI_TREADY,
    input  [STREAM_DATA_WIDTH - 1:0]        S_AXI_TDATA,
    input [(STREAM_DATA_WIDTH/8) -1:0]      S_AXI_TKEEP,
    input [0:0]                             S_AXI_TLAST,
    
    // Metadata input from Switch
    input [0:0]                         metadata_valid,
    input [METADATA_WIDTH -1:0]        metadata_data,
    
    
    // AXI4-LITE Master Output to Ethernet PMOD Module
    output                                  OUT_AXI_ACLK,
    output                                  OUT_AXI_ARESETN,
    // Write Address Channel
    output reg[0:0]                         OUT_AXI_AWVALID,
    input [0:0]                             OUT_AXI_AWREADY,
    output reg[CS_AXI_ADDR_WIDTH-1:0]       OUT_AXI_AWADDR,
    output reg[2:0]                         OUT_AXI_AWPROT,
    // Write Data Channel
    output reg[0:0]                         OUT_AXI_WVALID,
    input [0:0]                             OUT_AXI_WREADY,
    output reg[STREAM_DATA_WIDTH-1:0]       OUT_AXI_WDATA,
    output reg[(CS_AXI_ADDR_WIDTH/8)-1:0]   OUT_AXI_WSTRB,
    // Write Response Channel
    output reg[0:0]                         OUT_AXI_BREADY,
    input [0:0]                             OUT_AXI_BVALID,
    input [1:0]                             OUT_AXI_BRESP,
    // Read Address Channel
    input [0:0]                             OUT_AXI_ARREADY,
    output [0:0]                            OUT_AXI_ARVALID,
    output [CS_AXI_ADDR_WIDTH-1:0]          OUT_AXI_ARADDR,
    output [2:0]                            OUT_AXI_ARPROT,
    // Read Data Channel
    output reg[0:0]                         OUT_AXI_RREADY,
    input [0:0]                             OUT_AXI_RVALID,
    input [STREAM_DATA_WIDTH-1:0]           OUT_AXI_RDATA,
    input [1:0]                             OUT_AXI_RRESP,
    
    output reg[15:0] head,
    output reg[15:0] tail

    );
    
    assign OUT_AXI_ACLK = clk_line;
    assign OUT_AXI_ARESETN = clk_line_rst;

    localparam EGRESSPORT_1 = 1; // PMOD1
    localparam EGRESSPORT_2 = 2; // PMOD1
    localparam EGRESSPORT_3 = 3; // PMOD1
    localparam EGRESSPORT_4 = 4; // PMOD1

    localparam EGRESSDROP = 'hF; // DROP the PACKET

    // Declare BRAM for FIFO for each PMOD and more unused cases.
    reg [MAX_PACKET_SIZE-1:0] FIFORAM [BUFFER_SIZE-1:0];
    reg [METADATA_WIDTH-1:0] CONTROLRAM [BUFFER_SIZE-1:0];
    
    integer rx_data_index = 0;
    integer tx_data_index = 0;

    /************************************************************/
    /* Incoming data state machine                              */
    /************************************************************/

    localparam IN_STATE_IDLE  = 2'b00;
    localparam IN_STATE_RX    = 2'b01;
    localparam IN_STATE_DROP  = 2'b10;
    reg IN_STATE = IN_STATE_IDLE;

    // Change state based on Handshake procedure
    always@(posedge clk_line) begin
        if (clk_line_rst == 0) begin
            // Reset the RAM variables
            head <= 0;
            tail <= 0;
            rx_data_index <= 0;

            // Reset the State and the S_AXI_TREADY
            IN_STATE <= 0;
            S_AXI_TREADY <= 1;

        end else begin
            case (IN_STATE)
                IN_STATE_IDLE: begin
                    S_AXI_TREADY <= 1;
                    if (S_AXI_TVALID & S_AXI_TREADY) begin // Handshake. Begin the transfer.

                        if(~metadata_valid) begin // Check for the metadata for forwarding port.
                            IN_STATE <= IN_STATE_DROP;
                        end else begin
                            if(metadata_data[15:12] == EGRESSDROP | metadata_data[11] == 0) begin // Check if the packet is being dropped or not 
                                IN_STATE <= IN_STATE_DROP; // Drop packet
                            end else begin
                                CONTROLRAM[head] <= metadata_data;
                                if (S_AXI_TLAST) begin 
                                    IN_STATE <= IN_STATE_IDLE;
                                    head <= (head + 1) % BUFFER_SIZE;
                                    S_AXI_TREADY <= 0;
                                end else begin
                                    IN_STATE <= IN_STATE_RX; // Now in RX mode
                                end
                                

                                // Deassert the TREADY signal
                                S_AXI_TREADY <= 0;
                                
                                // Start pushing Bytes
                                FIFORAM[head][((rx_data_index + 1) * STREAM_DATA_WIDTH)-1 +: STREAM_DATA_WIDTH] <= S_AXI_TDATA;

                                // Increment the ram variables
                                rx_data_index <= rx_data_index + 1;

                           end
                        end
                    end
                end

                IN_STATE_DROP: begin
                    if (S_AXI_TLAST) begin
                        IN_STATE <= IN_STATE_IDLE; // Set to IDLE state
                    end
                end


                IN_STATE_RX: begin

                    // Start pushing Bytes
                    FIFORAM[head][((rx_data_index + 1) * STREAM_DATA_WIDTH)-1 +: STREAM_DATA_WIDTH] <= S_AXI_TDATA;

                    // Increment the ram variables
                    rx_data_index <= rx_data_index + 1;


                    if (S_AXI_TLAST) begin
                        IN_STATE <= IN_STATE_IDLE; // Set to IDLE state
                        head <= (head + 1) % BUFFER_SIZE;
                    end

                end if (CONTROLRAM[tail][10:0] % 4 != 0) begin
                                i <= CONTROLRAM[tail][10:0] / 4 + 1;
                            end else begin
                                i <= CONTROLRAM[tail][10:0] / 4;
                            end
            endcase
        end

    end

    /************************************************************/
    /* Outgoing data state machine  AXI4-LITE                   */
    /************************************************************/

    /** Sending available data in the RAM to AXI interface. */

    localparam OUT_STATE_IDLE   = 'b00;
    localparam OUT_STATE_TX     = 'b01;

    localparam TX_STATE_0 = 'b000;
    localparam TX_STATE_1 = 'b001;
    localparam TX_STATE_2 = 'b010;
    localparam TX_STATE_3 = 'b011;
    localparam TX_STATE_4 = 'b100;
    localparam TX_STATE_5 = 'b101;
    
    integer OUT_STATE;
    integer TX_STATE;
    integer i;
    reg[5:0] j;

    always @(posedge clk_line) begin
        if (clk_line_rst == 0) begin
            OUT_STATE <= OUT_STATE_IDLE;
            TX_STATE <= TX_STATE_0;
            tx_data_index <= 0;
            i <= 0;
            j <= 0;

        end else begin
            case (OUT_STATE)
                OUT_STATE_IDLE: begin
                    TX_STATE <= TX_STATE_0;
                    if(head == tail) begin // The buffer is empty
                        OUT_STATE <= OUT_STATE_IDLE;
                    end else begin
                        OUT_STATE <= OUT_STATE_TX;
                    end
                end

                OUT_STATE_TX: begin
                    case (TX_STATE)

                        TX_STATE_0: begin // Initiate the transfers
                            if (CONTROLRAM[tail][10:0] % 4 != 0) begin
                                i <= CONTROLRAM[tail][10:0] / 4 + 1;
                            end else begin
                                i <= CONTROLRAM[tail][10:0] / 4;
                            end
                            j <= 0;
                            TX_STATE <= TX_STATE_1;                         
                        end

                        TX_STATE_1: begin // Begin a burst
                            if (i > 0) begin
                                i <= i - 1;
                                j <= j + 1;
                                OUT_AXI_AWVALID <= 1;
                                OUT_AXI_AWADDR <= {CONTROLRAM[tail][10:0], j};
                                TX_STATE <= TX_STATE_2;                                
                            end else begin
                                OUT_STATE <= OUT_STATE_IDLE;
                                tail <= (tail + 1) % BUFFER_SIZE;
                            end
                        end

                        TX_STATE_2: begin // Write the address 
                            if (OUT_AXI_AWREADY == 1) begin
                                OUT_AXI_AWVALID <= 0;
                                OUT_AXI_AWADDR <= 0;
                                TX_STATE <= TX_STATE_3;
                            end
                        end

                        TX_STATE_3: begin // Assert wvalid
                            OUT_AXI_WVALID <= 1;
                            OUT_AXI_WDATA <= FIFORAM[tail][(j-1) * STREAM_DATA_WIDTH + STREAM_DATA_WIDTH-1 +: STREAM_DATA_WIDTH];
                            TX_STATE <= TX_STATE_4;
                        end
                        TX_STATE_4: begin
                            if (OUT_AXI_WREADY == 1) begin
                                OUT_AXI_WVALID <= 0;
                                OUT_AXI_WDATA <= 0;
                                TX_STATE <= TX_STATE_1; // Repeat cycle
                            end
                        end
                        default: begin
                            TX_STATE <= TX_STATE_0;
                            OUT_STATE <= OUT_STATE_IDLE;
                        end
                    endcase
                end

                default: begin
                    OUT_STATE <= OUT_STATE_IDLE;
                end
            endcase
        end
    end


endmodule
