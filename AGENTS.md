# AGENTS.md — Princeton slides template

This repo builds slide decks in one visual style through **two independent
pathways**. Each sits in its own top-level directory and works without the other.

| Pathway | Directory | Output | Read first |
|---|---|---|---|
| LaTeX / beamer | [`latex/`](latex/) | PDF | [`latex/README.md`](latex/README.md) |
| Quarto / reveal.js | [`quarto/`](quarto/) | HTML (video, live links) | [`quarto/README.md`](quarto/README.md) |

Before touching a deck, read the README of its pathway: build commands, deck
layout and gotchas live there, not here. If the user hasn't said which pathway a
new deck is for, ask. Don't convert a deck between pathways unless asked.

## Independence

- No file in one pathway reads a file from the other. Each has its own theme,
  `_template/`, `example/` reference deck, `content/<date>/` decks (gitignored),
  logo, and skills.
- Each deck folder is self-contained: its own `reference.bib`, `figures/` and
  (Quarto) `media/` live inside `content/<date>/`. Never share a bibliography
  between decks; copy the entries a new deck needs.
- The look is defined twice, so a style change has to be made in both:

| What | `latex/` | `quarto/` |
|---|---|---|
| Colours, fonts, frame title, footline | `beamerthemeprinceton.sty` | `_theme/princeton.scss` |
| The three boxes | `beamerthemeprinceton.sty` | `_theme/princeton.scss`, `_theme/princeton.lua` |
| Packages, figure palette | `preamble.tex` | `_theme/princeton.scss` |
| Title slide | `beamerthemeprinceton.sty` | `_theme/title-slide.html` |
| Math macros | `preamble.tex` | `_theme/macros.tex` |
| Citation style | natbib `[authoryear,square]` + `abbrvnat` | `csl/abbrvnat-square.csl` |

## Skills

Each pathway has its own skills under `<pathway>/.claude/skills/`. Both follow the
shared rules below; they differ only in tooling and units.

| Task | LaTeX | Quarto |
|---|---|---|
| Make a figure for a deck | [`slides-figure`](latex/.claude/skills/slides-figure/SKILL.md): one TikZ/pgfplots `tikzpicture` | [`quarto-figure`](quarto/.claude/skills/quarto-figure/SKILL.md): one matplotlib script that writes an SVG |

## Shared style

### Identity

- **Colours.** `princeton` `#C25508` (accent: frame titles, rules, bullets, the
  series to emphasise), `princetonlogo` `#ED6D0B` (only to match the shield),
  `princetonink` `#262626` (text), `princetonmute` `#787878` (footer, grids, ticks,
  de-emphasised text).
- **Figure palette.** Okabe–Ito, colour-blind safe: `c0` `#0072B2`, `c1` `#E69F00`,
  `c2` `#009E73`, `c3` `#D55E00`, `c4` `#CC79A7`, `c5` `#56B4E9`. Use `princeton`
  for the series you want to emphasise and `c0`…`c5` for everything else. Never
  pair `princeton` with `c3`, which reads as the same colour. No raw red/green/blue.
- **Font.** Carlito (a Calibri metric clone) for text, with old-style, proportional
  figures (`carlito.sty`'s default). Math follows beamer's default font theme:
  Latin letters and digits in Carlito, Greek, brackets and symbols in Euler,
  `\mathbb` and the slanted `\leq`/`\geq` from the AMS fonts. Never set a
  font family in a figure or on a slide.
- **Layout.** 16:9. Frame titles in orange with a thin orange rule under them.
  Footline: date, frame number, logo. Each section opens with an Outline slide.
- **Boxes.** Exactly three, each with its own job. Don't add look-alikes.
  - `block`: neutral titled box with a soft tinted title bar. `exampleblock` and
    theorem-style environments look the same.
  - `alertblock`: the emphasised box, with an orange border and a solid orange
    title bar. `\mainblock{T}{body}` (Quarto: `.mainblock`) is the same box.
  - `boxedblock`: an untitled, centred takeaway.

### Writing slides

- Frame titles in Title Case. Capitalise the principal words, not short
  articles, prepositions or conjunctions ("Accuracy on Held-out Tasks").
- Dataset, model and method names keep their canonical casing; see the table below.
- One idea per slide. If content doesn't fit, split the slide; don't shrink the text.
- Terminology, colours and casing match across slides and figures. A figure that
  brings in its own vocabulary is a bug.

### Figures

- **Legible from the back of the room.** Slide figures need bigger relative text
  than paper figures; there is no zooming on a projector. Each skill gives the
  minimum sizes in its own units.
- **Fits the frame body** with its legend, and leaves room for a lead-in line.
  Never scale a finished figure down to fit, because that shrinks the text too.
  Resize the plot or cut content.
- **No overlap.** No text, label or legend on another element or an axis line. No
  bar or marker clipped at the plot edge.
- **Clean axes.** L-shaped spine, light grid, tight margins.
- One figure per source file. Figures belong to exactly one deck and live inside it.

### Casing reference

Use the canonical form. Extend this as needed, and check the paper or repo when unsure.

| Wrong | Correct |
|---|---|
| Gsm8k, gsm8k | GSM8K |
| Llama, LLAMA | LLaMA (LLaMA 2/3 use `Llama` in Meta's later cards; match the specific paper) |
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

Acronyms stay uppercase (FLOPs, BLEU, ROUGE, F1).

### Done means looked at

A deck or figure isn't done until you have rendered it, opened the result, looked
at it, and checked it against the rules above. Rendering without looking is the
most common failure. Each pathway's README says how to get an image of a slide.
