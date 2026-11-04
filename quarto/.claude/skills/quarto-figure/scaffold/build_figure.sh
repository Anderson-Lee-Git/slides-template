#!/usr/bin/env bash
# Build one matplotlib slide figure, put it on a real themed reveal.js slide, and
# screenshot that slide so the result can be visually inspected.
#
#   build_figure.sh <deck>/figures/<name>.py [-t "Frame Title"]
#
# Writes:
#   <deck>/figures/<name>.svg                      the deliverable, ![](figures/<name>.svg)
#   <deck>/figures/out/<name>.slide-preview.png    the slide, for looking only (gitignored)
#   <deck>/figures/out/<name>.build.log            script + render output
# Needs: uv (runs matplotlib and Playwright without a project venv), quarto.
set -euo pipefail

TITLE="Figure Preview"
PY_PATH=""
while [ $# -gt 0 ]; do
  case "$1" in
    -t|--title) TITLE="${2:-}"; shift 2 ;;
    -h|--help)  echo "usage: build_figure.sh <deck>/figures/<name>.py [-t \"Frame Title\"]"; exit 0 ;;
    *)          PY_PATH="$1"; shift ;;
  esac
done
if [ -z "$PY_PATH" ] || [ ! -f "$PY_PATH" ]; then
  echo "usage: build_figure.sh <deck>/figures/<name>.py [-t \"Frame Title\"]" >&2
  exit 2
fi

DIR="$(cd "$(dirname "$PY_PATH")" && pwd)"
NAME="$(basename "$PY_PATH" .py)"
SCAFFOLD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Figures live in <deck>/figures/, where <deck> holds that deck's slides.qmd, so a
# deck stays self-contained.
DECK="$(dirname "$DIR")"
if [ "$(basename "$DIR")" != "figures" ] || [ ! -f "$DECK/slides.qmd" ]; then
  echo "build_figure.sh: figures must live in <deck>/figures/, next to the deck's slides.qmd." >&2
  echo "  got:      $PY_PATH" >&2
  echo "  expected: e.g. content/<date>/figures/$NAME.py" >&2
  exit 2
fi

# The Quarto project root is the nearest _quarto.yml above the deck.
ROOT="$DECK"
while [ "$ROOT" != "/" ] && [ ! -f "$ROOT/_quarto.yml" ]; do ROOT="$(dirname "$ROOT")"; done
if [ ! -f "$ROOT/_quarto.yml" ]; then
  echo "build_figure.sh: no _quarto.yml above $DECK; the deck must live inside quarto/." >&2
  exit 3
fi

OUT="$DIR/out"
mkdir -p "$OUT"
LOG="$OUT/$NAME.build.log"
: > "$LOG"

# 1. Run the figure script -> <name>.svg (princeton_mpl comes from _theme/).
if ! (cd "$DIR" && PYTHONPATH="$ROOT/_theme" uv run -q --no-project --with matplotlib \
        python "$NAME.py") >>"$LOG" 2>&1; then
  echo "build_figure.sh: $NAME.py failed:" >&2; tail -20 "$LOG" >&2; exit 4
fi
[ -f "$DIR/$NAME.svg" ] || { echo "build_figure.sh: $NAME.py did not write $NAME.svg (call save(fig, __file__))" >&2; exit 4; }

# 2. A one-slide deck in figures/out/ -- inside the project, so it gets the real
#    theme. No title: no title slide. Deleted again after the screenshot.
PREVIEW_QMD="$OUT/$NAME.preview.qmd"
printf -- '---\nfooter: "Preview"\n---\n\n## %s\n\n![](../%s.svg)\n' "$TITLE" "$NAME" > "$PREVIEW_QMD"
if ! quarto render "$PREVIEW_QMD" >>"$LOG" 2>&1; then
  echo "build_figure.sh: quarto render failed; see $LOG" >&2; exit 5
fi

# 3. Screenshot the slide and check the figure against the frame body.
#    PLAYWRIGHT_VERSION pins the Python package to a browser build you already have.
PW="playwright${PLAYWRIGHT_VERSION:+==$PLAYWRIGHT_VERSION}"
STATUS=0
uv run -q --no-project --with "$PW" python "$SCAFFOLD/preview.py" \
    "$OUT/$NAME.preview.html" "$OUT/$NAME.slide-preview.png" || STATUS=$?
rm -rf "$PREVIEW_QMD" "$OUT/$NAME.preview.html" "$OUT/$NAME.preview_files"
[ "$STATUS" -eq 0 ] || [ "$STATUS" -eq 10 ] || exit "$STATUS"

echo "Built: $DIR/$NAME.svg"
echo "Preview: $OUT/$NAME.slide-preview.png"
