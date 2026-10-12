# References and attribution

## TMDS encoding

The encoder's transition-reduction decision and running-disparity/control-symbol
flow were informed by [Project F's TMDS encoder for DVI](https://github.com/projf/display_controller/blob/master/rtl/tmds_encoder_dvi.v),
by Will Green (2019), released under the MIT License. The local implementation
is rewritten: transition reduction uses a loop, and disparity is calculated
from the complete output symbol. The testbench uses the reference's explicit
disparity equations for comparison. It is not an unchanged copy of that module.

The original attribution and MIT notice are retained below for that contribution.

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
