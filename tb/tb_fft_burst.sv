`timescale 1ns/1ps

module tb_fft_burst;
  import fft_pkg::*;

  localparam int FFT_LEN = 8;
  localparam int DATA_W = 16;

  logic clk;
  logic rst_n;
  logic start;
  logic in_valid;
  logic signed [DATA_W-1:0] in_real;
  logic signed [DATA_W-1:0] in_imag;
  logic in_ready;
  logic out_valid;
  logic signed [DATA_W-1:0] out_real;
  logic signed [DATA_W-1:0] out_imag;
  logic out_last;

  fft_burst #(
    .FFT_LEN(FFT_LEN),
    .DATA_W(DATA_W),
    .INVERSE(1'b0)
  ) dut (
    .clk,
    .rst_n,
    .start,
    .in_valid,
    .in_real,
    .in_imag,
    .in_ready,
    .out_valid,
    .out_real,
    .out_imag,
    .out_last
  );

  always #5 clk = ~clk;

  initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    in_valid = 0;
    in_real = '0;
    in_imag = '0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    @(posedge clk);
    start = 1;
    @(posedge clk);
    start = 0;

    for (int i = 0; i < FFT_LEN; i++) begin
      @(posedge clk);
      if (in_ready) begin
        in_valid <= 1'b1;
        in_real <= (i == 0) ? 16'sh7FFF : 16'sd0;
        in_imag <= 16'sd0;
      end
    end
    @(posedge clk);
    in_valid <= 1'b0;

    wait (out_valid);
    for (int k = 0; k < FFT_LEN; k++) begin
      @(posedge clk);
      if (out_valid) begin
        if (out_real < 16'sh7FFE || out_real > 16'sh7FFF) begin
          $fatal(1, "FFT burst output mismatch at bin %0d: %0d", k, out_real);
        end
        if (out_imag != 16'sd0) begin
          $fatal(1, "FFT burst output imag mismatch at bin %0d: %0d", k, out_imag);
        end
      end
    end
    $display("FFT burst test passed.");
    $finish;
  end
endmodule
