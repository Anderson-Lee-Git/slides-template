# Quarto (reveal.js) slides

The Quarto pathway of this repo: HTML decks in the same Princeton style as the
beamer pathway in `../latex/`, with the same colours, Carlito font, the same math
fonts, orange frame titles with a rule, the `date | frame number | logo` footline, the
section Outline frame, beamer-style blocks and boxes, and natbib-style
`[authoryear,square]` citations. It also does what a PDF can't: embedded and
background video. It runs on its own; nothing here reads from `../latex/`. Paths
below are relative to this `quarto/` directory, and the style rules shared with the
LaTeX pathway are in [`../AGENTS.md`](../AGENTS.md).

`example/slides.qmd` is the reference deck and shows every feature.

## Starting a deck

```bash
mkdir -p content/<date>
cp _template/slides.qmd content/<date>/slides.qmd
```

`content/*` is gitignored, as the decks are private. A deck inherits `_quarto.yml`
(author, `date: today`, theme, CSL), the way a beamer deck inherits `preamble.tex`.
The template reads `bibliography: ../reference.bib`, i.e. `content/reference.bib`;
change that line to use another `.bib`. Deck assets live inside the deck folder:
`media/` for video, `figures/` for figures.

## Building a deck

```bash
quarto preview content/<date>/slides.qmd   # live reload in the browser
quarto render  content/<date>/slides.qmd   # -> content/<date>/slides.html (+ slides_files/)
```

- `quarto render` with no file renders every deck; folders starting with `_` are
  skipped.
- Open the HTML in a browser: `F` for full screen, `S` for speaker notes. For a PDF,
  add `?print-pdf` to the URL and print from Chrome.
- Math loads MathJax 4 from jsDelivr, so it needs a network connection when the
  deck opens.
- Nothing warns when content runs off a slide (no `Overfull \vbox`), so check every
  slide by eye. If a slide is too full, split it; `{.scrollable}` is for the
  References slide only.

## Inspecting a slide

To look at slide N, render the deck, serve its folder (`python3 -m http.server`),
and screenshot it at 1280×720 with Playwright after `Reveal.slide(N-1)`. For a
figure, the `quarto-figure` skill's `build_figure.sh` does all of this for you.
Headless Playwright Chromium can't decode H.264, so `.mp4` slides show black there.
Real browsers play them.

## Figures

Use the `quarto-figure` skill
([`.claude/skills/quarto-figure/SKILL.md`](.claude/skills/quarto-figure/SKILL.md)).
A figure is one matplotlib script, `<deck>/figures/<name>.py`, styled by
`_theme/princeton_mpl.py`. It writes `<name>.svg`, which the deck includes with
`![](figures/<name>.svg)`. Screenshots and other raster images also go in
`<deck>/figures/`.

## Beamer → Quarto cheat sheet

| Beamer | Quarto |
|---|---|
| `\section{X}` | `# X` (makes the Outline frame; `outline: false` in YAML turns that off) |
| `\begin{frame}{Title}` | `## Title` |
| `\alert{x}` | `[x]{.alert}` |
| `\begin{block}{T}` (`exampleblock` looks the same) | `::: {.block title="T"}` … `:::` |
| `\begin{alertblock}{T}` = `\mainblock{T}{body}` | `::: {.alertblock title="T"}` (or `.mainblock`) … `:::` |
| `\begin{boxedblock}` | `::: boxedblock` … `:::` |
| `\begin{columns}` | `:::: columns` / `::: {.column width="50%"}` |
| `\cite{k}` = `\citet` | `@k` → Mialon et al. [2024] |
| `\citep{k}` | `[@k]` → [Mialon et al., 2024]; `[@k, Fig. 2]` for a locator |
| bibliography frame | `## References {.scrollable}` + `::: {#refs}` `:::` |
| `\includegraphics[width=.6\textwidth]{f}` | `![](f.png){width="60%"}` |
| `\textcolor{c0}{x}` | `[x]{.c0}` (Okabe–Ito `c0`…`c5`) |

## Math

- `\begin{equation}\label{eq:x}…\end{equation}`, `align`, `\eqref{eq:x}` paste in
  unchanged; numbering runs through the whole deck. `$…$` and `$$…$$` also work.
- Macros go in `_theme/macros.tex` as ordinary `\newcommand` /
  `\DeclareMathOperator` lines; every deck gets them. `\bm` is mapped to
  `\boldsymbol`, and `mathtools` is loaded.
- Avoid Quarto's own `$$…$$ {#eq-x}` / `@eq-x` cross-references here: they number
  separately from `\label`, so a deck using both gets two equation (1)s.
- Math looks like the PDF's, which mixes fonts the way beamer's default font theme
  does: Latin letters, digits and operator names in Carlito; Greek, brackets,
  `=`/`+`, `\mathcal` and big operators in Euler; `\mathbb` and the slanted
  `\leq`/`\geq` (eulervm's `\leqslant`) from the AMS fonts. `_theme/princeton.html`
  documents the mapping. It uses MathJax 4 from jsDelivr, so math needs a network
  connection when the deck opens.
- Small differences that remain: operator names (`min`, `sin`) are Carlito rather
  than beamer's CM Sans, and `\mathrm{d}` is Euler upright rather than CM Roman.

## Video

Put clips in the deck's `media/` folder.

```markdown
![](media/clip.mp4){.autoplay .loop .muted width="70%" .center}   <!-- embedded -->

## Title {background-video="media/bg.mp4" background-video-loop="true" background-video-muted="true" .video-overlay}

:::: columns
::: column
![](media/a.mp4){.autoplay .loop .muted width="100%"}
:::
::: column
![](media/b.mp4){.autoplay .loop .muted width="100%"}
:::
::::
```

`.autoplay` starts the clip when its slide opens. Add `.controls` for a player bar.
`.video-overlay` turns a slide's text white over dark footage. The demo clips are
synthetic; `example/media/make-demo-media.sh` regenerates them.

## Layout

| Path | Role |
|---|---|
| `_quarto.yml` | shared defaults, like `preamble.tex` |
| `_template/slides.qmd` | starting point for a deck |
| `example/` | reference deck: `slides.qmd`, `example.bib`, `figures/`, `media/` |
| `_theme/princeton.scss` | colours, fonts, frame title, footline, blocks |
| `_theme/title-slide.html` | title-slide layout (title, rule, author, date, logo bottom right) |
| `_theme/princeton.lua` | Outline frames, block/box divs, video tags, macro loading |
| `_theme/princeton.html` | MathJax 4 loader and the font mapping that matches beamer's math |
| `_theme/macros.tex` | math macros |
| `_theme/princeton_mpl.py` | matplotlib style for figures |
| `_theme/fonts/`, `fonts.css` | Carlito (SIL OFL) |
| `csl/abbrvnat-square.csl` | natbib `[authoryear,square]` + `abbrvnat` |
| `.claude/skills/quarto-figure/` | figure skill |

## Known differences from the PDF

- Bib entries with `and others` print "and others" rather than "et al.".
- Figures are matplotlib SVGs, not TikZ, so they match the beamer figures in
  style rather than pixel for pixel. Their numbers use lining figures, because
  matplotlib can't select Carlito's old-style ones.
