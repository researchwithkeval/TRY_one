# FPGA-Compatible FFT/IFFT (Burst + Streaming)

This repository provides a small, synthesizable fixed-point FFT/IFFT reference design with **burst** and **streaming** dataflow variants. The intent is **block-level feasibility** and **fixed-point/dataflow exploration** for FPGA workflows (Vivado, EDA Playground) rather than a full 5G NR production FFT engine.

## What this design is (and is not)

- ✅ **Synthesizable RTL** (SystemVerilog) targeted to FPGA-friendly flows.
- ✅ **Fixed-point modeling** with rounding and optional IFFT scaling.
- ✅ **Burst and streaming** interfaces to compare dataflow/latency behavior.
- ❌ **Not a full 5G NR FFT engine**. Only an **8-point** twiddle ROM is provided by default. 5G NR requires larger sizes (128…4096) and additional system-level framing (CP insertion/removal, windowing, etc.).

To use this for 5G NR numerologies, you must generate twiddle ROMs for the desired FFT size and adjust parameters accordingly.

## File overview

- `rtl/fft_pkg.sv` — shared fixed-point helper (`round_shift`) and parameters.
- `rtl/fft_burst.sv` — burst-mode FFT/IFFT (collect frame → compute → output).
- `rtl/fft_streaming.sv` — streaming FFT/IFFT with ready/valid and `in_last` framing.
- `rtl/twiddle_rom.sv` — ROM wrapper used by both implementations.
- `rtl/twiddle_8_re.mem`, `rtl/twiddle_8_im.mem` — default Q1.15 twiddle ROM for FFT_LEN=8.
- `tb/tb_fft_burst.sv`, `tb/tb_fft_streaming.sv` — impulse-response tests.
- `scripts/gen_twiddle.py` — helper to generate twiddle ROMs for larger FFT sizes.

## Generating twiddles for 5G NR FFT sizes

Use the generator to create new ROMs (example for FFT_LEN=256):

```bash
python3 scripts/gen_twiddle.py --fft-len 256 --out-re rtl/twiddle_256_re.mem --out-im rtl/twiddle_256_im.mem
```

Then update the ROM parameters in your top-level instantiation or override the ROM file paths in `twiddle_rom.sv`.

## Vivado setup (synthesis + simulation)

1. **Create a project** in Vivado.
2. **Add RTL sources**:
   - `rtl/fft_pkg.sv`
   - `rtl/twiddle_rom.sv`
   - `rtl/fft_burst.sv` (or `rtl/fft_streaming.sv`)
   - Twiddle mem files (`rtl/twiddle_8_re.mem`, `rtl/twiddle_8_im.mem`)
3. **For simulation**, add the testbench (e.g., `tb/tb_fft_burst.sv`).
4. **Set top module** in simulation to the testbench.
5. **Run behavioral simulation**.

> Note: Ensure the ROM `.mem` files are in the simulation working directory or add them as simulation sources so `$readmemh` can locate them.

## EDA Playground setup (simulation)

1. Select **SystemVerilog** as the language.
2. Paste/add these files:
   - `rtl/fft_pkg.sv`
   - `rtl/twiddle_rom.sv`
   - `rtl/fft_burst.sv` (or `rtl/fft_streaming.sv`)
   - `tb/tb_fft_burst.sv` (or `tb/tb_fft_streaming.sv`)
3. Add the `.mem` contents as additional files (`twiddle_8_re.mem`, `twiddle_8_im.mem`).
4. Choose a simulator (e.g., **Icarus** or **Questa** if available).
5. Run the simulation.

## How to verify correctness

The provided testbenches apply a **unit impulse** input (`x[0] = 1`, others 0). The expected FFT output is:

- **All bins equal to 1** (within fixed-point rounding tolerance).
- **Imaginary part = 0** for all bins.

The testbenches check these conditions and will `fatal` if they fail.

For a stronger check, you can:

- Apply a single-tone input and confirm one dominant bin.
- Compare against a reference FFT (MATLAB/Python) using the same fixed-point scaling.

## Notes on 5G NR compatibility

To target 5G NR FFT sizes and latency/throughput requirements, you will likely need:

- Larger FFT sizes (e.g., 128/256/512/1024/2048/4096).
- Pipelined or radix-2/4 streaming architectures for throughput.
- Carefully tuned scaling schedules to avoid overflow.
- Integration with CP insertion/removal and windowing (system-level blocks).

This repo is designed to support **early block-level feasibility** and fixed-point exploration, not final production deployment.
