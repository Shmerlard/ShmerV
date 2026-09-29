#!/bin/sh
set -eu

board=tang_nano_9k
target=${1:-}
output_file=${2:-}

if [ -z "$target" ]; then
  echo "Usage: $0 TARGET [OUTPUT_FILE]" >&2
  exit 1
fi

target_directory="fpga/$board/$target"
sources_file="$target_directory/sources.f"
constraints_file="$target_directory/pins.cst"

if [ ! -f "$sources_file" ] || [ ! -f "$constraints_file" ]; then
  echo "Unknown or incomplete FPGA target: $target" >&2
  exit 1
fi

while IFS= read -r source_file; do
  if [ -n "$source_file" ] && [ ! -f "$source_file" ]; then
    echo "Missing FPGA source: $source_file" >&2
    exit 1
  fi
done < "$sources_file"

fingerprint=$(
  {
    sha256sum "$sources_file" "$constraints_file"
    while IFS= read -r source_file; do
      if [ -n "$source_file" ]; then
        sha256sum "$source_file"
      fi
    done < "$sources_file"
  } | sha256sum | awk '{print $1}'
)

if [ -n "$output_file" ]; then
  mkdir -p "$(dirname "$output_file")"
  printf '%s\n' "$fingerprint" > "$output_file"
else
  printf '%s\n' "$fingerprint"
fi
