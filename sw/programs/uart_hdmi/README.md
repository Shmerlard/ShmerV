# UART to HDMI

Received characters are written to 80×30 text cells with a black background;
the foreground color advances through the 16-color palette. The program does
not clear the screen at startup, so the FPGA's initial character image remains
until overwritten. At the end of a row, writing continues on the next row.

Carriage return (`0x0D`) moves to the start of the next row. Ctrl+C (`0x03`)
clears the screen and resets the cursor. Delete (`0x7F`) erases the previous
character within the current row. Other received bytes are displayed as glyphs.

Connect UART RX to C.1 / pin 37, with a shared ground. Use 9600 baud, 8N1.
Reception uses polling; there is no scrolling.
