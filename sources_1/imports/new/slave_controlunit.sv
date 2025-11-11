`timescale 1ns / 1ps

module slave_controlunit (
    input logic clk,
    input logic reset,
    input logic [7:0] rx_data,  // SPI 슬레이브에서 8비트씩 들어옴
    input logic done,  // SPI 8비트 수신 완료 펄스
    input logic ssn,
    output logic [13:0] data   // FND에 표시할 최종 "이진수 값" (0~9999)
);

    typedef enum {
        IDLE,
        WAIT_LOW_BYTE
    } state_t;
    state_t state, state_next;

    // FND에 표시될 최종 값 (0~9999). 14비트면 충분 (최대 16383).
    logic [13:0] data_reg, data_next;

    // 첫 번째 SPI 전송에서 받은 값 (천/백의 자리, 0~99)
    // 7비트(0~127)면 0~99를 저장하기에 충분합니다.
    logic [6:0] high_val_reg, high_val_next;

    // 'done' 펄스 엣지 감지 로직
    logic done_delay;
    logic done_rising_edge;

    assign data = data_reg;  // 최종 14비트 "값" 출력

    always_ff @(posedge clk) begin
        done_delay <= done;
    end
    assign done_rising_edge = done && !done_delay;

    // FSM 상태 및 데이터 레지스터
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            high_val_reg <= 0;
            data_reg     <= 0;
        end else begin
            state        <= state_next;
            high_val_reg <= high_val_next;
            data_reg     <= data_next;
        end
    end

    // FSM 로직 (Combinational Logic)
    always_comb begin
        // 기본적으로 현재 값 유지
        state_next = state;
        high_val_next = high_val_reg;
        data_next     = data_reg; // 이전 값 유지 (FND 값이 갑자기 0이 되지 않도록)

        case (state)
            IDLE: begin
                // 첫 번째 바이트 (천/백의 자리, 0~99)를 기다림
                if (done_rising_edge) begin
                    // 8비트 중 하위 7비트(0~99 값)를 저장
                    high_val_next = rx_data[6:0];
                    state_next    = WAIT_LOW_BYTE;
                end
            end

            WAIT_LOW_BYTE: begin
                // 두 번째 바이트 (십/일의 자리, 0~99)를 기다림
                if (ssn) begin
                    state_next = IDLE;
                end else if (done_rising_edge) begin
                    data_next  = (high_val_reg * 100) + rx_data[6:0];
                    state_next = IDLE;  // 계산 완료 후 다시 IDLE로
                end
            end
        endcase
    end
endmodule
