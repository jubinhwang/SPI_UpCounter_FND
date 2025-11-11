// `timescale 1ns / 1ps

// module spi_slave (
//     // global signals
//     input logic clk,
//     input logic rst,
//     // SPI 인터페이스 (마스터와 연결)
//     input logic sclk,
//     input logic mosi,
//     //output logic miso,
//     input logic ssn,   // Slave Select (Active Low)

//     // 내부 로직/CPU 인터페이스
//     input logic reset,  // 시스템 리셋 (Active High)
//     input  logic [7:0] tx_data_in,  // 슬레이브가 *다음* 전송에 보낼 데이터
//     output logic [7:0] rx_data_out, // 슬레이브가 *방금* 수신 완료한 데이터
//     output logic rx_done  // 1바이트 수신 완료 시 1클럭 펄스
// );

//     edge_detector U_Edge_Detector(
//         .clk(clk),
//         .rst(rst),
//         .sclk(sclk),  
//         .rise_pulse(w_sclk)  
//     );

//     // --- 내부 레지스터 ---
//     // 송신측 로직 (negedge sclk 동기)
//     logic [7:0] tx_shift_reg;
//     logic       miso_bit;

//     // 수신측 로직 (posedge sclk 동기)
//     logic [7:0] rx_shift_reg;
//     logic [2:0] bit_counter;

//     // MISO 출력 로직
//     //assign miso = (ssn == 0) ? miso_bit : 1'bz;

//     // --- 수신(Receive) 로직 ---
//     // (posedge sclk에 동기화, reset 또는 ssn=1일 때 비동기 리셋)
//     always_ff @(posedge w_sclk, posedge reset, posedge ssn) begin
//         if (reset) begin  // 1. 시스템 리셋 (최우선)
//             rx_shift_reg <= 0;
//             bit_counter  <= 0;
//             rx_data_out  <= 0;  // rx_data_out도 리셋
//             rx_done      <= 0;
//         end else if (ssn) begin  // 2. 트랜잭션 종료 (ssn=1)
//             bit_counter  <= 0;  // 다음을 위해 카운터 리셋
//             rx_shift_reg <= 0;  // 다음을 위해 쉬프터 리셋
//             rx_done      <= 0;  // 펄스 클리어
//         end else begin  // 3. 트랜잭션 진행 (ssn=0)
//             rx_shift_reg <= {rx_shift_reg[6:0], mosi};
//             bit_counter  <= bit_counter + 1;
//             rx_done      <= 1'b0;  // 기본값

//             if (bit_counter == 7) begin
//                 rx_data_out <= {
//                     rx_shift_reg[6:0], mosi
//                 };  // 8비트 완료 시 저장
//                 rx_done <= 1'b1;  // 완료 펄스 생성
//             end
//         end
//     end

//     // // --- 송신(Transmit) 로직 ---
//     // // (negedge sclk에 동기화, reset 또는 ssn=1일 때 비동기 리셋/로드)
//     // always_ff @(negedge sclk, posedge reset, posedge ssn) begin
//     //     if (reset) begin // 1. 시스템 리셋
//     //         tx_shift_reg <= 0;
//     //         miso_bit     <= 0;
//     //     end else if (ssn) begin // 2. 트랜잭션 종료 (ssn=1)
//     //         tx_shift_reg <= tx_data_in;   // *다음* 전송을 위해 데이터 미리 로드
//     //         miso_bit     <= tx_data_in[7]; // *다음* 전송의 첫 비트 미리 설정
//     //     end else begin // 3. 트랜잭션 진행 (ssn=0)
//     //         tx_shift_reg <= {tx_shift_reg[6:0], 1'b0}; // 쉬프트
//     //         miso_bit     <= tx_shift_reg[7];          // 현재 비트 출력
//     //     end
//     // end

// endmodule

// module edge_detector (
//     input  logic clk,
//     input  logic rst,
//     input  logic sclk,  
//     output logic rise_pulse  
// );
//     logic sclk_sync0, sclk_sync1;

//     always_ff @(posedge clk or posedge rst) begin
//         if (rst) begin
//             sclk_sync0 <= 1'b0;
//             sclk_sync1 <= 1'b0;
//         end else begin
//             sclk_sync0 <= sclk;
//             sclk_sync1 <= sclk_sync0;
//         end
//     end

//     always_ff @(posedge clk or posedge rst) begin
//         if (rst) rise_pulse <= 1'b0;
//         else     rise_pulse <= (sclk_sync0 & ~sclk_sync1);
//     end
// endmodule

