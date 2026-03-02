# gpu-thermal-perf-evolution

A lightweight analysis tool to study the relationship between GPU performance and temperature over time.

The application loads temperature logs and matrix multiplication timing data, then generates dual-axis time-series plots to visualize the correlation between thermal behavior and computational performance.

To see more details about the specific use, use the command `.\orchestator.sh --help`

Besides, this tool relies on external system utilities for GPU monitoring and data preprocessing:

- rocm-smi (AMD GPUs)
- nvidia-smi (NVIDIA GPUs)
- jq
- awk

Make sure they are available in your PATH.
