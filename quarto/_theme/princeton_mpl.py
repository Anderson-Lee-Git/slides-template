"""Matplotlib style for slide figures -- the Quarto counterpart of preamble.tex.

A figure script does

    from princeton_mpl import COLORS, save
    fig, ax = plt.subplots()          # default size fits a titled slide
    ...
    save(fig, __file__)               # writes <name>.svg next to the script

and never sets fonts, sizes or colours itself. build_figure.sh puts this
directory on PYTHONPATH.

Sizes: matplotlib writes SVG in pt and the browser draws 1pt = 4/3 px, so on the
1280x720 slide a size in px is 0.75x that in pt. The slide body is 31px (11pt
beamer); ticks/labels at 21pt = 28px (beamer \\small), value labels at 17pt =
22.6px (\\scriptsize, the floor).
"""
from pathlib import Path

import matplotlib

matplotlib.use("svg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib import font_manager  # noqa: E402

COLORS = {
    "princeton": "#C25508",
    "princetonlogo": "#ED6D0B",
    "ink": "#262626",
    "mute": "#787878",
    "c0": "#0072B2",
    "c1": "#E69F00",
    "c2": "#009E73",
    "c3": "#D55E00",
    "c4": "#CC79A7",
    "c5": "#56B4E9",
}

LABEL_PT = 21   # axis labels, ticks, legend
VALUE_PT = 17   # value labels; never smaller

for ttf in (Path(__file__).parent / "fonts").glob("Carlito-*.ttf"):
    font_manager.fontManager.addfont(str(ttf))

plt.rcParams.update({
    "font.family": "Carlito",
    "font.size": LABEL_PT,
    "axes.labelsize": LABEL_PT,
    "xtick.labelsize": LABEL_PT,
    "ytick.labelsize": LABEL_PT,
    "legend.fontsize": LABEL_PT,
    "mathtext.fontset": "custom",
    "mathtext.rm": "Carlito",
    "mathtext.it": "Carlito:italic",
    "mathtext.bf": "Carlito:bold",
    "text.color": COLORS["ink"],
    "axes.labelcolor": COLORS["ink"],
    "axes.edgecolor": COLORS["mute"],
    "xtick.color": COLORS["mute"],
    "ytick.color": COLORS["mute"],
    "xtick.labelcolor": COLORS["ink"],
    "ytick.labelcolor": COLORS["ink"],
    "axes.prop_cycle": plt.cycler(color=[COLORS[c] for c in ("c0", "princeton", "c2", "c4", "c5", "c1")]),
    # L-shaped spine, light grid, tight margins
    "axes.spines.top": False,
    "axes.spines.right": False,
    "axes.grid": True,
    "axes.grid.axis": "y",
    "axes.axisbelow": True,
    "grid.color": COLORS["mute"],
    "grid.alpha": 0.3,
    "grid.linewidth": 0.6,
    "legend.frameon": False,
    # 1000 x 440 px on the slide: fits the 1192 x ~520 px frame body with room to spare
    "figure.figsize": (10.4, 4.6),
    "figure.facecolor": "none",
    "axes.facecolor": "none",
    "savefig.transparent": True,
    "svg.fonttype": "path",     # glyphs as outlines: the SVG looks the same everywhere
})


def save(fig, script_path):
    """Write <script name>.svg next to the figure script."""
    out = Path(script_path).with_suffix(".svg")
    fig.savefig(out, bbox_inches="tight", pad_inches=0.05)
    print(f"wrote {out}")
