Timer A counts from 0 to 1000 with a divide-by-8 clock; compare interrupts at 250 and 750 turn on GPIO C.0 and C.1 respectively.
The overflow interrupt turns both outputs off, producing approximately 75% and 25% duty cycles through CPU interrupt handlers.
Each handler clears its pending flag before returning, allowing the pattern to repeat continuously.
