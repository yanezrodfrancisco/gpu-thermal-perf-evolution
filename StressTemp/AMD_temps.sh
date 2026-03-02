#!/usr/bin/env bash
set -euo pipefail

OUTFILE="${1:-gpu_temps.json}"
INTERVAL="${2:-2}"

running=1
trap 'running=0' SIGINT SIGTERM

if [[ ! -s "$OUTFILE" ]]; then
  echo "{}" > "$OUTFILE"
fi

while [[ "$running" -eq 1 ]]; do
  ts="$(date +%s)"

  sample="$(rocm-smi --showtemp --json)"

  norm="$(jq '
    with_entries(
      .value |= {
        edge:     (.["Temperature (Sensor edge) (C)"]     | tonumber),
        junction: (.["Temperature (Sensor junction) (C)"] | tonumber),
        memory:   (.["Temperature (Sensor memory) (C)"]   | tonumber),
        hbm0:     (.["Temperature (Sensor HBM 0) (C)"]     | tonumber),
        hbm1:     (.["Temperature (Sensor HBM 1) (C)"]     | tonumber),
        hbm2:     (.["Temperature (Sensor HBM 2) (C)"]     | tonumber),
        hbm3:     (.["Temperature (Sensor HBM 3) (C)"]     | tonumber)
      }
    )
  ' <<<"$sample")"

  tmp="$(mktemp)"
  jq --arg ts "$ts" --argjson norm "$norm" \
     '. + {($ts): $norm}' \
     "$OUTFILE" > "$tmp"
  mv "$tmp" "$OUTFILE"

  sleep "$INTERVAL"
done

