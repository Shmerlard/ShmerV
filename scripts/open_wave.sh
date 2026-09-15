#!/bin/sh
set -eu

module=${1:-}
program=${2:-}

if [ -z "$module" ]; then
  echo "Usage: just wave MODULE [PROGRAM]" >&2
  exit 1
fi

if [ "$module" = "cpu_system" ]; then
  if [ -z "$program" ]; then
    echo "A program is required: just wave cpu_system PROGRAM" >&2
    exit 1
  fi
  waveform="build/cpu_system/$program/waveform.fst"
elif [ -n "$program" ]; then
  echo "A program name is only valid for cpu_system" >&2
  exit 1
else
  waveform="build/tests/$module/waveform.fst"
fi
state_file="tb/waves/$module.surf.ron"

if [ ! -f "$waveform" ]; then
  echo "Missing waveform: $waveform" >&2
  echo "Generate it with: just sim $module${program:+ $program}" >&2
  exit 1
fi

if [ -f "$state_file" ]; then
  exec surfer --state-file "$state_file" "$waveform"
fi
exec surfer "$waveform"
