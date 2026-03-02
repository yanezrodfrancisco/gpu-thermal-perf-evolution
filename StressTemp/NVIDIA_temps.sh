#!/usr/bin/env bash
set -euo pipefail

OUTFILE="${1:-gpu_temps.json}"
INTERVAL="${2:-1}"

running=1
trap 'running=0' SIGINT SIGTERM

if [[ ! -s "$OUTFILE" ]]; then
  echo "{}" > "$OUTFILE"
fi

while [[ "$running" -eq 1 ]]; do
  ts="$(date +%s)"

  sample="$(nvidia-smi \
      --query-gpu=index,temperature.gpu \
      --format=csv,noheader,nounits)"

  norm="$(awk -F',' '
    {
      gsub(/ /, "", $1)
      gsub(/ /, "", $2)
      printf "\"card%s\": %s,", $1, $2
    }
  ' <<<"$sample")"

  norm="{${norm%,}}"

  tmp="$(mktemp)"

  jq --arg ts "$ts" --argjson norm "$norm" \
     '. + {($ts): $norm}' \
     "$OUTFILE" > "$tmp"

  mv "$tmp" "$OUTFILE"

  sleep "$INTERVAL"
done