`timescale 1ns / 1ps

module spi_slave (
    // global signals
    input  logic       clk,
    input  logic       reset,
    // SPI External port
    input  logic       sclk,
    input  logic       mosi,
    output logic       miso,
    input  logic       cs,
    // Internal signals
    output logic [7:0] si_data,   // rx_data
    output logic       si_done,   // rx_done
    input  logic [7:0] so_data,   // tx_data
    input  logic       so_start,  // tx_start
    output logic       so_ready   // tx_ready
);
    /////////////////// Synchronizer Edge Detector //////////////////
    logic sclk_sync0, sclk_sync1;
    logic sclk_rising_edge, sclk_falling_edge;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            sclk_sync0 <= 0;
            sclk_sync1 <= 0;
        end else begin
            sclk_sync0 <= sclk;
            sclk_sync1 <= sclk_sync0;
        end
    end

    assign sclk_rising_edge  = sclk_sync0 & ~(sclk_sync1);
    assign sclk_falling_edge = ~(sclk_sync0) & sclk_sync1;

    /////////////////// Slave In Sequence ////////////////////////////
    logic si_done_reg, si_done_next;
    logic [2:0] si_bit_cnt_reg, si_bit_cnt_next;
    logic [7:0] si_data_reg, si_data_next;

    assign si_data = si_data_reg;
    assign si_done = si_done_reg;

    typedef enum {
        SI_IDLE,
        SI_PHASE
    } si_state_e;

    si_state_e si_state, si_state_next;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            si_state       <= SI_IDLE;
            si_bit_cnt_reg <= 0;
            si_data_reg    <= 0;
            si_done_reg    <= 0;
        end else begin
            si_state       <= si_state_next;
            si_bit_cnt_reg <= si_bit_cnt_next;
            si_data_reg    <= si_data_next;
            si_done_reg    <= si_done_next;
        end
    end

    always_comb begin
        si_state_next   = si_state;
        si_bit_cnt_next = si_bit_cnt_reg;
        si_data_next    = si_data_reg;
        si_done_next    = si_done_reg;
        case (si_state)
            SI_IDLE: begin
                si_done_next = 1'b0;
                if (!cs) begin
                    si_state_next   = SI_PHASE;
                    si_bit_cnt_next = 0;
                end
            end
            SI_PHASE: begin
                if (!cs) begin
                    if (sclk_rising_edge) begin
                        si_data_next = {si_data_reg[6:0], mosi};
                        if (si_bit_cnt_reg == 7) begin
                            si_bit_cnt_next = 0;
                            si_state_next   = SI_IDLE;
                            si_done_next    = 1'b1;
                        end else begin
                            si_bit_cnt_next = si_bit_cnt_reg + 1;
                        end
                    end
                end else begin
                    si_state_next = SI_IDLE;
                end
            end
        endcase
    end
    //////////////// Slave Out Sequence //////////////////////////////

    logic [2:0] so_bit_cnt_reg, so_bit_cnt_next;
    logic [7:0] so_data_reg, so_data_next;

    assign miso = cs ? 1'hz : so_data_reg[7];

    typedef enum {
        SO_IDLE,
        SO_PHASE
    } so_state_e;

    so_state_e so_state, so_state_next;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            so_state       <= SO_IDLE;
            so_bit_cnt_reg <= 0;
            so_data_reg    <= 0;
        end else begin
            so_state       <= so_state_next;
            so_bit_cnt_reg <= so_bit_cnt_next;
            so_data_reg    <= so_data_next;
        end
    end

    always_comb begin
        so_state_next   = so_state;
        so_bit_cnt_next = so_bit_cnt_reg;
        so_data_next    = so_data_reg;
        so_ready        = 1'b0;
        case (so_state)
            SO_IDLE: begin
                so_ready = 1'b0;
                if (!cs) begin
                    so_ready = 1'b1;
                    if (so_start) begin
                        so_state_next   = SO_PHASE;
                        so_data_next    = so_data;
                        so_bit_cnt_next = 0;
                    end
                end
            end
            SO_PHASE: begin
                if (!cs) begin
                    so_ready = 1'b0;
                    if (sclk_falling_edge) begin
                        so_data_next = {so_data_reg[6:0], 1'b0};
                        if (so_bit_cnt_reg == 7) begin
                            so_bit_cnt_next = 0;
                            so_state_next   = SO_IDLE;
                        end else begin
                            so_bit_cnt_next = so_bit_cnt_reg + 1;
                        end
                    end
                end else begin
                    so_state_next = SO_IDLE;
                end
            end
        endcase
    end
endmodule

