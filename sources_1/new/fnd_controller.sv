`timescale 1ns / 1ps


module fnd_controller (
    input rst,
    input clk,
    input [13:0] counter,

    output [3:0] fnd_com,
    output [7:0] fnd_data
);

    wire w_clk_1khz;
    wire [1:0] w_sel;

    wire [3:0] w_num_1;
    wire [3:0] w_num_10;
    wire [3:0] w_num_100;
    wire [3:0] w_num_1000;
    wire [3:0] w_bcd;


    clk_div U_DIV (
        .clk (clk),
        .rst (rst),
        .o_clk(w_clk_1khz)
    );

    counter_4 U_COUNTER_4 (
        .clk (w_clk_1khz),
        .rst (rst),
        .count_reg (w_sel)
    );

    decoder_2x4 U_DECODER_2X4 (
        .sel(w_sel),
        .fnd_com(fnd_com)
    );

    digit_spliter U_SPLITER (
        .num(counter),

        .num_1(w_num_1),
        .num_10(w_num_10),
        .num_100(w_num_100),
        .num_1000(w_num_1000)
    );

    mux_4x1 U_4X1_MUX (
        .sel(w_sel),
        .digit_1(w_num_1),
        .digit_10(w_num_10),
        .digit_100(w_num_100),
        .digit_1000(w_num_1000),

        .o_bcd(w_bcd)
    );

    bcd U_BCD (
        .bcd(w_bcd),
        .fnd_data(fnd_data)
    );

endmodule

module clk_div (
    input  clk,
    input  rst,
    output o_clk
);
    parameter COUNT = 100_000_000 / 1000;
    reg [$clog2(COUNT)-1:0] count;
    reg tick;

    assign o_clk = tick;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            tick  <= 1'b0;
        end else begin
            if (count == COUNT - 1) begin
                count <= 0;
                tick  <= 1'b1;
            end else begin
                count <= count + 1;
                tick  <= 1'b0;
            end
        end
    end

endmodule

module counter_4 (
    input clk,
    input rst,
    output reg [1:0] count_reg
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count_reg <= 0;
        end else begin
            count_reg <= count_reg + 1;
        end
    end
endmodule

module decoder_2x4 (
    input [1:0] sel,
    output reg [3:0] fnd_com
);
    always @(*) begin
        case (sel)
            2'b00:   fnd_com = 4'b1110;
            2'b01:   fnd_com = 4'b1101;
            2'b10:   fnd_com = 4'b1011;
            2'b11:   fnd_com = 4'b0111;
            default: fnd_com = 4'b1110;
        endcase
    end

endmodule

module digit_spliter (
    input  [13:0] num,
    output [ 3:0] num_1,
    output [ 3:0] num_10,
    output [ 3:0] num_100,
    output [ 3:0] num_1000
);
    assign num_1000 = num / 1000;
    assign num_100 = (num % 1000) / 100;
    assign num_10 = (num % 100) / 10;
    assign num_1 = (num % 10);
endmodule

module mux_4x1 (
    input [1:0] sel,
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,

    output [3:0] o_bcd
);

    reg [3:0] bcd_reg;
    assign o_bcd = bcd_reg;

    always @(*) begin
        case (sel)
            2'b00:   bcd_reg = digit_1;
            2'b01:   bcd_reg = digit_10;
            2'b10:   bcd_reg = digit_100;
            2'b11:   bcd_reg = digit_1000;
            default: bcd_reg = digit_1;
        endcase
    end

endmodule

module bcd (
    input [3:0] bcd,
    output reg [7:0] fnd_data
);
    always @(bcd) begin
        case (bcd)
            4'b0000: fnd_data = 8'hc0;
            4'b0001: fnd_data = 8'hF9;
            4'b0010: fnd_data = 8'hA4;
            4'b0011: fnd_data = 8'hB0;
            4'b0100: fnd_data = 8'h99;
            4'b0101: fnd_data = 8'h92;
            4'b0110: fnd_data = 8'h82;
            4'b0111: fnd_data = 8'hF8;
            4'b1000: fnd_data = 8'h80;
            4'b1001: fnd_data = 8'h90;
            4'b1010: fnd_data = 8'h88;
            4'b1011: fnd_data = 8'h83;
            4'b1100: fnd_data = 8'hc6;
            4'b1101: fnd_data = 8'ha1;
            4'b1110: fnd_data = 8'h7f;
            4'b1111: fnd_data = 8'hff;
            default: fnd_data = 8'hff;
        endcase

    end
endmodule
