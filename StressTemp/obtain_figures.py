#!/usr/bin/env python3

import argparse
import json
import os
import glob

import numpy as np
import matplotlib.pyplot as plt


def parse_args():
    parser = argparse.ArgumentParser(
        description="Plot GPU temperatures and MM times from a data_{timestamp} directory"
    )
    parser.add_argument(
        "timestamp",
        type=str,
        help="Timestamp used in data_{timestamp} directory name"
    )
    return parser.parse_args()


def main():
    args = parse_args()

    data_dir = f"data_{args.timestamp}"
    if not os.path.isdir(data_dir):
        raise FileNotFoundError(f"Directory {data_dir} not found")

    json_candidates = glob.glob(os.path.join(data_dir, "*.json"))
    npz_candidates = glob.glob(os.path.join(data_dir, "*.npz"))

    if len(json_candidates) != 1:
        raise RuntimeError(
            f"Expected exactly 1 JSON file in {data_dir}, found {len(json_candidates)}"
        )

    if len(npz_candidates) != 1:
        raise RuntimeError(
            f"Expected exactly 1 NPZ file in {data_dir}, found {len(npz_candidates)}"
        )

    json_file = json_candidates[0]
    npz_file = npz_candidates[0]

    with open(json_file, "r") as f:
        temps_data = json.load(f)

    timestamps = sorted(temps_data.keys(), key=lambda x: int(x))

    t0 = int(timestamps[0])
    time_axis = np.array([int(ts) - t0 for ts in timestamps])

    first_entry = temps_data[timestamps[0]]
    cards = sorted(first_entry.keys())

    mm_data = np.load(npz_file)['arr_0'].T
    
    ## First 5 elements may are influenced by JIT complilations, module loads, caches warm-up, ... ###
    mm_x = mm_data[0][5:] - t0
    mm_y = mm_data[1][5:]

for card in cards:
        junction = []
        edge = []

        for ts in timestamps:
            entry = temps_data[ts]
            if card not in entry:
                raise KeyError(f"Card {card} not found in timestamp {ts}")

            try:
                # AMD-style JSON with detailed sensors
                junction.append(entry[card]["junction"])
                edge.append(entry[card]["edge"])
            except (TypeError, KeyError):
                # NVIDIA-smi style JSON: flat temperature per GPU
                temp = entry[card]
                edge.append(temp)

        edge = np.array(edge)

        fig, ax = plt.subplots()

        ax2 = ax.twinx()

        # Primary axis: temperatures
        if junction != []:
            junction = np.array(junction)
            ax2.plot(time_axis, junction, '.-', color="orange", label="junction", linewidth = 0.8)
            ax2.plot(time_axis, edge, '.-' , color="red", label="edge", linewidth = 0.8)
        else:
            ax2.plot(time_axis, edge, '.-' , color="red", label="gpu temperature", linewidth = 0.8)
        ax2.set_xlabel("Time (s)")
        ax2.set_ylabel("Temperature (°C)", color="red")
        ax2.tick_params(axis="y", labelcolor="red")

        # Secondary axis: MM times
        ax.plot(mm_x, mm_y, "bo-", label="MM time")
        ax.set_ylabel("MM time (s)", color="blue")
        ax.tick_params(axis="y", labelcolor="blue")
        ax.set(xlabel='Real time (s)')

        tit = f"{card[0].upper()}{card[1:-1]} {card[-1]}"
        plt.title(f"Probe realized in a GPU AMD Instinct MI210")

        # Optional: combine legends
        lines, labels = ax.get_legend_handles_labels()
        lines2, labels2 = ax2.get_legend_handles_labels()
        ax.legend(lines + lines2, labels + labels2, loc="best")

        plt.tight_layout()

        # Build descriptive output name
        base_name = os.path.splitext(os.path.basename(json_file))[0]
        output_path = f"{card}_{base_name}.png"

        plt.savefig(output_path, dpi=300)
        plt.close(fig)


if __name__ == "__main__":
    main()

