`timescale 1ns / 1ps

//오차 발생 시키기
module tb_uart_nonpass ();
    parameter BAUD_BIT_PERIOD = 100_000_000 / 9600 * 10;  //1M /9600* 10clk

    reg clk, rst, rx;
    reg [7:0] result_data, expected_data;
    wire tx;
    integer i, j;
    integer pass_count, fail_count;
    real bit_period;
    uart_fifo_loopback dut (
        .clk(clk),
        .rst(rst),
        .rx (rx),
        .tx (tx)
    );
    always #5 clk = ~clk;

    task sender_uart(input [7:0] send_data);
        integer i;
        begin
            rx = 0;
            #(bit_period);
            for (i = 0; i < 8; i = i + 1) begin
                rx = send_data[i];
                #(bit_period);
            end
            rx = 1;  //stop bit
            #(bit_period);
        end
    endtask
    task receive_uart(output [7:0] rx_data);
        integer i;
        begin
            wait (~tx);
            #(BAUD_BIT_PERIOD / 2);
            //check start bit 0
            // if (tx != 0) $display("[receive tx] error start bit");
            for (i = 0; i < 8; i = i + 1) begin
                #(BAUD_BIT_PERIOD);
                rx_data[i] = tx;
            end
            #(BAUD_BIT_PERIOD);
            // if (!tx) $display("[receive tx] error stop bit");
        end
    endtask

    task score_board(input [7:0] result, expected);
        begin
            //to compare result data and
            if (result == expected) begin
                pass_count = pass_count + 1;
                // $display("[result] %t: pass", $time);
            end else begin
                fail_count = fail_count + 1;
                // $display("[result] %t: fail", $time);
            end
        end
    endtask
    initial begin
        clk = 0;
        rst = 1;
        rx = 1;
        i = 0;
        j = 0;
        pass_count = 0;
        fail_count = 0;
        for (j = -52; j < -45; j = j + 1) begin
            pass_count = 0;
            fail_count = 0;
            bit_period = BAUD_BIT_PERIOD * (1.0 + j / 1000.0);
            rst = 1;
            rx = 1;
            #100 rst = 0;
            #(BAUD_BIT_PERIOD * 2);  // 안정화 대기
            for (i = 0; i < 256; i = i + 1) begin
                #10 rst = 0;
                expected_data = $random() % 256;
                // $display("j: %d",j);
                // expected_data = 8'b01010101;
                // #({$random} % 6510);
                fork
                    begin
                        sender_uart(expected_data);
                    end
                    begin
                        receive_uart(result_data);
                    end
                join
                score_board(result_data, expected_data);
                #100;
            end
            #1000;
            $display("--------------report -------------");
            // $display("bit_period = %d", BAUD_BIT_PERIOD * (1.0 + j / 100.0));
            $display("skew = %0f%%, bit_period = %0.1f ns", j / 10.0,
                     bit_period);
            $display("total test num = %d", i);
            $display("Pass count = %d", pass_count);
            $display("fail count = %d", fail_count);
        end
        $stop;
    end
endmodule
