#!/bin/sh
set -eu
. scripts/fpga/image_selection.sh

check() {
  expected=$1
  shift
  actual=$(select_flash_image "$@"; printf '%s %s\n' "$mode" "$bitstream")
  if [ "$actual" != "$expected" ]; then
    echo "Expected: $expected; got: $actual" >&2
    exit 1
  fi
}
reject() {
  if (select_flash_image "$@") >/dev/null 2>&1; then
    echo "Unexpectedly accepted: $*" >&2
    exit 1
  fi
}

check 'sram build/fpga/tang_nano_9k/soc/images/gowin/uart_hdmi.fs' soc uart_hdmi --gowin
check 'flash build/fpga/tang_nano_9k/soc/images/gowin/uart_hdmi.fs' soc uart_hdmi --gowin flash
check 'flash build/fpga/tang_nano_9k/soc/images/gowin/uart_hdmi.fs' soc uart_hdmi flash --gowin
check 'sram build/fpga/tang_nano_9k/soc/images/nextpnr/uart_hdmi.fs' soc uart_hdmi '' ''
check 'flash build/fpga/tang_nano_9k/soc/images/nextpnr/uart_hdmi.fs' soc uart_hdmi flash
check 'sram impl/pnr/ShmerV.fs' soc ide --gowin
check 'flash impl/pnr/ShmerV.fs' soc ide --gowin flash
check 'sram build/fpga/tang_nano_9k/hdmi_test/images/nextpnr/hdmi_test.fs' hdmi_test '' '' ''
check 'flash build/fpga/tang_nano_9k/hdmi_test/images/nextpnr/hdmi_test.fs' hdmi_test flash '' ''
reject soc --gowin
reject soc ide
reject soc uart_hdmi --unknown
reject soc uart_hdmi sram flash
reject soc uart_hdmi --gowin --gowin
reject hdmi_test --gowin
echo 'PASS: image selection (no FPGA tools invoked)'
