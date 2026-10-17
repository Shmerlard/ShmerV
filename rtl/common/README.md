# Clock-domain crossing

`cdc_bit_sync` samples a single level through two destination-clock registers.
Its input should be registered in the source domain and held long enough to be
observed. It does not guarantee delivery of short pulses or coherent buses.

`cdc_handshake #(.WIDTH(N))` continuously transfers snapshots of an N-bit value
between `src_clk` and `dst_clk`. The sender holds a snapshot until the four-phase
request/acknowledge handshake finishes. The receiver stores its own copy. Updates
during a transfer may be skipped; a stable latest value eventually arrives.
Use a FIFO or an explicit transaction interface when every update must arrive.

Resets are active high and synchronous to their local clocks. Reset both domains
before use; independent resets during an active handshake are not supported.

The SoC SDC matches reserved internal register names across hierarchy:

- `cdc_bit_meta`: only the first synchronizer stage's D input is excluded.
- `cdc_hs_hold` and `cdc_hs_value`: only the handshake data bus receives the
  destination-relative setup multicycle and hold exception.

Do not reuse these names elsewhere or rename them without updating the SDC.
Gowin's `syn_preserve` keeps both synchronizer registers; `syn_keep` preserves
the handshake data nets used by the constraints. These attributes do not replace
the timing constraints or guarantee placement/metastability resolution.
This is pin-name matching, not filtering by module type. Stage-to-stage timing
and destination logic remain checked. Check that the collections match the
expected registers in Gowin's timing/exception report after synthesis, especially
when using a new width (scalar names at width 1 differ from bus names).

RTL simulation checks the protocol, not analog metastability or physical timing.
