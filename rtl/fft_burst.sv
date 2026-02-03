`timescale 1ns/1ps

module fft_burst #(
  parameter int FFT_LEN = 8,
  parameter int DATA_W = 16,
  parameter bit INVERSE = 1'b0
) (
  input  logic                     clk,
  input  logic                     rst_n,
  input  logic                     start,
  input  logic                     in_valid,
  input  logic signed [DATA_W-1:0] in_real,
  input  logic signed [DATA_W-1:0] in_imag,
  output logic                     in_ready,
  output logic                     out_valid,
  output logic signed [DATA_W-1:0] out_real,
  output logic signed [DATA_W-1:0] out_imag,
  output logic                     out_last
);
  import fft_pkg::*;

  localparam int ADDR_W = $clog2(FFT_LEN);
  localparam int ACC_W = DATA_W + TWIDDLE_W + 5;

  typedef enum logic [1:0] {
    IDLE,
    COLLECT,
    COMPUTE,
    OUTPUT
  } state_t;

  state_t state;

  logic signed [DATA_W-1:0] sample_re [0:FFT_LEN-1];
  logic signed [DATA_W-1:0] sample_im [0:FFT_LEN-1];
  logic signed [DATA_W-1:0] out_re_mem [0:FFT_LEN-1];
  logic signed [DATA_W-1:0] out_im_mem [0:FFT_LEN-1];

  int unsigned sample_count;
  int unsigned k_idx;
  int unsigned n_idx;
  int unsigned out_idx;

  logic signed [ACC_W-1:0] acc_re;
  logic signed [ACC_W-1:0] acc_im;

  function automatic signed [DATA_W-1:0] apply_scale(
    input signed [ACC_W-1:0] value
  );
    signed [ACC_W-1:0] scaled;
    if (INVERSE) begin
      scaled = value >>> SCALE_BITS;
    end else begin
      scaled = value;
    end
    apply_scale = round_shift(scaled);
  endfunction

  logic signed [TWIDDLE_W-1:0] tw_re;
  logic signed [TWIDDLE_W-1:0] tw_im_val;
  logic signed [DATA_W-1:0] x_re;
  logic signed [DATA_W-1:0] x_im;
  logic signed [DATA_W+TWIDDLE_W-1:0] mult_re;
  logic signed [DATA_W+TWIDDLE_W-1:0] mult_im;
  logic [ADDR_W-1:0] tw_addr;
  logic signed [TWIDDLE_W-1:0] tw_im_raw;
  int unsigned tw_index;

  always_comb begin
    tw_index = (k_idx * n_idx) % FFT_LEN;
  end

  assign tw_addr = tw_index[ADDR_W-1:0];
  assign tw_im_val = INVERSE ? -tw_im_raw : tw_im_raw;
  assign x_re = sample_re[n_idx];
  assign x_im = sample_im[n_idx];
  assign mult_re = (x_re * tw_re) - (x_im * tw_im_val);
  assign mult_im = (x_re * tw_im_val) + (x_im * tw_re);

  twiddle_rom #(
    .FFT_LEN(FFT_LEN),
    .TWIDDLE_W(TWIDDLE_W)
  ) twiddle_lut (
    .addr(tw_addr),
    .tw_re(tw_re),
    .tw_im(tw_im_raw)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      sample_count <= 0;
      k_idx <= 0;
      n_idx <= 0;
      out_idx <= 0;
      acc_re <= '0;
      acc_im <= '0;
      out_valid <= 1'b0;
      out_last <= 1'b0;
    end else begin
      out_valid <= 1'b0;
      out_last <= 1'b0;
      case (state)
        IDLE: begin
          if (start) begin
            sample_count <= 0;
            state <= COLLECT;
          end
        end
        COLLECT: begin
          if (in_valid && in_ready) begin
            sample_re[sample_count] <= in_real;
            sample_im[sample_count] <= in_imag;
            sample_count <= sample_count + 1;
            if (sample_count == FFT_LEN-1) begin
              k_idx <= 0;
              n_idx <= 0;
              acc_re <= '0;
              acc_im <= '0;
              state <= COMPUTE;
            end
          end
        end
        COMPUTE: begin
          acc_re <= acc_re + mult_re;
          acc_im <= acc_im + mult_im;

          if (n_idx == FFT_LEN-1) begin
            out_re_mem[k_idx] <= apply_scale(acc_re + mult_re);
            out_im_mem[k_idx] <= apply_scale(acc_im + mult_im);
            acc_re <= '0;
            acc_im <= '0;
            n_idx <= 0;
            if (k_idx == FFT_LEN-1) begin
              out_idx <= 0;
              state <= OUTPUT;
            end else begin
              k_idx <= k_idx + 1;
            end
          end else begin
            n_idx <= n_idx + 1;
          end
        end
        OUTPUT: begin
          out_valid <= 1'b1;
          out_real <= out_re_mem[out_idx];
          out_imag <= out_im_mem[out_idx];
          out_last <= (out_idx == FFT_LEN-1);
          if (out_idx == FFT_LEN-1) begin
            state <= IDLE;
          end else begin
            out_idx <= out_idx + 1;
          end
        end
        default: state <= IDLE;
      endcase
    end
  end

  assign in_ready = (state == COLLECT);

endmodule
