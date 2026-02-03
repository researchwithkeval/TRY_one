#!/usr/bin/env python3
import argparse
import math


def quantize_q15(value: float) -> int:
    scaled = int(round(value * (1 << 15)))
    if scaled > 0x7FFF:
        scaled = 0x7FFF
    if scaled < -0x8000:
        scaled = -0x8000
    return scaled


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate twiddle ROMs.")
    parser.add_argument("--fft-len", type=int, default=8)
    parser.add_argument("--out-re", required=True)
    parser.add_argument("--out-im", required=True)
    args = parser.parse_args()

    re_lines = []
    im_lines = []
    for k in range(args.fft_len):
        angle = 2 * math.pi * k / args.fft_len
        re = math.cos(angle)
        im = -math.sin(angle)
        re_q = quantize_q15(re)
        im_q = quantize_q15(im)
        re_lines.append(f"{re_q & 0xFFFF:04X}")
        im_lines.append(f"{im_q & 0xFFFF:04X}")

    with open(args.out_re, "w", encoding="utf-8") as f:
        f.write("\n".join(re_lines) + "\n")
    with open(args.out_im, "w", encoding="utf-8") as f:
        f.write("\n".join(im_lines) + "\n")


if __name__ == "__main__":
    main()
