`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.10.2019 00:48:58
// Design Name: 
// Module Name: Controller
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


module Controller(
    
    /* Write and Read BUS from SPI */
    output reg[0:0] wr_valid,
    output reg[7:0] wr_data,
    input[0:0]      wr_done,
    input[0:0]      wr_got_byte,

    input[0:0]      rd_valid,
    output reg[0:0] rd_stop,
    input[7:0]      rd_data,

    // S AXI
    input [31:0]        DATA,
    input[10:0]                 data_tx_len,
    output reg[0:0]             tx_done,
    input[0:0]                  tx_ready,

    input[0:0]      clk,
    input[0:0]      reset,
    
    output reg[0:0] busy,
    input rx_last,
    input has_data

    );


    // Constants
    // Instructions
    localparam[7:0] WCRU      = 8'b00100010;
    localparam[7:0] RCRU      = 8'b00100000;
    localparam[7:0] BFSU      = 8'b00100100;
    localparam[7:0] RUDADATA  = 8'b00110000;
    localparam[7:0] WUDADATA  = 8'b00110010;
    localparam[7:0] SETTXRTS  = 8'b11010100;
    localparam[7:0] SETPKTDEC = 8'b11001100;
    localparam[7:0] WRXRDPT   = 8'b01100100;
    localparam[7:0] RRXDATA   = 8'b00101100;

    // Addresses
    localparam[7:0] EUDASTL   = 'h16;
    localparam[7:0] ESTATL    = 'h1a;
    localparam[7:0] ESTATH    = 'h1b;
    localparam[7:0] ECON1L    = 'h1e;
    localparam[7:0] ECON1H    = 'h1f;
    localparam[7:0] ECON2L    = 'h6e;
    localparam[7:0] ECON2H    = 'h6f;
    localparam[7:0] ETXSTL    = 'h00;
    localparam[7:0] ETXWIREL  = 'h14;
    localparam[7:0] MACON2L   = 'h42;
    localparam[7:0] MAMXFLL   = 'h4a;
    localparam[7:0] EIEL      = 'h72;
    localparam[7:0] EIEH      = 'h73;
    localparam[7:0] EUDARDPTL = 'h8E;
    localparam[7:0] EUDAWRPTL = 'h90;
    localparam[7:0] PKTCNT    = ESTATL;
    localparam[7:0] EIRL      = 'h1c;
    localparam[7:0] ERXSTL    = 'h04;
    localparam[7:0] ERXTAILL  = 'h06;
    localparam[7:0] MAADR3L   = 'h60;

    // Masks
    localparam[7:0] TXCRCEN  = 8'b00010000; // MACON2L
    localparam[7:0] PADCFG   = 8'b11100000; // MACON2L
    localparam[7:0] CLKRDY   = 8'b00010000; // ESTATH
    localparam[7:0] ETHRST   = 8'b00010000; // ECON2L
    localparam[7:0] RXEN     = 8'b00000001; // ECON1L
    localparam[7:0] TXMAC    = 8'b00100000; // ECON2H
    localparam[7:0] TXIE     = 8'b00001000; // EIEL
    localparam[7:0] TXABTIE  = 8'b00000100; // EIEL
    localparam[7:0] INTIE    = 8'b10000000; // EIEH
    localparam[7:0] PKTDEC   = 8'b00000001; // ECON1H
    localparam[7:0] PKTIF    = 8'b01000000; // EIRL

    // Default Control Register
    localparam[7:0] MACON2L_d = 'hb2;


    /**********************************************/
    // Control States
    /**********************************************/
    localparam CS_INIT0 = 0;
    localparam CS_INIT1 = 1;
    localparam CS_INIT2 = 2;
    localparam CS_INIT3 = 3;
    localparam CS_INIT4 = 4;
    localparam CS_INIT5 = 5;
    localparam CS_INIT6 = 6;
    localparam CS_INIT7 = 7;
    localparam CS_INIT8 = 8;
    localparam CS_INIT9 = 9;
    localparam CS_INIT10 = 10;
    localparam CS_INIT11 = 11;
    localparam CS_INIT12 = 12;
    localparam CS_INIT13 = 13;
    localparam CS_INIT14 = 14;
    localparam CS_INIT15 = 15;
    localparam CS_INIT16 = 16;
    localparam CS_INIT17 = 17;
    localparam CS_INIT18 = 18;
    localparam CS_INIT19 = 19;
    localparam CS_INIT20 = 20;
    localparam CS_INIT21 = 21;
    localparam CS_INIT22 = 22;
    localparam CS_INIT23 = 23;
    localparam CS_INIT24 = 24;
    localparam CS_INIT25 = 25;
    localparam CS_INIT26 = 26;
    localparam CS_INIT27 = 27;
    localparam CS_INIT28 = 28;
    localparam CS_INIT29 = 29;
    localparam CS_INIT30 = 30;
    localparam CS_INIT31 = 31;
    localparam CS_INIT32 = 32;
    localparam CS_INIT33 = 33;
    localparam CS_INIT34 = 34;
    localparam CS_INIT35 = 35;
    localparam CS_INIT36 = 36;
    localparam CS_INIT37 = 37;
    localparam CS_INIT38 = 38;
    localparam CS_INIT39 = 39;
    localparam CS_INIT40 = 40;
    localparam CS_INIT41 = 41;
    localparam CS_INIT42 = 42;
    localparam CS_INIT43 = 43;
    localparam CS_INIT44 = 44;
    localparam CS_INIT45 = 45;
    localparam CS_INIT46 = 46;
    localparam CS_INIT47 = 47;
    localparam CS_INIT48 = 48;
    localparam CS_INIT49 = 49;
    localparam CS_INIT50 = 50;
    localparam CS_INIT51 = 51;
    localparam CS_INIT52 = 52;
    localparam CS_INIT53 = 53;
    localparam CS_INIT54 = 54;
    localparam CS_INIT55 = 55;
    localparam CS_INIT56 = 56;
    localparam CS_INIT57 = 57;
    localparam CS_INIT58 = 58;


    localparam CS_IDLE = 60;

    localparam CS_RX0 = 100;
    localparam CS_RX1 = 101;
    localparam CS_RX2 = 102;
    localparam CS_RX3 = 103;
    localparam CS_RX4 = 104;
    localparam CS_RX5 = 105;
    localparam CS_RX6 = 106;
    localparam CS_RX7 = 107;
    localparam CS_RX8 = 108;
    localparam CS_RX9 = 109;
    localparam CS_RX10 = 110;
    localparam CS_RX11 = 111;
    localparam CS_RX12 = 112;
    localparam CS_RX13 = 113;
    localparam CS_RX14 = 114;
    localparam CS_RX15 = 115;
    localparam CS_RX16 = 116;
    localparam CS_RX17 = 117;
    localparam CS_RX18 = 118;
    localparam CS_RX19 = 119;
    localparam CS_RX20 = 120;
    localparam CS_RX21 = 121;
    localparam CS_RX22 = 122;
    localparam CS_RX23 = 123;
    localparam CS_RX24 = 124;
    localparam CS_RX25 = 125;
    localparam CS_RX26 = 126;
    localparam CS_RX27 = 127;
    localparam CS_RX28 = 128;
    localparam CS_RX29 = 129;
    localparam CS_RX30 = 130;

    localparam CS_TX0 = 200;
    localparam CS_TX1 = 201;
    localparam CS_TX2 = 202;
    localparam CS_TX3 = 203;
    localparam CS_TX4 = 204;
    localparam CS_TX5 = 205;
    localparam CS_TX6 = 206;
    localparam CS_TX7 = 207;
    localparam CS_TX8 = 208;
    localparam CS_TX9 = 209;
    localparam CS_TX10 = 210;
    localparam CS_TX11 = 211;
    localparam CS_TX12 = 212;
    localparam CS_TX13 = 213;
    localparam CS_TX14 = 214;
    localparam CS_TX15 = 215;
    localparam CS_TX16 = 216;
    localparam CS_TX17 = 217;
    localparam CS_TX18 = 218;
    localparam CS_TX19 = 219;
    localparam CS_TX20 = 220;
    localparam CS_TX21 = 221;
    localparam CS_TX22 = 222;
    localparam CS_TX23 = 223;
    localparam CS_TX24 = 224;
    localparam CS_TX25 = 225;
    localparam CS_TX26 = 226;
    localparam CS_TX27 = 227;
    localparam CS_TX28 = 228;
    localparam CS_TX29 = 229;


    reg[7:0] CS_STATE;
    integer i, j;

    reg[15:0] buffer;

    reg[15:0] next_packet_ptr = 'h3000;
    reg[15:0] temp;
    /**********************************************/
    // Procedural Logic
    /**********************************************/

    always @(posedge clk) begin
        
        if (reset == 0) begin
            CS_STATE <= CS_INIT0;
            wr_data <= 8'b000000000;
            wr_valid <= 0;
            rd_stop <= 1;
            i <= 0;
            j <= 0;
            busy <= 1;

        end else begin
            case (CS_STATE)
                /************************************/
                // Initiation and Reset
                /************************************/

                // Write 'h1234 to EUDAST
                CS_INIT0: begin
                    wr_valid <= 1;
                    wr_data <= WCRU;
                    CS_STATE <= CS_INIT47;
                end

                CS_INIT1: begin
                    if (wr_got_byte == 1) begin // SPI ready to accept new data
                        wr_data <= EUDASTL;
                        CS_STATE <= CS_INIT2;
                    end
                end

                CS_INIT2: begin
                    if (wr_got_byte == 1) begin
                        wr_data <= 'h12;
                        CS_STATE <= CS_INIT3;
                    end
                end

                CS_INIT3: begin
                    if(wr_got_byte == 1) begin
                        wr_data <= 'h34;
                        CS_STATE <= CS_INIT4;
                    end
                end

        
                // Read EUDAST to check if its now 'h1234
                CS_INIT4: begin
                    if(wr_got_byte == 1) begin
                        wr_valid <= 0;
                        CS_STATE <= CS_INIT5;
                    end
                end
                CS_INIT5: begin
                    if(wr_done == 1) begin
                        CS_STATE <= CS_INIT6;
                    end
                end
                CS_INIT6: begin
                    wr_valid <= 1;
                    wr_data <= RCRU;
                    CS_STATE <= CS_INIT7;
                end
                CS_INIT7: begin
                    if (wr_got_byte == 1) begin
                        wr_data <= EUDASTL;
                        CS_STATE <= CS_INIT8;
                    end
                end
                CS_INIT8: begin
                    if (wr_got_byte == 1) begin
                        wr_valid <= 0; // No input
                        CS_STATE <= CS_INIT9;
                    end
                end
                CS_INIT9: begin
                    rd_stop <= 0; // Enable reading
                    if (rd_valid == 1) begin
                        buffer[7:0] <= rd_data;
                        CS_STATE <= CS_INIT10;
                    end
                end
                CS_INIT10: begin
                    if(rd_valid == 1) begin
                        buffer[15:8] <= rd_data;
                        CS_STATE <= CS_INIT11;
                        rd_stop <= 0; // Diable access to read
                    end
                end
                CS_INIT11: begin
                    if(!(buffer == 'h3412)) begin // Check if register is same as formula.
                        CS_STATE <= CS_INIT0;
                    end else begin
                        CS_STATE <= CS_INIT12;
                    end
                end

                // Poll CLKRDY until it's set
                CS_INIT12: begin
                    wr_valid <= 1;
                    wr_data = RCRU;
                    CS_STATE <= CS_INIT13;
                end
                CS_INIT13: begin
                    if(wr_got_byte == 1) begin
                        wr_data <= ESTATH;
                        CS_STATE <= CS_INIT14;
                    end
                end
                CS_INIT14: begin
                    if(wr_got_byte == 1) begin
                        wr_valid <= 0;
                        CS_STATE <= CS_INIT15;
                        rd_stop <= 0;
                    end
                end
                CS_INIT15: begin
                    if(rd_valid == 1) begin
                        buffer[7:0] <= rd_data;
                        CS_STATE <= CS_INIT16;
                        rd_stop <= 1;
                    end
                end
                CS_INIT16: begin
                    if (buffer[4] == 1) begin
                        CS_STATE <= CS_INIT17;
                    end else begin
                        CS_STATE <= CS_INIT12;
                    end
                end

                // Issue a System Reset Command
                CS_INIT17: begin
                    wr_valid <= 1;
                    wr_data <= BFSU;
                    CS_STATE <= CS_INIT18;
                end
                CS_INIT18: begin
                    if (wr_got_byte == 1) begin
                        wr_data <= ECON2L;
                        CS_STATE <= CS_INIT19;
                    end
                end
                CS_INIT19: begin
                    if(wr_got_byte == 1) begin
                        wr_data <= ETHRST;
                        CS_STATE <= CS_INIT20;
                    end
                end
                CS_INIT20: begin
                    if(wr_got_byte == 1) begin
                        wr_valid <= 0; // Stop writing
                        CS_STATE <= CS_INIT21;
                    end
                end
                CS_INIT21: begin
                    if(wr_done == 1) begin
                        CS_STATE <= CS_INIT22;
                        i <= 625;
                    end
                end

                // Delay for at least 25u seconds.
                CS_INIT22: begin
                    i <= i - 1;
                    if (i == 0) begin
                        CS_STATE <= CS_INIT23;
                    end
                end

                // Read EUDAST to confirm the System Reset
                CS_INIT23: begin
                    wr_valid <= 1;
                    wr_data <= RCRU;
                    CS_STATE <= CS_INIT24;
                end
                CS_INIT24: begin
                    if (wr_got_byte == 1) begin
                        wr_data <= EUDASTL;
                        CS_STATE <= CS_INIT25;
                    end
                end
                CS_INIT25: begin
                    if (wr_got_byte == 1) begin
                        wr_valid <= 0;
                        CS_STATE <= CS_INIT26;
                    end
                end
                CS_INIT26: begin
                    rd_stop <= 0;
                    if (rd_valid == 1) begin
                        buffer[7:0] <= rd_data;
                        CS_STATE <= CS_INIT27;
                    end
                end
                CS_INIT27: begin
                    if (rd_valid == 1) begin
                        buffer[15:0] <= rd_data;
                        CS_STATE <= CS_INIT28;
                        rd_stop <= 1;
                    end
                end
                CS_INIT28: begin
                    if (buffer == 'h0000) begin
                        CS_STATE <= CS_INIT29;
                        i <= 7000;
                    end
                end
                
                // Delay for 256uS for PHY registers to become available
                CS_INIT29: begin
                    i <= i - 1;
                    if (i == 0) begin
                        CS_STATE <= CS_INIT30;
                    end
                end

                // Verify that TXCRCEN bits set correctly
                CS_INIT30: begin
                    wr_valid <= 1;
                    wr_data <= RCRU;
                    CS_STATE <= CS_INIT31;
                end
                CS_INIT31: begin
                    if (wr_got_byte == 1) begin
                        wr_data <= MACON2L;
                        CS_STATE <= CS_INIT32;
                    end
                end
                CS_INIT32: begin
                    if (wr_got_byte == 1) begin
                        wr_valid <= 0;
                        rd_stop <= 0;
                        CS_STATE <= CS_INIT33;
                    end
                end
                CS_INIT33: begin
                    if(rd_valid == 1) begin
                        buffer[7:0] <= rd_data;
                        rd_stop <= 1;
                        CS_STATE <= CS_INIT34;
                    end
                end
                CS_INIT34: begin
                    if (buffer[7:0] == MACON2L_d) begin
                        CS_STATE <= CS_INIT35;
                    end else begin
                        CS_STATE <= CS_INIT30;
                    end
                end


                // Set up the RX ptr head and tail
                CS_INIT35: begin
                    wr_valid <= 1;
                    wr_data <= WCRU;
                    CS_STATE <= CS_INIT36;
                end
                CS_INIT36: begin
                    if (wr_got_byte == 1) begin
                        wr_data <= ERXSTL;
                        CS_STATE <= CS_INIT37;
                   end
                end
                CS_INIT37: begin
                    temp = next_packet_ptr;
                    if (wr_got_byte == 1) begin
                        wr_data <= temp[7:0]; // 'h00
                        CS_STATE <= CS_INIT38;
                    end
                end
                CS_INIT38: begin
                    if(wr_got_byte == 1) begin
                        wr_data <= temp[15:8]; //'h30
                        CS_STATE <= CS_INIT39;
                    end
                end
                CS_INIT39: begin
                    if(wr_got_byte == 1) begin
                        wr_data <= 'hfe; // ERXTAILL = fe
                        CS_STATE <= CS_INIT40;
                    end
                end
                CS_INIT40: begin
                    if(wr_got_byte == 1) begin
                        wr_data <= 'h5f; // ERXTAILH = 5f
                        CS_STATE <= CS_INIT41;
                    end
                end
                CS_INIT41: begin // Finish writing
                    if(wr_got_byte == 1) begin
                        wr_valid <= 0;
                        CS_STATE <= CS_INIT42;
                    end
                end
                CS_INIT42: begin
                    if(wr_done == 1) begin
                        CS_STATE <= CS_INIT43;
                    end
                end

                // Enable packet reception
                CS_INIT43: begin
                    wr_valid <= 1;
                    wr_data <= BFSU;
                    CS_STATE <= CS_INIT44;
                end
                CS_INIT44: begin
                    if(wr_got_byte == 1) begin
                        wr_data <= ECON1L;
                        CS_STATE <= CS_INIT45;
                    end
                end
                CS_INIT45: begin
                    if(wr_got_byte == 1) begin
                        wr_data <= RXEN;
                        CS_STATE <= CS_INIT46;
                    end
                end
                CS_INIT46: begin
                    if(wr_got_byte == 1) begin
                        wr_valid <= 0;
                        CS_STATE <= CS_INIT47;
                    end
                end
                CS_INIT47: begin
                    if(wr_done == 1) begin
                        CS_STATE <= CS_IDLE;
                        busy <= 0;
                    end
                end
            
                /********************************************/
                // IDLE STATE
                /********************************************/

                CS_IDLE: begin
                    if (has_data) begin
                        CS_STATE <= CS_TX0;
                        busy <= 1;
                    end
                end

                /********************************************/
                // TX
                /********************************************/

                CS_TX0: begin
                    wr_valid <= 1;
                    wr_data <= WCRU;
                    CS_STATE <= CS_TX1;
                end

                CS_TX1: begin
                    if (wr_got_byte == 1) begin
                        wr_data <= ETXSTL;
                        CS_STATE <= CS_TX2;
                    end
                end

                CS_TX2: begin
                    if (wr_got_byte ==1) begin
                        wr_data <= 'h00;
                        CS_STATE <= CS_TX3;
                    end
                end

                CS_TX3: begin
                    if (wr_got_byte == 1) begin
                        wr_data <= 'h00;
                        CS_STATE <= CS_TX4;
                    end
                end

                CS_TX4: begin
                    if (wr_got_byte == 1) begin
                        temp = 'b0000000000000100;
                        wr_data <= temp[7:0];
                        CS_STATE <= CS_TX5;
                    end
                end

                CS_TX5: begin
                    if(wr_got_byte == 1) begin
                        wr_data <= temp[15:8];
                        CS_STATE <= CS_TX6;
                    end
                end

                CS_TX6: begin
                    if(wr_got_byte == 1) begin
                        wr_valid <= 0;
                        CS_STATE <= CS_TX7;
                    end
                end

                CS_TX7: begin
                    if (wr_done == 1) begin
                        CS_STATE <= CS_TX8;                        
                    end
                end

                CS_TX8: begin
                    wr_valid <= 1;
                    wr_data <= WCRU;
                    CS_STATE <= CS_TX9;
                end

                CS_TX9: begin
                    if (wr_got_byte == 1) begin
                        wr_data <= EUDAWRPTL;
                        CS_STATE <= CS_TX10;
                    end
                end

                CS_TX10: begin
                    if (wr_got_byte == 1) begin
                        wr_data <= 'h00;
                        CS_STATE <= CS_TX11;
                    end
                end
                CS_TX11: begin
                    if (wr_got_byte == 1) begin
                        wr_data <= 'h00;
                        CS_STATE <= CS_TX12;
                    end
                end

                CS_TX12: begin
                    if (wr_got_byte == 1) begin
                        wr_valid <= 0;
                        CS_STATE <= CS_TX13;
                    end
                end                

                CS_TX13: begin
                    if (wr_done == 1) begin
                        CS_STATE <= CS_TX14;
                    end
                end

                CS_TX14: begin
                    wr_valid <= 1;
                    wr_data <= WUDADATA;
                    CS_STATE <= CS_TX15;
                end

                // Copy data to memory
                CS_TX15: begin
                    if (wr_got_byte == 1) begin
                        wr_data <= DATA[7:0];
                        CS_STATE <= CS_TX16;
                    end
                end

                CS_TX16: begin
                    if (wr_got_byte == 1) begin
                        wr_data <= DATA[15:8];
                        CS_STATE <= CS_TX17;
                    end
                end

                CS_TX17: begin
                    if (wr_got_byte == 1) begin
                        wr_data <= DATA[23:16];
                        CS_STATE <= CS_TX18;
                    end
                end

                CS_TX18: begin
                    if (wr_got_byte == 1) begin
                        wr_data <= DATA[31:24];
                        if (rx_last) begin
                            CS_STATE <= CS_TX20;
                        end else begin
                            CS_STATE <= CS_TX19;    
                        end
                    end
                end

                // Wait for new data
                CS_TX19: begin
                    if (has_data) begin
                        CS_STATE <= CS_TX15;
                    end
                end

                // Done with data
                CS_TX20: begin
                    if (wr_got_byte == 1) begin
                        wr_valid <= 0;
                        CS_STATE <= CS_TX21;
                    end
                end

                CS_TX21: begin
                    if(wr_done) begin
                        CS_STATE <= CS_TX22;
                    end
                end

                //Start the transaction
                CS_TX22: begin
                    wr_valid <= 1;
                    wr_data <= SETTXRTS;
                    CS_STATE <= CS_TX23;
                end

                CS_TX23: begin
                    if (wr_got_byte == 1) begin
                        wr_valid <= 0;
                        CS_STATE <= CS_TX24;
                    end
                end
                
                CS_TX24: begin
                    if (wr_done == 1) begin
                        busy <= 0;
                        CS_STATE <= CS_IDLE;
                    end
                end

                /********************************************/
                // RX
                /********************************************/





                default: begin
                    CS_STATE <= CS_INIT0;
                end
            endcase
        end
    end

endmodule
