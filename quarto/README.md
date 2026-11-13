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

## Setup on a machine without Quarto (e.g. a Slurm cluster)

Tested on Princeton's della cluster (RHEL 9, no root, no `quarto` module), with
Quarto 1.11.9 and Playwright's Chromium 1248. Nothing else had to change: once
these two tools were installed, the example deck and `build_figure.sh` worked.
Do this on the login node, because compute nodes have no internet.

1. **Install Quarto from the release tarball** into a large filesystem, not `$HOME`:

   ```bash
   V=1.11.9; DEST=/scratch/gpfs/<group>/<netid>/quarto-cli
   mkdir -p $DEST && cd $DEST
   curl -sL https://github.com/quarto-dev/quarto-cli/releases/download/v$V/quarto-$V-linux-amd64.tar.gz | tar xz
   export PATH=$DEST/quarto-$V/bin:$PATH     # add this to ~/.bashrc; build_figure.sh calls `quarto`
   quarto check
   ```

   Quarto ships its own pandoc and Deno, so the conda `pandoc` doesn't matter.
   `quarto check` says "Chrome Headless Shell: not installed". You can ignore
   that: it's only for Quarto's own PDF/diagram output, which these decks don't use.

2. **Install Playwright's Chromium** (needed by `build_figure.sh` and for slide
   screenshots). It downloads ~120 MB, so if `$HOME` is small, put the browsers
   somewhere else with `PLAYWRIGHT_BROWSERS_PATH`. Every later Playwright run
   needs the same variable set, so export it in `~/.bashrc`:

   ```bash
   export PLAYWRIGHT_BROWSERS_PATH=/scratch/gpfs/<group>/<netid>/.cache/ms-playwright
   uv run --no-project --with playwright playwright install chromium
   ```

   Headless Chromium launched on RHEL 9 without any extra system libraries.
   `uv` caches its environments in `UV_CACHE_DIR`; point that off `$HOME` too
   if needed.

3. **Viewing a deck from your laptop.** `quarto preview` on the cluster can't open
   a browser. Run it on a fixed port and forward that port:

   ```bash
   quarto preview content/<date>/slides.qmd --no-browser --port 4321
   # on the laptop: ssh -N -L 4321:localhost:4321 <netid>@<login-node>
   # then open http://localhost:4321/content/<date>/slides.html
   ```

   VS Code / Cursor Remote-SSH forwards the port automatically. Login nodes are
   shared, so pick an unusual port. If it's already taken, `python3 -m http.server`
   fails with "Address already in use", and Playwright then reports
   `Reveal is not defined` because no deck loaded. Alternatively, copy the
   rendered `slides.html` to your laptop and open it there: it is self-contained
   (see "Building a deck").

## Starting a deck

```bash
mkdir -p content/<date>
cp _template/slides.qmd content/<date>/slides.qmd
touch content/<date>/reference.bib
```

`content/*` is gitignored, as the decks are private. A deck inherits `_quarto.yml`
(author, `date: today`, theme, CSL), the way a beamer deck inherits `preamble.tex`.
Everything else belongs to the deck and lives in its folder, so a deck folder is
self-contained:

- **`reference.bib`**: each deck has its own; there is no shared bibliography. The
  template reads `bibliography: reference.bib` (relative to `slides.qmd`). To reuse
  entries from an older deck, copy them in. **If the file doesn't exist, the render
  fails** with `File 'reference.bib' not found in resource path`, even for a deck
  with no citations: create it (an empty file is fine) or delete the
  `bibliography:` line.
- `media/` for video, `figures/` for figures.

## Building a deck

```bash
quarto preview content/<date>/slides.qmd   # live reload in the browser
quarto render  content/<date>/slides.qmd   # -> content/<date>/slides.html (one self-contained file)
```

- `quarto render` with no file renders every deck; folders starting with `_` are
  skipped.
- The rendered HTML is **self-contained** (`embed-resources: true` in
  `_quarto.yml`): theme, Carlito, logo, figures and videos are all inlined into
  `slides.html`, with no `slides_files/`, so the one file can be copied or mailed on
  its own. Videos make it large (base64 adds about a third). reveal.js slide
  backgrounds (`background-video`, `background-image`) aren't inlined by Quarto;
  `_theme/princeton.lua` does it, and `_theme/princeton.html` hands them to reveal
  as `blob:` URLs. To link resources instead (smaller file, but the deck then needs
  `slides_files/`, `media/` and the project's `_theme/` beside it), set
  `embed-resources: false` under `format: revealjs:` and `inline-backgrounds: false`
  at the top of the deck's YAML.
- Open the HTML in a browser: `F` for full screen, `S` for speaker notes. For a PDF,
  add `?print-pdf` to the URL and print from Chrome.
- Math loads MathJax 4 from jsDelivr at run time, so it still needs a network
  connection when the deck opens; embedding doesn't cover it. Decks without math
  work offline.
- Nothing warns when content runs off a slide (no `Overfull \vbox`), so check every
  slide by eye. If a slide is too full, split it.
- **References over several slides.** A `## References` slide holding `::: {#refs}`
  is split into "References", "References (cont.)", … by `_theme/refs-pages.lua`
  (like beamer's `[allowframebreaks]`), with entries spread evenly and each citation
  linking to the slide that holds its entry. Mark the slide `{.scrollable}` to keep
  one scrolling slide instead. The split estimates entry heights from text length;
  if a slide overflows, lower `refs-lines` (default 16.5) in the deck's YAML.
  The filter runs citeproc itself (Quarto would otherwise run it after all
  filters) and then sets `suppress-bibliography`, so the second pass adds nothing.

## Inspecting a slide

To look at slide N, render the deck, serve the `quarto/` directory (not just the
deck folder, which would 404 `_theme/fonts.css`; see above) with
`python3 -m http.server <port>`, open `http://localhost:<port>/content/<date>/slides.html`,
and screenshot it at 1280×720 with Playwright after `Reveal.slide(N-1)`. Wait for
`networkidle` plus about a second, so MathJax and its Euler fonts finish loading. The
browser console prints harmless warnings ("mathjax-euler-extension uses 4.0.0 of
MathJax") and a 404 for `mathjax-modern-font/…/mjx-ne-gk.woff2`. Greek still
renders in Euler. For a
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
| bibliography frame (`allowframebreaks`) | `## References` + `::: {#refs}` `:::` (add `{.scrollable}` for one scrolling slide) |
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
| `_theme/refs-pages.lua` | splits the bibliography over several slides |
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
