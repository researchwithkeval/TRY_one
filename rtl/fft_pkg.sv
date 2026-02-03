package fft_pkg;
  parameter int FFT_LEN = 8;
  parameter int DATA_W = 16;
  parameter int TWIDDLE_W = 16;

  localparam int SCALE_BITS = $clog2(FFT_LEN);

  function automatic signed [DATA_W-1:0] round_shift(
    input signed [DATA_W+TWIDDLE_W+4:0] value
  );
    signed [DATA_W+TWIDDLE_W+4:0] rounded;
    rounded = value + (1 <<< (TWIDDLE_W-1));
    round_shift = rounded[DATA_W+TWIDDLE_W+4:TWIDDLE_W];
  endfunction
endpackage
