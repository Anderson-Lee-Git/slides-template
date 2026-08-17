#!/usr/bin/env bash
# Render a single-tikzpicture slide figure onto a real 16:9 beamer frame,
# then rasterize it so the result can be visually inspected.
#
#   build_figure.sh <deck>/tikzpicture/<figure_name>.tex [-t "Frame Title"]
#
# Produces, in <deck>/tikzpicture/out/ (gitignored by the repo's out/ rules):
#   <figure_name>.pdf                 one-page slide carrying the figure
#   <figure_name>.slide-preview.png   raster of that slide, for `look at it`
#
# The <figure_name>.tex must contain ONLY a single \begin{tikzpicture}
# ... \end{tikzpicture}. The preamble lives in the repo's preamble.tex, which
# scaffold/main.tex loads so the preview matches the deck exactly.
set -euo pipefail

TITLE="Figure Preview"
TEX_PATH=""
while [ $# -gt 0 ]; do
  case "$1" in
    -t|--title) TITLE="${2:-}"; shift 2 ;;
    -h|--help)  echo "usage: build_figure.sh <path/to/figure_name.tex> [-t \"Frame Title\"]"; exit 0 ;;
    *)          TEX_PATH="$1"; shift ;;
  esac
done

if [ -z "$TEX_PATH" ]; then
  echo "usage: build_figure.sh <path/to/figure_name.tex> [-t \"Frame Title\"]" >&2
  exit 2
fi
if [ ! -f "$TEX_PATH" ]; then
  echo "build_figure.sh: no such figure source: $TEX_PATH" >&2
  exit 2
fi

DIR="$(cd "$(dirname "$TEX_PATH")" && pwd)"
NAME="$(basename "$TEX_PATH" .tex)"
SCAFFOLD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Figures live in <deck>/tikzpicture/, where <deck> is the directory holding
# that deck's slides.tex. Enforced here so the layout cannot drift: a deck has
# to stay self-contained to be copied or archived whole.
DECK="$(dirname "$DIR")"
if [ "$(basename "$DIR")" != "tikzpicture" ] || [ ! -f "$DECK/slides.tex" ]; then
  echo "build_figure.sh: figures must live in <deck>/tikzpicture/." >&2
  echo "  got:      $TEX_PATH" >&2
  echo "  expected: <deck>/tikzpicture/$NAME.tex, e.g. content/06-22-2026/tikzpicture/$NAME.tex" >&2
  echo "            where <deck> is the directory containing that deck's slides.tex." >&2
  exit 2
fi

# Walk up from the figure to the repo root, identified by preamble.tex sitting
# next to the theme. Works from any deck depth (example/, content/<date>/, ...).
ROOT="$DIR"
while [ "$ROOT" != "/" ] && [ ! -f "$ROOT/preamble.tex" ]; do
  ROOT="$(dirname "$ROOT")"
done
if [ ! -f "$ROOT/preamble.tex" ]; then
  echo "build_figure.sh: could not find preamble.tex above $DIR." >&2
  echo "  The figure must live inside the slides repo (e.g. content/<date>/tikzpicture/)." >&2
  exit 3
fi

OUT="$DIR/out"
mkdir -p "$OUT"
cd "$DIR"

# TEXINPUTS lets pdflatex find main.tex (scaffold), preamble.tex + the theme
# (repo root), and the figure itself (here).
if ! TEXINPUTS="$SCAFFOLD:$ROOT:$DIR:" pdflatex \
      -interaction=nonstopmode -halt-on-error \
      -output-directory="$OUT" -jobname="$NAME" \
      "\\def\\figtitle{$TITLE}\\def\\figfile{$NAME.tex}\\input{main.tex}" \
      > "$OUT/$NAME.build.log" 2>&1; then
  echo "build_figure.sh: pdflatex failed. Last errors:" >&2
  grep -E "^(!|l\.[0-9]+)" "$OUT/$NAME.build.log" | head -20 >&2
  echo "  Full log: $OUT/$NAME.build.log" >&2
  exit 4
fi

# An overflowing figure still compiles -- surface it rather than letting it
# slip through as a figure that runs off the bottom of the slide.
if grep -q "Overfull \\\\vbox" "$OUT/$NAME.log"; then
  echo "WARNING: figure overflows the frame body (14.9cm x 6.2cm). Shrink it." >&2
fi

# Keep the PDF and the log; drop the beamer build litter.
rm -f "$OUT/$NAME.aux" "$OUT/$NAME.nav" "$OUT/$NAME.snm" "$OUT/$NAME.toc" "$OUT/$NAME.out"

# Rasterize for visual inspection. pdftoppm/pdftocairo (poppler) give the
# cleanest output; fall back to Ghostscript, which is near-universal.
PREVIEW="$OUT/$NAME.slide-preview.png"
if command -v pdftoppm >/dev/null 2>&1; then
  pdftoppm -png -r 200 -singlefile "$OUT/$NAME.pdf" "$OUT/$NAME.slide-preview"
elif command -v pdftocairo >/dev/null 2>&1; then
  pdftocairo -png -r 200 -singlefile "$OUT/$NAME.pdf" "$OUT/$NAME.slide-preview"
elif command -v gs >/dev/null 2>&1; then
  gs -q -dSAFER -dBATCH -dNOPAUSE -dUseCropBox -r200 \
     -sDEVICE=pngalpha -sOutputFile="$PREVIEW" "$OUT/$NAME.pdf"
else
  echo "build_figure.sh: need one of pdftoppm, pdftocairo, or gs to rasterize the PDF." >&2
  echo "  macOS: 'brew install poppler'. Linux: 'apt-get install poppler-utils'." >&2
  exit 5
fi

echo "Built: $OUT/$NAME.pdf"
echo "Preview: $PREVIEW"
