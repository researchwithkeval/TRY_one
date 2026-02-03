`timescale 1ns/1ps

module twiddle_rom #(
  parameter int FFT_LEN = 8,
  parameter int TWIDDLE_W = 16,
  parameter string RE_FILE = "rtl/twiddle_8_re.mem",
  parameter string IM_FILE = "rtl/twiddle_8_im.mem"
) (
  input  logic [$clog2(FFT_LEN)-1:0] addr,
  output logic signed [TWIDDLE_W-1:0] tw_re,
  output logic signed [TWIDDLE_W-1:0] tw_im
);
  logic signed [TWIDDLE_W-1:0] rom_re [0:FFT_LEN-1];
  logic signed [TWIDDLE_W-1:0] rom_im [0:FFT_LEN-1];

  initial begin
    $readmemh(RE_FILE, rom_re);
    $readmemh(IM_FILE, rom_im);
  end

  always_comb begin
    tw_re = rom_re[addr];
    tw_im = rom_im[addr];
  end
endmodule
