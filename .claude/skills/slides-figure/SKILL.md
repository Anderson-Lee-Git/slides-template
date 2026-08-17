---
name: slides-figure
description: Create presentation-ready beamer figures as a single LaTeX/TikZ source that is \input into a slide. Use when asked to make, build, draw, plot, or render a figure/chart/plot/diagram for a deck, with Carlito font, projector-legible text, no overlapping labels, theme colors, and a fit inside the 16:9 frame. Sources always live in a tikzpicture/ subdirectory of the deck build directory (example/tikzpicture/, content/06-22-2026/tikzpicture/). Mandates rendering the figure onto a real slide, looking at it, and iterating until it passes the style bar.
---

# Slide figure

Every figure is **one source, one format**:

**`<name>.tex`** — a single `tikzpicture`, `\input` into a frame. It stays
vector and inherits the deck's fonts and colors because it is compiled *as
part of* the deck, not imported as an image. There is no Python and no PNG
deliverable; a rasterized preview exists only so you can look at the result.

You are **not done until you have opened the rendered slide, looked at it,
and confirmed it passes the style checklist below.** Rendering without
looking is the most common failure — the example bar chart in this skill
needed a fix on the second pass (legend markers rendered as thin slivers)
that no amount of reading the source would have caught. Expect to iterate.

Paths below are relative to the repo root.

## Environment requirements

- **LaTeX** with `pdflatex`, `beamer`, and the `carlito`, `pgfplots`, and
  `tikz` packages (all in a full TeX Live; verified on TeX Live 2025).
  Verify: `kpsewhich beamer.cls carlito.sty pgfplots.sty`.
- **A PDF rasterizer** to render the slide for inspection. `build_figure.sh`
  tries `pdftoppm` → `pdftocairo` (both poppler) → `gs` (Ghostscript), in
  that order. Verify at least one: `which pdftoppm pdftocairo gs`. macOS:
  `brew install poppler`.
- **Carlito font** comes from the TeX Live tree via the `princeton` theme,
  so no system font install is needed.
- **No Python.** Everything is TeX. If the data comes from a script, that
  script's job ends at emitting numbers you paste into the `.tex`.

## Directory layout — every figure lives in `<deck>/tikzpicture/`

**A figure source always goes in a `tikzpicture/` subdirectory of the deck
build directory it belongs to — never anywhere else.** The deck build
directory is the one holding that deck's `slides.tex`. Create
`tikzpicture/` if it does not exist yet.

```
content/06-22-2026/         <- a deck build directory (has slides.tex)
  slides.tex                # the deck's build root
  main.tex                  # frames; \input's the figure
  tikzpicture/              <- ALL of this deck's figure sources
    replay-size.tex         # ONE tikzpicture — the deliverable
    motivation.tex
    out/                    # build litter, gitignored
      replay-size.pdf                 # the figure on a one-page slide
      replay-size.slide-preview.png   # raster of that slide, for looking only

example/                    <- another deck build directory
  slides.tex
  main.tex
  tikzpicture/
    example-bar.tex
```

So a figure for the 06-22-2026 deck is `content/06-22-2026/tikzpicture/<name>.tex`,
and a figure for the example deck is `example/tikzpicture/<name>.tex`. Never
a shared top-level `figures/`, never loose in the deck directory, never
inside another deck's folder — figures are owned by exactly one deck, and a
deck must stay self-contained so it can be copied or archived whole.
`build_figure.sh` refuses to build a figure that is not in
`<deck>/tikzpicture/`.

Raster assets that are *not* tikz (screenshots, externally produced plots)
are a different thing and belong in `<deck>/figures/` instead;
`tikzpicture/` is only for `.tex` sources.

Name figures for what they show (`replay-size.tex`, `motivation.tex`), not
for the slide number. Never overwrite another deck's figure.

`<name>.tex` contains **only** `\begin{tikzpicture} ... \end{tikzpicture}`.
No `\documentclass`, no `\usepackage`, no `\usetikzlibrary`, no
`\definecolor` — all of that lives in `preamble.tex` (see *Never declare in
the figure* below).

## Build (agent path)

```bash
# Render the figure onto a real 16:9 frame and rasterize it
.claude/skills/slides-figure/scaffold/build_figure.sh \
    content/<date>/tikzpicture/<name>.tex -t "Frame Title"
```

Then **look at it** (this is mandatory, not optional):

