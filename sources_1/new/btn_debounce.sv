`timescale 1ns / 1ps


module btn_debounce (  ///////SIPO
    input  logic clk,
    input  logic rst,
    input  logic in_btn,
    output logic out_btn
);

    logic [3:0] q_reg, q_next;
    logic debounce;

    logic [$clog2(100)-1:0] counter;
    logic r_db_clk;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter  <= 0;
            r_db_clk <= 0;
        end else begin
            if (counter == 99) begin
                counter  <= 0;
                r_db_clk <= 1'b1;
            end else begin
                counter  <= counter + 1;
                r_db_clk <= 1'b0;
            end
        end
    end


    always @(posedge r_db_clk, posedge rst) begin
        if (rst) begin
            q_reg <= 4'b0000;
        end else begin
            q_reg <= q_next;
        end
    end

    always @(*) begin
        q_next = {in_btn, q_reg[3:1]};
    end

    assign debounce = &q_reg;

    logic edge_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_reg <= 0;
        end else begin
            edge_reg <= debounce;
        end
    end

    assign out_btn = ~edge_reg & debounce;


endmodule
