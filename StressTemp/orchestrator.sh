#!/usr/bin/env bash
set -euo pipefail

CMDNAME=`basename $0`
HELP="Uso: $CMDNAME [OPTIONS...]

Options:
      --matrix-size             Size of the square matrices to be multiplied. Must be an integer
      				By default: 10000
      --prec                    Numerical precision of the matrices
                                Must be chosen between BF16, FP16, FP32, FP64 or C128
				By default: BF16
      --temp-dt                 Time interval (in seconds) between meausurements in temperature
      				By default: 2
      --data-size               Quantity of matrices multiplications realized in the probe
      				By default: 1000


Use example:
	./orchestator --matrix-size 7000 --prec FP32 --temp-dt 1 --data-size 500


Help options:
      --help                    Show this help message

 "









# Valores por defecto
export MATRIX_SIZE=10000
export PREC=BF16
export TEMP_DT=2
export DATA_SIZE=1000 
# Parseo de argumentos
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help)
      echo "${HELP}" 2>/dev/null
      exit 0
      ;;

    --matrix-size)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --matrix-size"
	exit 1	
      fi
      MATRIX_SIZE="$2"
      export MATRIX_SIZE=$MATRIX_SIZE
      shift 2
      ;;

    --prec)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --prec"
	exit 1
      fi
      PREC="$2"
      export PREC=$PREC
      shift 2
      ;;

    --temp-dt)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --temp-dt"
	exit 1
      fi
      TEMP_DT="$2"
      shift 2
      ;;

    --data-size)
      if [[ -z "${2:-}" ]]; then
        echo echo "Missing value for --data-size"
        exit 1	
      fi
      DATA_SIZE="$2"
      export DATA_SIZE=$DATA_SIZE
      shift 2
      ;;

    *)
      echo "Unknown argument: $1"
      echo "Use ./orchestator --help for more information"
      exit 1
      ;;
  esac
done

if nvidia-smi >/dev/null 2>&1; then
  LOG_SCRIPT="./NVIDIA_temps.sh"
elif rocm-smi >/dev/null 2>&1; then
  LOG_SCRIPT="./AMD_temps.sh"
else
  echo Not founded nvidia-smi or rocm-smi to measure GPU temperature
  exit 1
fi

export SAVE_FILE=data_$(date +%s)
 
mkdir -p "${SAVE_FILE}"



PY_SCRIPT="./MM_bench.py"   
OUT_TEMPS="${SAVE_FILE}/gpu_temps_${MATRIX_SIZE}_${PREC}.json"

LOGGER_PID=""

cleanup() {
  if [[ -n "${LOGGER_PID}" ]] && kill -0 "${LOGGER_PID}" 2>/dev/null; then
    echo "[orchestrator] Stopping logger (PID ${LOGGER_PID})..."
    kill -TERM "${LOGGER_PID}" 2>/dev/null || true
    wait "${LOGGER_PID}" 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

echo "[orchestrator] Initiating logger..."
bash "${LOG_SCRIPT}" "${OUT_TEMPS}" "${TEMP_DT}" &
LOGGER_PID=$!


echo "[orchestrator] Executing python MM_bench.py..."
python3 "${PY_SCRIPT}"

echo "[orchestrator] MM_bench finished. Results saved in ${SAVE_FILE}"

