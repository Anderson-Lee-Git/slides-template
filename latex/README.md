# LaTeX (beamer) slides

The beamer pathway of this repo: the `princeton` theme
(`beamerthemeprinceton.sty`), the shared `preamble.tex`, and decks that compile to
PDF. Paths below are relative to this `latex/` directory. The style rules shared
with the Quarto pathway are in [`../AGENTS.md`](../AGENTS.md).

## Starting a deck

```bash
mkdir -p content/<date>
cp _template/slides.tex content/<date>/slides.tex
# write content/<date>/main.tex (frames); see example/main.tex
```

`content/*` is gitignored, as the decks are private. `example/` is the tracked
reference deck; its compiled `example/out/slides.pdf` is tracked too.

## Compiling a deck

Each deck lives in its own build directory holding a `slides.tex` (e.g.
`content/<date>/`, `example/`). The shared `preamble.tex` and the
`beamerthemeprinceton.sty` theme sit at the top of `latex/`, so `pdflatex` only finds
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

The workspace-level `../.vscode/settings.json` (VS Code only reads it at the repo
root) sets the same variables. They are relative to the deck folder, so they resolve
here from `example/` (`../`) and `content/<date>/` (`../../`).

## Figures

Use the `slides-figure` skill ([`.claude/skills/slides-figure/SKILL.md`](.claude/skills/slides-figure/SKILL.md)).
Figure sources are single `tikzpicture`s in `<deck>/tikzpicture/<name>.tex`,
`\input` from `main.tex` via `\slidesdir`.
