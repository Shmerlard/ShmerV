# UART to HDMI

Clear the screen and write each UART byte into the next cell, white on black.
The cursor moves across 80 columns and 30 rows, then wraps and overwrites
from the top-left. Every byte is a glyph code, including Enter and Tab.

Connect UART RX to C.1 / pin 37, with a shared ground. Use 9600 baud, 8N1.
Reception uses polling; there is no terminal parsing or scrolling.
