`timescale 1ns / 1ps


module tb_master ();
    logic clk;
    logic reset;
    logic sclk;
    logic mosi;
    logic run_stop;
    logic clear;
    logic ss;

    master_top tb_master_top (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        run_stop = 0;
        clear = 0;

        #10;
        reset = 0;
        run_stop = 1;
        clear = 0;

        #10;
        run_stop = 0;

        #1000000000;
        $finish;
    end

    // task automatic spi_write(byte data);
    //     @(posedge clk);
    //     wait (tx_ready);
    //     start   = 1;
    //     tx_data = data;
    //     @(posedge clk);
    //     start = 0;
    //     wait (done);
    //     @(posedge clk);
    // endtask  //automatic

    // initial begin
    //     repeat (5) @(posedge clk);
    //     spi_write(8'hf0);
    //     spi_write(8'h0f);
    //     spi_write(8'haa);
    //     spi_write(8'h55);

    //     #20;
    //     $finish;
    // end

endmodule
