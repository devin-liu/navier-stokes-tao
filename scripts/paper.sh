#!/usr/bin/env bash
# The paper, by line range, so nobody loads all of it. Zero model calls.
#
#   scripts/paper.sh fetch            download the arXiv source once into refs/ (untracked; operator's go-ahead)
#   scripts/paper.sh toc              sections and numbered items with their line numbers
#   scripts/paper.sh FIRST LAST       those lines of the TeX source
#   scripts/paper.sh grep PATTERN     matching lines with numbers
#
# The source stays out of git: it is the author's text, and the repository cites it by item.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
id=$(python3 -c "import json;print(json.load(open('$root/config/project.json'))['paper'].split(':')[1])")
dir="$root/refs/$id"
tex() { ls "$dir"/*.tex 2>/dev/null | head -n 1; }
case ${1:-} in
  fetch)
    mkdir -p "$dir"; cd "$dir"
    curl -fsSL -A "lean-formalization-reader" -o source "https://arxiv.org/e-print/$id"
    tar -xf source 2>/dev/null || { gunzip -c source >paper.tex 2>/dev/null || cp source paper.tex; }
    echo "fetched: $(tex) ($(wc -l <"$(tex)") lines)" ;;
  toc)
    [ -n "$(tex)" ] || { echo "no source yet: scripts/paper.sh fetch" >&2; exit 1; }
    grep -nE '\\(sub)*section\*?\{|\\begin\{(theorem|lemma|proposition|conjecture|corollary|definition|remark)\}|\\label\{' "$(tex)" | cut -c1-150 ;;
  grep) grep -nE -- "$2" "$(tex)" | cut -c1-220 ;;
  ''|-h|--help) sed -n '2,10p' "$0" ;;
  *) sed -n "${1},${2}p" "$(tex)" ;;
esac
