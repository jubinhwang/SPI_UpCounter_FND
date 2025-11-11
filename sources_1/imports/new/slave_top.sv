`timescale 1ns / 1ps

module slave_top (
    // --- Global Signals ---
    input logic clk,
    input logic reset,

    // --- SPI Master Interface ---
    input logic sclk,
    input logic mosi,
    input logic ssn,
    output logic miso,    

    // --- FND Display Outputs ---
    output logic [7:0] fnd_data,
    output logic [3:0] fnd_com
);

    wire [ 7:0] w_spi_rx_data;
    wire        w_spi_rx_done;
    wire [13:0] w_fnd_data_in;

    spi_slave U_spi_slave (
        .clk     (clk),
        .reset   (reset),
        .sclk    (sclk),
        .mosi    (mosi),
        .cs      (ssn),
        .miso    (miso),
        .si_data (w_spi_rx_data),
        .si_done (w_spi_rx_done),
        .so_data (),
        .so_start(),
        .so_ready()
    );

    slave_controlunit U_control_unit (
        .clk    (clk),
        .reset  (reset),
        .ssn    (ssn),
        .rx_data(w_spi_rx_data),
        .done   (w_spi_rx_done),
        .data   (w_fnd_data_in)
    );

    fnd_controller U_fnd_controller (
        .clk     (clk),
        .rst     (reset),
        .counter (w_fnd_data_in),
        .fnd_data(fnd_data),
        .fnd_com (fnd_com)
    );

endmodule
