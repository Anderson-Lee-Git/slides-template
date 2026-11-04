---
name: quarto-figure
description: Create presentation-ready figures for Quarto reveal.js decks (under quarto/) as one matplotlib script that writes an SVG, styled by the repo's princeton_mpl module (Carlito, theme colours, projector-legible text, fits the 16:9 frame body). Sources live in a figures/ subdirectory of the deck (example/figures/, content/<date>/figures/). Use when asked to make, plot, draw or render a figure, chart or diagram for a Quarto deck. Requires rendering the figure onto a real slide, looking at it, and iterating until it passes the style bar. For beamer decks under latex/, use slides-figure instead.
---

# Quarto slide figure

Every figure is **one source, one deliverable**:

- **`<name>.py`**: a matplotlib script that draws one figure and calls
  `save(fig, __file__)`.
- **`<name>.svg`**: what it writes. Glyphs are stored as outlines, so the SVG looks
  the same in every browser. The deck includes it with `![](figures/<name>.svg)`.

Track both. The PNG preview exists only so you can look at the result.

You are **not done until you have opened the rendered slide, looked at it, and
confirmed it passes the style checklist below.** Expect to iterate.

This is the Quarto pathway's figure skill. The LaTeX pathway has its own
(`latex/.claude/skills/slides-figure/`). Both follow the shared style rules in
`AGENTS.md` at the repo root; this file adds the matplotlib mechanics and the sizes
in slide pixels. Paths below are relative to `quarto/`.

## Environment requirements

- **uv**, which runs matplotlib and Playwright without a project venv.
- **quarto**, to render the preview slide.
- **Chromium for Playwright**, for the screenshot. If it's missing, the script
  says so. Install it with `uv run --no-project --with playwright playwright install
  chromium`, or set `PLAYWRIGHT_VERSION` to match a browser build you already have
  (for example `PLAYWRIGHT_VERSION=1.48.0` for `~/.cache/ms-playwright/chromium-1140`).
- **Carlito** comes from `_theme/fonts/`; no system font install is needed.

## Directory layout: every figure lives in `<deck>/figures/`

```
content/<date>/             <- a deck (holds slides.qmd)
  slides.qmd
  figures/
    replay-size.py          # the source
    replay-size.svg         # the deliverable
    out/                    # gitignored
      replay-size.slide-preview.png
      replay-size.build.log
```

Figures belong to exactly one deck, never a shared top-level folder.
`build_figure.sh` refuses a script that is not in `<deck>/figures/` next to a
`slides.qmd`. Screenshots and other raster images go in the same `figures/` folder.
Name figures for what they show, not for the slide number.

## Build (agent path)

```bash
.claude/skills/quarto-figure/scaffold/build_figure.sh \
    content/<date>/figures/<name>.py -t "Frame Title"
```

This runs the script, puts the SVG on a real titled slide rendered with this
repo's theme, screenshots it at 1280×720, and prints the figure's size against the
frame body. Then **look at it** (mandatory):

```
Read content/<date>/figures/out/<name>.slide-preview.png
```

Fix the script, rebuild, look again.

### Then check it in the deck (required before you call it done)

```markdown
## Method Comparison

![](figures/<name>.svg){fig-align="center"}
```

Render the deck and look at that slide (see *Inspecting a slide* in
`quarto/README.md`). A lead-in line, columns or a caption take space that the
preview didn't have.

## Style checklist: the rendered slide must pass

The shared rules (palette, casing, legibility, no overlap, consistency) are in
`AGENTS.md` under *Shared style*, and they apply in full. In slide pixels
(1280×720 slide; matplotlib pt × 4/3 = px):

- **Fits the frame.** The titled-frame body is about **1192 × 520 px**. The default
  `figsize` (10.4 × 4.6 in, about 1000 × 440 px) is the full-width target; go
  smaller when text shares the slide. `build_figure.sh` warns if the figure reaches
  the footline or the browser had to scale it down.
- **Font:** Carlito everywhere, from `princeton_mpl`. Never set a font family.
- **Font size:** ticks, axis labels and legend at `LABEL_PT` (21 pt = 28 px, beamer
  `\small`). Value labels at `VALUE_PT` (17 pt = 22.6 px, `\scriptsize`) at minimum.
  Never go below `VALUE_PT`.
- **Color:** `COLORS["princeton"]` for the series to emphasise; `COLORS["c0"]`…`["c5"]`
  for the rest. Never hex literals in a figure script.
- **Text casing:** titles, axis labels and legend entries in Title Case; names per
  the `AGENTS.md` casing reference.
- **Clean axes:** the style gives an L-shaped spine and a light y grid. Keep it.

## The shared scaffolding (do not edit per-figure)

- **`_theme/princeton_mpl.py`**, the matplotlib counterpart of `preamble.tex`.
  Importing it registers Carlito and sets the rcParams: sizes, colours, spines,
  grid, transparent background, SVG outlines, and the default figure size. It
  provides `COLORS`, `LABEL_PT`, `VALUE_PT` and `save()`.
- **`scaffold/build_figure.sh`**: runs the script with `_theme/` on `PYTHONPATH`,
  renders a one-slide preview deck in `figures/out/` (deleted afterwards), and calls
  `preview.py`.
- **`scaffold/preview.py`**: screenshots the slide and checks the figure's box
  against the frame body.

### Never declare in the figure

No `rcParams` edits, `plt.style.use`, font families, font sizes or hex colours in
`<name>.py`. They belong in `princeton_mpl.py`, so every figure in every deck stays
consistent. If a figure really needs a new shared setting, add it there and say so.

## Worked example

`example/figures/example-bar.py` is a complete, verified reference: the same
grouped bar chart as the beamer example, shown on the "Method Comparison" slide of
`example/slides.qmd`. Copy it as a starting point.

## Gotchas

- **Don't set `width=` on the image in the deck.** Scaling the SVG scales its text
  too. Change `figsize` in the script instead. (This is the counterpart of beamer's
  "never `\resizebox`".)
- **The deck sets `auto-stretch: false`**, so a lone image keeps its size. Don't
  add `.r-stretch` to a figure.
- **`save()` uses `bbox_inches="tight"`**, so the SVG is the drawn area, not exactly
  `figsize`. Read the size `build_figure.sh` prints, not the one you asked for.
- **Legend above the plot:** `loc="lower center", bbox_to_anchor=(0.5, 1.0)`.
  Inside the axes it collides with tall bars.
- **Bar labels:** `ax.bar_label(bars, padding=3, fontsize=VALUE_PT)`. Leave headroom
  with `ylim` so the top label isn't clipped.
- One figure per script. Two figures on a slide means two scripts, placed in a
  `columns` layout.

## Troubleshooting

- `figures must live in <deck>/figures/` → move the script next to the deck's
  `slides.qmd`, into `figures/`.
- `<name>.py failed` → the traceback is in `figures/out/<name>.build.log`.
  `ModuleNotFoundError: princeton_mpl` means it was run outside `build_figure.sh`.
- `did not write <name>.svg` → the script must end with `save(fig, __file__)`.
- `cannot start Chromium` → install the browser or set `PLAYWRIGHT_VERSION` (see
  *Environment requirements*).
- `WARNING: figure overflows the frame body` → shrink `figsize`; don't scale the image.
