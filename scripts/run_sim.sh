#!/bin/sh
set -eu

module=${1:-}
program=${2:-}

if [ -z "$module" ]; then
  echo "Usage: just sim MODULE [PROGRAM]" >&2
  exit 1
fi

if [ "$module" = "cpu_system" ]; then
  if [ -z "$program" ]; then
    echo "Usage: just sim cpu_system PROGRAM"
    echo "Available programs:"
    for program_source in sw/tests/cpu_system/*.S; do
      if [ -f "$program_source" ]; then
        basename "$program_source" .S
      fi
    done
    exit 0
  fi
  waveform="build/cpu_system/$program/waveform.fst"
elif [ -n "$program" ]; then
  echo "A program name is only valid for cpu_system" >&2
  exit 1
else
  waveform="build/tests/$module/waveform.fst"
fi

# Do not open a stale waveform if the traced build or run fails early.
rm -f "$waveform"

test_status=0
scripts/run_tests.sh "$module" "$program" trace || test_status=$?

if [ ! -f "$waveform" ]; then
  echo "No waveform was generated: $waveform" >&2
  if [ "$test_status" -eq 0 ]; then
    exit 1
  fi
  exit "$test_status"
fi

viewer_status=0
scripts/open_wave.sh "$module" "$program" || viewer_status=$?

if [ "$test_status" -ne 0 ]; then
  exit "$test_status"
fi
exit "$viewer_status"
