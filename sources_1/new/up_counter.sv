`timescale 1ns / 1ps

module up_counter (
    input  logic       clk,
    input  logic       reset,
    //
    input  logic       btn_run_stop,
    input  logic       btn_clear,
    //
    output logic [7:0] tx_data,
    output logic       tx_start,
    input  logic       tx_ready,
    input  logic       tx_done,
    output logic       ss
);

    //debounce 관련
    logic w_db_run, w_db_clr;
    //cu 관련
    logic w_run, w_clr;
    logic w_counter_tick;
    //divider 관련
    logic [13:0] w_counter;
    logic [7:0] w_num1;
    logic [7:0] w_num100;


    btn_debounce U_DB_RUN (
        .clk(clk),
        .rst(reset),
        .in_btn(btn_run_stop),
        .out_btn(w_db_run)
    );

    btn_debounce U_DB_CLR (
        .clk(clk),
        .rst(reset),
        .in_btn(btn_clear),
        .out_btn(w_db_clr)
    );

    counter_cmd_unit U_COUNTER_CU (
        .clk(clk),
        .rst(reset),
        .btn_en(w_db_run),
        .btn_clr(w_db_clr),
        .run_stop(w_run),
        .clear_p(w_clr)
    );

    counter U_COUNTER (     /////// CLEAR, RUN/STOP 기능 있는 10000진 카운터
        .clk         (clk),
        .rst         (reset),
        .clear       (w_clr),
        .run_stop    (w_run),
        .counter_data(w_counter),
        .counter_tick(w_counter_tick)
    );

    count_divder U_CNT_DIVIDER (    ////카운터 값을 천-백의자리, 십-일의자리 수로 8비트 씩 두자리수 2개
        .count (w_counter),
        .num100(w_num100),
        .num1  (w_num1)
    );

    num_sender U_NUM_SENDER (  ///신호에 따라 수 두개 전달
        .clk         (clk),
        .reset       (reset),
        .num100      (w_num100),
        .num1        (w_num1),
        .ready       (tx_ready),
        .done        (tx_done),
        .counter_tick(w_counter_tick),
        .tx_num      (tx_data),
        .start       (tx_start),
        .ss          (ss)
    );

endmodule



module count_divder (
    input  logic [13:0] count,
    output logic [ 7:0] num100,
    output logic [ 7:0] num1
);

    assign num100 = count / 100;
    assign num1   = count % 100;

endmodule



module num_sender (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] num100,
    input  logic [7:0] num1,
    input  logic       ready,
    input  logic       done,
    input  logic       counter_tick,
    output logic [7:0] tx_num,
    output logic       start,
    output logic       ss
);
    typedef enum {
        IDLE,
        NUM100,
        NUM1
    } state;

    state c_state, n_state;

    logic [7:0] c_set_num100, n_set_num100;
    logic [7:0] c_set_num1, n_set_num1;
    logic c_ss, n_ss;
    logic c_start, n_start;

    assign ss = c_ss;
    assign start = c_start;

    always_ff @(posedge clk) begin
        if (reset) begin
            c_state      <= IDLE;
            c_set_num100 <= 0;
            c_set_num1   <= 0;
            c_ss         <= 0;
            c_start      <= 0;
        end else begin
            c_state      <= n_state;
            c_set_num100 <= n_set_num100;
            c_set_num1   <= n_set_num1;
            c_ss         <= n_ss;
            c_start      <= n_start;
        end
    end

    always_comb begin
        tx_num       = 8'hzz;
        n_state      = c_state;
        n_set_num100 = c_set_num100;
        n_set_num1   = c_set_num1;
        n_ss         = c_ss;
        n_start      = c_start;

        case (c_state)
            IDLE: begin
                n_start = 1'b0;
                n_ss = 1'b1;
                if (ready) begin
                    n_set_num100 = num100;
                    n_set_num1   = num1;
                    n_state      = NUM100;
                    n_ss         = 1'b0;
                    n_start      = 1'b1;
                end
            end
            NUM100: begin
                n_start = 1'b0;
                tx_num  = c_set_num100;
                if (done) begin
                    n_state = NUM1;
                    n_start = 1'b1;
                end
            end
            NUM1: begin
                n_start = 1'b0;
                tx_num  = c_set_num1;
                if (done) begin
                    n_ss    = 1'b1;
                    n_state = IDLE;
                end
            end
        endcase
    end
endmodule


module counter_cmd_unit (
    input clk,
    input rst,
    input btn_en,  // run/stop 토글 버튼 (디바운스 레벨)
    input btn_clr, // clear 버튼

    output reg run_stop,  // 1=RUN
    output reg clear_p    // 1clk
);
    // 버튼 상승엣지 검출
    reg br_d, bc_d;
    wire b_run_p = btn_en & ~br_d;  // run/stop 토글
    wire b_clr_p = btn_clr & ~bc_d;  // clear 1클럭

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            br_d <= 1'b0;
            bc_d <= 1'b0;
        end else begin
            br_d <= btn_en;
            bc_d <= btn_clr;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            run_stop <= 1'b1;
            clear_p  <= 1'b0;
        end else begin
            clear_p <= 1'b0;
            if (b_clr_p) clear_p <= 1'b1;
            if (b_run_p) run_stop <= ~run_stop;
        end
    end
endmodule