```
Read content/<date>/tikzpicture/out/<name>.slide-preview.png
```

Fix the source, rebuild, look again. Repeat until it passes the checklist.

The preview is a genuine beamer frame built from this repo's `preamble.tex`
and `princeton` theme — same fonts, same colors, same usable area as the
deck. What you see is what the slide will show.

### Then check it in the deck (required before you call it done)

The preview puts the figure alone on a titled frame. The real slide may add
a lead-in line, a second column, or a caption, all of which steal space.
Wire it in and look at the actual page:

```latex
\begin{frame}{Method Comparison}
    \centering
    \input{\slidesdir/tikzpicture/<name>.tex}
\end{frame}
```

```bash
cd content/<date> && latexmk -pdf -outdir=out slides   # or just save in VS Code
```

```
Read content/<date>/out/slides.pdf   (pages: the figure's page)
```

`\slidesdir` is set to `.` by the deck's `slides.tex`, so the path resolves
from the deck directory. Use it rather than a bare relative path.

## Style checklist — the rendered slide must pass

- **Fits the frame.** The body of a titled frame is **14.9cm × 6.2cm**. A
  full-width figure should target **≤ 12.5cm wide × ≤ 5.5cm tall** including
  its legend; go smaller when text shares the slide. `build_figure.sh` warns
  on `Overfull \vbox`, which means it is running off the slide.
- **Font:** Carlito everywhere, inherited from the theme. Never set a font
  family in the figure.
- **Font size:** legible from the back of a room. Ticks and axis labels at
  `\small`, value labels no smaller than `\scriptsize`. **Never `\tiny`.**
  Slide figures need larger relative text than paper figures — there is no
  zooming in on a projector.
- **No overlap:** no text/label/legend overlaps another element, an axis
  line, or a bar. No bar or marker clipped at the plot boundary.
- **Color:** use the theme colors and the shared color-blind-safe palette
  from `preamble.tex` — `princeton` (the orange accent) for the series you
  want to emphasize, `c0..c5` (Okabe-Ito) for everything else,
  `princetonink` for text, `princetonmute` for grids/ticks. No raw
  red/green/blue. Do not pair `princeton` with `c3` (vermillion); they read
  as the same color.
- **Text casing:** titles, axis labels, and legend entries use **Title
  Case**; dataset, model, and method names use their **conventional
  casing** — never auto-lowercased or sentence-cased. Write `GSM8K`,
  `LLaMA`, `MMLU`, not `Gsm8k` / `Llama` / `Mmlu`. See the casing reference
  below. When unsure of a name's canonical form, check its paper/repo
  rather than guessing.
- **Clean axes:** `axis lines*=left`, light grid, tight margins.
- **Consistency with the deck:** colors, casing, and terminology match the
  surrounding slides. A figure that introduces its own vocabulary is a bug.

### Casing reference

Use the canonical form. Common ones (extend as needed; check the source
when in doubt):

