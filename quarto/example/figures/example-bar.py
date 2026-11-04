"""Worked example for the quarto-figure skill: a grouped bar chart sized for a
titled 16:9 slide (same data as latex/example/tikzpicture/example-bar.tex).
Copy this as a starting point. Build (from quarto/):
    .claude/skills/quarto-figure/scaffold/build_figure.sh example/figures/example-bar.py -t "Method Comparison"
"""
import matplotlib.pyplot as plt
import numpy as np

from princeton_mpl import COLORS, VALUE_PT, save

tasks = ["GSM8K", "MMLU", "HumanEval"]
series = {"Baseline": ([61, 68, 54], COLORS["c0"]),
          "Ours": ([74, 79, 71], COLORS["princeton"])}

x = np.arange(len(tasks))
width = 0.32
fig, ax = plt.subplots()
for i, (label, (values, color)) in enumerate(series.items()):
    bars = ax.bar(x + (i - 0.5) * width, values, width, label=label, color=color)
    ax.bar_label(bars, padding=3, fontsize=VALUE_PT)

ax.set_xticks(x, tasks)
ax.tick_params(axis="x", length=0)
ax.set_ylim(0, 100)
ax.set_yticks([0, 25, 50, 75, 100])
ax.set_ylabel("Accuracy (%)")
ax.legend(loc="lower center", bbox_to_anchor=(0.5, 1.0), ncols=2,
          handlelength=1.0, columnspacing=1.5)
save(fig, __file__)
