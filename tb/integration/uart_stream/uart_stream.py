#!/usr/bin/env python3
"""Check byte-for-byte UART echo with simultaneous sending and receiving."""

import argparse
import random
import sys
import threading
import time
from pathlib import Path


def positive_integer(value):
    number = int(value)
    if number <= 0:
        raise argparse.ArgumentTypeError("must be positive")
    return number


def check_burst(port, payload, baud):
    port.reset_input_buffer()
    received = bytearray()
    errors = []
    started = time.monotonic()
    deadline = started + len(payload) * 10 / baud * 3 + 2

    def receive():
        finish_at = deadline
        try:
            while time.monotonic() < finish_at:
                received.extend(port.read(max(1, port.in_waiting)))
                if len(received) >= len(payload) and finish_at == deadline:
                    # Also catch unexpected bytes after the expected echo.
                    finish_at = min(deadline, time.monotonic() + 0.2)
        except Exception as error:
            errors.append(error)

    reader = threading.Thread(target=receive)
    reader.start()
    try:
        sent = port.write(payload)
        if sent != len(payload):
            raise RuntimeError(f"only wrote {sent}/{len(payload)} bytes")
    finally:
        reader.join()

    if errors:
        raise RuntimeError(f"receive failed: {errors[0]}")
    if received == payload:
        print(f"PASS: {len(payload)} bytes echoed exactly")
        return True

    print(f"FAIL: sent {len(payload)} bytes, received {len(received)}")
    mismatch = next(
        (index for index, (expected, actual) in enumerate(zip(payload, received))
         if expected != actual), None
    )
    if mismatch is not None:
        print(f"First mismatch at byte {mismatch}: expected "
              f"0x{payload[mismatch]:02x}, received 0x{received[mismatch]:02x}")
    elif len(received) < len(payload):
        print(f"Matching prefix; timed out waiting for {len(payload) - len(received)} bytes")
    else:
        print(f"Expected echo followed by {len(received) - len(payload)} extra bytes")
    print("A mismatch can indicate dropped, duplicated, reordered, or corrupted bytes.")
    return False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", default="/dev/ttyUSB0")
    parser.add_argument("--baud", type=positive_integer, default=9600)
    parser.add_argument("--sizes", type=positive_integer, nargs="+", default=[16, 256, 1000])
    parser.add_argument("--vectors", type=Path,
                        help="write simulated input bytes as hex instead of opening a serial port")
    args = parser.parse_args()

    if args.vectors:
        generator = random.Random(0)
        payload = b"".join(generator.randbytes(size) for size in args.sizes)
        args.vectors.write_text("".join(f"{byte:02x}\n" for byte in payload))
        return 0

    try:
        import serial
    except ImportError:
        parser.exit(1, "pyserial is required; enter the updated nix develop shell.\n")

    try:
        # Exclusive access catches another terminal holding this device.
        with serial.Serial(args.port, args.baud, timeout=0.05, write_timeout=10,
                           exclusive=True, xonxoff=False, rtscts=False,
                           dsrdtr=False) as port:
            print(f"Testing {args.port} at {args.baud} baud, 8N1; close other terminals.")
            generator = random.Random(0)
            for size in args.sizes:
                if not check_burst(port, generator.randbytes(size), args.baud):
                    return 1
    except (serial.SerialException, OSError, RuntimeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
