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
  program_state_file="tb/waves/cpu_system/$program.surf.ron"
  shared_state_file="tb/waves/cpu_system.surf.ron"
  if [ -f "$program_state_file" ]; then
    state_file=$program_state_file
  elif [ -f "$shared_state_file" ]; then
    state_file=$shared_state_file
  else
    state_file=$program_state_file
  fi
elif [ -n "$program" ]; then
  echo "A program name is only valid for cpu_system" >&2
  exit 1
else
  waveform="build/tests/$module/waveform.fst"
  state_file="tb/waves/$module.surf.ron"
fi

if [ ! -f "$waveform" ]; then
  echo "Missing waveform: $waveform" >&2
  echo "Generate it with: just sim $module${program:+ $program}" >&2
  exit 1
fi

if [ -f "$state_file" ]; then
  exec surfer --state-file "$state_file" "$waveform"
fi

mkdir -p "$(dirname "$state_file")"
command_file=$(mktemp)
trap 'rm -f "$command_file"' EXIT
printf 'save_state_as %s\n' "$state_file" > "$command_file"
surfer --command-file "$command_file" "$waveform"
