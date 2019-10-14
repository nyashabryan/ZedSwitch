`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.10.2019 22:32:46
// Design Name: 
// Module Name: SPI
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


module SPI(

    /* Write Data Bus */
    input[0:0]      wr_valid,
    input[7:0]      wr_data,
    output reg[0:0] wr_done,
    output reg[0:0] wr_got_byte,

    /* Read Data Bus */
    output reg[0:0]     rd_valid,
    input[0:0]      rd_stop,
    output reg[7:0] rd_data,

    output reg[0:0] ss,
    output reg[0:0] pmod_mosi,
    input[0:0]      pmod_miso,

    input[0:0]      clk,
    input[0:0]      reset // active LOW

    );

    // State Machine states
    localparam  SPI_STATE_IDLE      = 2'b00;
    localparam  SPI_STATE_WRITING   = 2'b01;
    localparam  SPI_STATE_READING   = 2'b10;
    localparam  SPI_STATE_DELAY     = 2'b01;

    integer SPI_STATE;
    integer i;
    reg[7:0] temp;
    reg running;

    always @(posedge clk) begin
        if (reset == 0) begin
            SPI_STATE <= SPI_STATE_IDLE;

            wr_done <= 0;
            wr_got_byte <= 0;

            rd_valid <= 0;
            rd_data <= 0;

            ss <= 1;
            pmod_mosi <= 0;

            i <= 0;
            temp <= 8'b00000000;
            running <= 0;

        end else begin
            case (SPI_STATE)
                SPI_STATE_IDLE: begin
                    wr_done <= 0;
                    rd_valid <= 0;

                    if(wr_valid == 1) begin // TX
                        SPI_STATE <= SPI_STATE_WRITING;
                        ss <= 0; // Select the master to send
                        if (running == 1) begin
                            pmod_mosi <= wr_data[7];
                            i <= 6;
                        end else begin
                            i <= 7;
                        end
                        temp <= wr_data;
                        wr_got_byte <= 1;
                        running <= 1;

                    end else if (rd_stop == 0) begin
                        SPI_STATE <= SPI_STATE_READING;
                        ss <= 0;
                        i <= 7;
                        running <= 1;

                    end else begin
                        if (running == 1) begin
                            i <= 1;
                            SPI_STATE <= SPI_STATE_DELAY;
                        end                        
                    end
                end

                SPI_STATE_READING: begin
                    temp[i] <= pmod_miso;
                    if (rd_stop == 1) begin // Stop read initiated from controller
                        SPI_STATE <= SPI_STATE_IDLE;
                        ss <= 1;

                    end else if (i == 0) begin // Done reading the byte
                        rd_valid <= 1; // Invite the controller to read the bytes
                        rd_data <= temp;
                        i <= 7; // Reset the value of i
                    end else begin // Still reading
                        i <= i - 1;
                        rd_valid <= 0; //Data not ready for reading
                    end
                end

                SPI_STATE_WRITING: begin
                    wr_got_byte <= 0; // Still txing the byte
                    pmod_mosi <= temp[i];

                    if (i == 0) begin // Done txing the byte
                        SPI_STATE <= SPI_STATE_IDLE;
                        wr_done <= 1;
                    end else begin
                        i <= i - 1;
                    end
                end

                SPI_STATE_DELAY: begin
                    ss <= 1; // Keep the mode in read mode
                    if (i == 0) begin
                        SPI_STATE <= SPI_STATE_IDLE;
                    end else begin
                        i <= i - 1;
                    end
                end

            endcase
        end
    end


endmodule
