# References and attribution

## TMDS encoding

Both HDMI encoders and their reference test use the encoding flow from
[Project F](https://github.com/projf/display_controller/blob/master/rtl/tmds_encoder_dvi.v),
by Will Green (2019, MIT). The local implementation uses a loop for transition
reduction and complete-symbol disparity. The original MIT notice is below.

## Font

`rtl/peripherals/hdmi/fonts/NICER40C.F16` is an unmodified bitmap font by
VileR, from [VGA Text Mode Fonts](https://github.com/viler-int10h/vga-text-mode-fonts).
`NICER40C.hex` contains the same bytes converted to hexadecimal text.
See the [author's description](https://int10h.org/blog/2019/05/de-uglifying-40-column-text-games-for-vga/).
The project's MIT license does not cover this asset; a specific license for
the raw binary file has not been confirmed.

## Gowin firmware repack

The FS frame/CRC and BSRAM fuse-layout references are
[Project Apicula](https://github.com/YosysHQ/apicula), particularly
`bslib.py` and `gowin_pack.py`. The repacker uses its installed device database.

## Board and primitive references

- [Sipeed Tang Nano 9K HDMI example](https://github.com/sipeed/TangNano-9K-example/tree/main/hdmi/src):
  reference for HDMI pair assignments, drive settings, PLL/CLKDIV clocking,
  and serializer/output-buffer arrangement. The local wrappers were written
  for this project; Sipeed's generated IP source is not bundled.
- [Gowin FPGA Primitive guide](https://www.gowinsemi.com/upload/database_doc/39/document/5bfcff2ce0b72.pdf):
  OSER10, ELVDS_OBUF, rPLL, and CLKDIV interfaces. Those are Gowin hardware
  primitives, not implementations written by this project. Editor stubs only
  declare interfaces. Integration tests use the separately installed Gowin
  simulation library; that vendor library is not redistributed here.
- [VESA DMT](https://glenwing.github.io/docs/VESA-DMT-1.13.pdf):
  640x480 timing parameters.

## Project F MIT notice

Copyright (c) 2019 Will Green

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
