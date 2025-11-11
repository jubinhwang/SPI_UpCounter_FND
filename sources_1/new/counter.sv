`timescale 1ns / 1ps
module counter (
    input  logic        clk,
    input  logic        rst,
    input  logic        clear,
    input  logic        run_stop,
    output logic [13:0] counter_data,
    output logic        counter_tick
);
    logic w_tick_clk_10hz;

    counter_dp U_COUNTER_10000 (
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick_clk_10hz),
        .clear(clear),
        .run_stop(run_stop),
        .count(counter_data),
        .counter_tick(counter_tick)
    );

    clk_div_tick_10Hz U_CLK_DIV_10hz (
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .run_stop(run_stop),
        .clk_out(w_tick_clk_10hz)
    );


endmodule

module clk_div_tick_10Hz (
    input  logic clk,
    input  logic rst,
    input  logic run_stop,
    input  logic clear,
    output logic clk_out
);
    // parameter COUNT = 1_000;
    parameter COUNT = 10_000_000;
    logic [$clog2(COUNT)-1:0] count;


    always @(posedge clk or posedge rst) begin
        if (rst || clear) begin
            count   <= 0;
            clk_out <= 0;
        end else begin
            if (~run_stop) begin
                count   <= count;
                clk_out <= clk_out;
            end else if (count == COUNT - 1) begin
                count   <= 0;
                clk_out <= 1;
            end else begin
                count   <= count + 1;
                clk_out <= 0;
            end
        end
    end
endmodule


module counter_dp (
    input logic clk,
    input logic rst,
    input logic i_tick,
    input logic clear,
    input logic run_stop,
    output logic [13:0] count,
    output logic counter_tick
);

    always @(posedge clk or posedge rst) begin
        if (rst || clear) begin
            count <= 0;
            counter_tick <= 0;
        end else begin
            if (i_tick) begin
                if (run_stop == 0) begin
                    count <= count;
                end else begin
                    if (count == 10000 - 1) begin
                        count <= 0;
                        counter_tick <= 1;
                    end else begin
                        count <= count + 1;
                        counter_tick <= 0;
                    end
                end
            end
        end
    end
endmodule
