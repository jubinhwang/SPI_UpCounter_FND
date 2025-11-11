`timescale 1ns / 1ps

module spi_top (
    input  logic       clk,
    input  logic       reset,
    input  logic       run_stop,
    input  logic       clear,
    input  logic       cpol,
    input  logic       cpha,
    input  logic       master_miso,
    output logic       master_ss,
    output logic       master_sclk,
    output logic       master_mosi,
    ////////////
    output  logic       slave_miso,
    input  logic       slave_ss,
    input  logic       slave_sclk,
    input  logic       slave_mosi,
    output logic [7:0] fnd_data,
    output logic [3:0] fnd_com
);

    
    master_top U_MASTER_TOP (
        .clk     (clk),
        .reset   (reset),
        .run_stop(run_stop),
        .clear   (clear),
        .cpol    (cpol),
        .cpha    (cpha),
        .ss      (master_ss),
        .sclk    (master_sclk),
        .mosi    (master_mosi),
        .miso    (master_miso)
    );

    slave_top U_SLAVE_TOP (
        .clk              (clk),
        .reset            (reset),
        .sclk             (slave_sclk),
        .mosi             (slave_mosi),
        .miso             (slave_miso),
        .ssn              (slave_ss),
        .fnd_data         (fnd_data),
        .fnd_com          (fnd_com)
    );


endmodule
