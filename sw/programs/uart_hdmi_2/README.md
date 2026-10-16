# UART to HDMI with hardware cursor writes

Polling UART RX on C.1 / pin 37, 9600 baud, 8N1. Ordinary bytes are written
as white-on-black glyphs through CURSOR_DATA (`0x1000200C`); hardware writes
the cell and advances the visible blinking cursor. Startup resets the cursor
without clearing the configuration-time screen image.

Terminal operations match `uart_hdmi`: CR (`0x0D`) moves to the next row,
Ctrl+C (`0x03`) clears the visible screen, and Delete (`0x7F`) erases the
previous character within the current row. Other bytes, including LF and
Tab, remain glyph codes. Erasing and clearing use direct RAM writes at
`0x10006000 + 4*index`. CURSOR_POS (`0x10002004`) updates the hardware cursor
after terminal operations. Its low 12 bits select the next cell; setting it
does not write RAM. A software position mirror supports these operations;
ordinary writes do not manually update the hardware position.

Writing past the visible 80×30 area wraps to cell zero in software. CR also
wraps at the bottom, avoiding the original program's out-of-screen CR case.
Scrolling, cursor-position readback, and hardware end-of-buffer policy remain
unimplemented. UART polling can lose input during screen clearing.

User-run firmware command: `just firmware-build uart_hdmi_2`.
Rebuild FPGA hardware for the new controller before loading this firmware.
