#!/usr/bin/env python3
"""Generate progress.png from results.tsv."""
import csv, sys
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

def main():
    tsv = sys.argv[1] if len(sys.argv) > 1 else "results.tsv"
    rows = []
    with open(tsv) as f:
        for r in csv.DictReader(f, delimiter="\t"):
            rows.append(r)

    xs = list(range(1, len(rows) + 1))
    bpbs = [float(r["val_bpb"]) for r in rows]
    statuses = [r["status"] for r in rows]

    # running best
    best = []
    cur = float("inf")
    for b, s in zip(bpbs, statuses):
        if s == "keep" and b < cur:
            cur = b
        best.append(cur if cur < float("inf") else b)

    fig, ax = plt.subplots(figsize=(12, 5))
    fig.patch.set_facecolor("#0d1117")
    ax.set_facecolor("#0d1117")

    # all experiments
    colors = {"keep": "#3fb950", "discard": "#f85149", "crash": "#f0883e"}
    for x, b, s in zip(xs, bpbs, statuses):
        ax.scatter(x, b, color=colors.get(s, "#8b949e"), s=28, zorder=3, alpha=0.8)

    # best line
    ax.plot(xs, best, color="#58a6ff", linewidth=2, label="best val_bpb", zorder=2)

    ax.set_xlabel("experiment #", color="#c9d1d9", fontsize=11)
    ax.set_ylabel("val_bpb (lower is better)", color="#c9d1d9", fontsize=11)
    ax.set_title("autoresearch-scalable progress", color="#c9d1d9", fontsize=14, fontweight="bold")
    ax.tick_params(colors="#8b949e")
    ax.spines[:].set_color("#30363d")
    ax.yaxis.set_major_formatter(ticker.FormatStrFormatter("%.3f"))
    ax.grid(True, color="#21262d", linewidth=0.5)

    # legend
    from matplotlib.lines import Line2D
    handles = [
        Line2D([0], [0], color="#58a6ff", linewidth=2, label="best"),
        Line2D([0], [0], marker="o", color="#0d1117", markerfacecolor="#3fb950", markersize=7, label="keep"),
        Line2D([0], [0], marker="o", color="#0d1117", markerfacecolor="#f85149", markersize=7, label="discard"),
    ]
    ax.legend(handles=handles, facecolor="#161b22", edgecolor="#30363d", labelcolor="#c9d1d9", fontsize=9)

    # filter out the catastrophic outlier for y-axis
    sane = [b for b in bpbs if b < 1.1]
    if sane:
        ax.set_ylim(min(sane) - 0.002, max(sane) + 0.005)

    out = tsv.rsplit("/", 1)
    out = (out[0] + "/" if len(out) > 1 else "") + "progress.png"
    fig.savefig(out, dpi=150, bbox_inches="tight", facecolor=fig.get_facecolor())
    plt.close()
    print(f"Saved {out}")

if __name__ == "__main__":
    main()