| Wrong | Correct |
|---|---|
| Gsm8k, gsm8k | GSM8K |
| Llama, LLAMA | LLaMA (LLaMA 2/3 use `Llama` in Meta's later cards — match the specific paper) |
| Mmlu | MMLU |
| Imagenet | ImageNet |
| Bert, Gpt, Roberta | BERT, GPT, RoBERTa |
| Humaneval | HumanEval |
| Squad | SQuAD |
| Cifar-10, Cifar10 | CIFAR-10 |
| Wikitext | WikiText |
| Hellaswag | HellaSwag |
| Truthfulqa | TruthfulQA |
| arxiv | arXiv |

Acronyms stay uppercase (FLOPs, BLEU, ROUGE, F1). Title Case capitalizes
the principal words but not short articles/prepositions/conjunctions
("Accuracy on Held-out Tasks", not "Accuracy On Held-Out Tasks").

## The shared scaffolding (do not edit per-figure)

`.claude/skills/slides-figure/scaffold/` holds two files.

**`main.tex`** — the beamer wrapper. It `\input`s the repo's `preamble.tex`
and puts your `tikzpicture` on one centered, titled frame. It is
deliberately *not* a `standalone` document: a slide figure is `\input` into
the deck, so previewing it through the same preamble the deck uses is what
guarantees the preview cannot diverge from the real build.

**`build_figure.sh`** — compiles one `<name>.tex` to `out/<name>.pdf` and
`out/<name>.slide-preview.png`. It walks up from the figure to find
`preamble.tex`, so it works from any deck depth, and sets `TEXINPUTS` so
`pdflatex` finds the scaffold, the theme, and your figure. Usage:
`build_figure.sh <path>/<name>.tex [-t "Frame Title"]`.

### Never declare in the figure

`\usepackage`, `\usetikzlibrary`, `\usepgfplotslibrary`, and `\definecolor`
belong in `preamble.tex`, never in `<name>.tex`. Two reasons:

1. `\usetikzlibrary` inside a frame defines its keys **locally**, so a
   second frame reusing that library silently loses them.
2. A figure that declares its own dependencies previews fine through the
   scaffold and then breaks the deck build, or drifts to different colors.

`preamble.tex` already provides `calc`, `positioning`, `arrows.meta`,
`patterns`, `fit`, `backgrounds`, `shapes`, `colorbrewer`,
`overlay-beamer-styles`, `fillbetween`, and `groupplots`, plus the
`princeton*` and `c0..c5` colors. If a figure needs something else, add it
to `preamble.tex` and say so.

## Worked example

`example/tikzpicture/example-bar.tex` is a complete, verified reference (a
grouped bar chart), shown on page 4 of the example deck. Copy it as a
starting point.

## Gotchas (learned by looking at the output)

- **pgfplots `symbolic x coords` silently ignores `enlarge x limits`.** With
  few groups the first group crowds against the y-axis and the leftmost bar
  overlaps the tick labels. Use **numeric x positions + explicit
  `xmin`/`xmax`** (`xtick`/`xticklabels` for the category names) for
  deterministic margins. See the example `.tex`.
- **Grouped bars clip at the axis boundary.** Outer bars that extend past
  the outermost coordinate get cut off (only their value labels remain).
  Set `clip=false` *and* leave margin via `xmin`/`xmax`.
- **Use `axis lines*=left`** (starred) for the L-shaped spine — the
  non-starred `axis y line=left` can place the y-axis at x=0 instead of the
  plot boundary, putting it through your bars.
- **Default `ybar` legend markers are thin slivers**, not swatches. Override:
  `legend image code/.code={\draw[#1] (0cm,-0.09cm) rectangle (0.30cm,0.15cm);}`.
- **Never `\resizebox` a figure to fit.** It scales the text down with the
  drawing, straight past legibility. Set `width=`/`height=` on the `axis`
  instead, or cut content.
- **`scale=` on a `tikzpicture` scales coordinates but not fonts.** Nodes
  keep their type size while the drawing shrinks around them, so labels
  start colliding. Resize the axis, not the picture.
- **Sizing is in cm, not `\textwidth` fractions.** `\textwidth` inside the
  scaffold's frame and inside a two-column deck frame are different widths;
  absolute units keep the preview honest.
- **Overlays go in the frame, not the figure.** Keep `\onslide`/`\visible`
  in `main.tex` where the reveal sequence is readable, or use the
  `overlay-beamer-styles` keys (`visible on=<2->`) on tikz elements.
- Only ever put **one** `tikzpicture` in a file. Two figures on one slide
  means two files, both `\input` into the same frame.

## Troubleshooting

- `build_figure.sh: could not find preamble.tex above ...` → the figure is
  outside the slides repo. Put it in `<deck>/tikzpicture/`.
- `WARNING: figure overflows the frame body` → the figure is taller than
  6.2cm. Reduce `height=` on the axis; do not `\resizebox`.
- `! Undefined control sequence` on a tikz/pgfplots key → the library is
  missing from `preamble.tex`. Add it there, not in the figure.
- `! Package pgfplots Error: ... compat` → `preamble.tex` sets
  `compat=1.15`; bump it if a figure needs newer syntax, and rebuild the
  whole deck afterwards to confirm nothing else shifted.
- `pdflatex: ... carlito.sty not found` → install the `carlito` package
  (`tlmgr install carlito` on TeX Live).
- `build_figure.sh: need one of pdftoppm, pdftocairo, or gs` → install a
  rasterizer: `brew install poppler` (macOS) / `apt-get install
  poppler-utils` (Linux).
- Figure looks right in the preview but wrong in the deck → something is
  declared in the figure instead of `preamble.tex`, or the frame around it
  is constraining the width. Read the deck page, not the preview.
- Full LaTeX output is kept at `<deck>/tikzpicture/out/<name>.build.log`.
