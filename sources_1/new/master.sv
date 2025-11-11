`timescale 1ns / 1ps

module master_top (
    input logic clk,
    input logic reset,

    input  logic run_stop,
    input  logic clear,
    input  logic cpol,
    input  logic cpha,
    input  logic miso,
    output logic ss,
    output logic sclk,
    output logic mosi
);
    //카운터 관련 나머지
    logic        w_counter_tick;

    //divider 관련
    logic [13:0] w_counter;
    logic [ 7:0] w_num1;
    logic [ 7:0] w_num100;

    //spi 관련
    logic        w_start;
    logic [ 7:0] w_tx_data;
    logic        w_tx_ready;
    logic        w_tx_done;

    up_counter U_COUNTER_UP (
        .clk(clk),
        .reset(reset),
        .btn_run_stop(run_stop),
        .btn_clear(clear),
        .tx_data(w_tx_data),
        .tx_start(w_start),
        .tx_ready(w_tx_ready),
        .tx_done(w_tx_done),
        .ss(ss)
    );

    spi_master U_SPI_MASTER (
        .clk     (clk),
        .reset   (reset),
        .start   (w_start),
        .cpol    (cpol),
        .cpha    (cpha),
        .tx_data (w_tx_data),
        .rx_data (),
        .tx_ready(w_tx_ready),
        .done    (w_tx_done),
        .sclk    (sclk),
        .mosi    (mosi),
        .miso    (miso)
    );

endmodule


