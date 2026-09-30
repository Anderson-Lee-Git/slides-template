# Slides template

## Compiling a deck

Each deck lives in its own build directory holding a `slides.tex` (e.g.
`content/<date>/`, `example/`). The shared `preamble.tex` and the
`beamerthemeprinceton.sty` theme sit at the repo root, so `pdflatex` only finds
them when `TEXINPUTS` includes the parent directories. Build from the deck
directory:

```bash
cd content/<date>
TEXINPUTS="../:../../:" BIBINPUTS="../:" latexmk -pdf -interaction=nonstopmode -outdir=out slides
```

- Always pass `-interaction=nonstopmode` (or `-halt-on-error`). Without it a
  missing file drops LaTeX into an interactive prompt and the build hangs
  silently — `File 'beamerthemeprinceton.sty' not found` is the usual symptom of
  a missing `TEXINPUTS`.
- `BIBINPUTS="../:"` is needed for decks with a `reference.bib`: latexmk runs
  BibTeX inside `out/`, so without it `slides.blg` reports `I couldn't open
  database file ./reference.bib` and citations render as `[?]`. Reference the
  file as `\bibliography{reference}` — no `\slidesdir/` prefix and no `.bib`
  extension, since a leading `./` makes BibTeX ignore `BIBINPUTS`.
- Output goes to `content/<date>/out/slides.pdf`; `out/` is build litter.
- Check `out/slides.log` for `^!` (errors) and `Overfull \vbox` (content
  running off a frame) before calling a build good.
- To inspect a page: `pdftoppm -f N -l N -r 100 -png out/slides.pdf out/page`
  then read the PNG.

The VS Code LaTeX Workshop task in `.vscode/settings.json` sets the same
`TEXINPUTS` and `BIBINPUTS`, so saving in the editor builds the same way.

## Figures

Use the `slides-figure` skill. Figure sources are single `tikzpicture`s in
`<deck>/tikzpicture/<name>.tex`, `\input` from `main.tex` via `\slidesdir`.
