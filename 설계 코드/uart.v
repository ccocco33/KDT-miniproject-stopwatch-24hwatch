`timescale 1ns / 1ps
module uart_fifo_loopback (
    input  clk,
    input  rst,
    input  rx,   //from PC
    output tx    //to PC
);
    wire w_b_tick;
    wire w_rx_done;
    wire [7:0] w_rx_data, w_fifo_rx_pop_data, w_fifo_tx_pop_data;
    wire w_fifo_tx_full, w_fifo_rx_empty, w_fifo_tx_empty,w_tx_busy;
    uart_rx U_UART_RX (
        .clk    (clk),
        .rst    (rst),
        .b_tick (w_b_tick),
        .rx     (rx),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );
    fifo U_FIFO_RX (
        .clk      (clk),
        .rst      (rst),
        .push     (w_rx_done),           //from uart rx
        .pop      (~w_fifo_tx_full),
        .push_data(w_rx_data),
        .pop_data (w_fifo_rx_pop_data),
        .full     (),
        .empty    (w_fifo_rx_empty)
    );
    fifo U_FIFO_TX (
        .clk      (clk),
        .rst      (rst),
        .push     (~w_fifo_rx_empty),
        .pop      (~w_tx_busy),
        .push_data(w_fifo_rx_pop_data),
        .pop_data (w_fifo_tx_pop_data),
        .full     (w_fifo_tx_full),
        .empty    (w_fifo_tx_empty)
    );

    //uart tx
    uart_tx U_UART_TX (
        .clk     (clk),
        .rst     (rst),
        .tx_start(~w_fifo_tx_empty),
        .tx_data (w_fifo_tx_pop_data),
        .b_tick  (w_b_tick),
        .tx      (tx),
        .tx_busy (w_tx_busy)

    );

    baud_tick_gen U_BAUD_TICK_GEN (
        .clk   (clk),
        .rst   (rst),
        .b_tick(w_b_tick)
    );
endmodule
// module uart_loopback(
//     input clk,
//     input rst,
//     input rx,  //from PC
//     output tx  //to PC
// );
//     wire w_b_tick,w_rx_done;
//     wire [7:0]w_rx_data;

//     uart_rx U_UART_RX (
//         .clk    (clk),
//         .rst    (rst),
//         .b_tick (w_b_tick),
//         .rx     (rx),
//         .rx_data(w_rx_data),
//         .rx_done(w_rx_done)
//     );

//     //uart tx
//     uart_tx U_UART_TX (
//         .clk     (clk),
//         .rst     (rst),
//         .tx_start(w_rx_done),
//         .tx_data (w_rx_data),
//         .b_tick  (w_b_tick),
//         .tx      (tx),
//         .tx_busy()

//     );

//     baud_tick_gen U_BAUD_TICK_GEN (
//         .clk   (clk),
//         .rst   (rst),
//         .b_tick(w_b_tick)
//     );
// endmodule

module baud_tick_gen (
    input      clk,
    input      rst,
    output reg b_tick
);
    // parameter F_COUNT = 100_000_000 / 9600;
    parameter F_COUNT = 100_000_000 / (9600 * 16);
    reg [$clog2(F_COUNT) -1:0] counter_reg;
    //100Mhz -> 9600hz
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            b_tick      <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                b_tick      <= 1'b1;
            end else begin
                b_tick <= 1'b0;
            end
        end
    end
endmodule
