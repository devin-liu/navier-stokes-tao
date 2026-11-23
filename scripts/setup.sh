#!/usr/bin/env bash
# Make this checkout able to build. Zero model calls.
#
#   scripts/setup.sh                  git identity and hooks, then `lake exe cache get`
#                                     (downloads the built Mathlib, several GB: operator's go-ahead)
#   scripts/setup.sh --reuse DIR      no download: copy-on-write clone of DIR/.lake/packages, where DIR
#                                     is another Lean checkout on this disk pinned to the same Mathlib
#   scripts/setup.sh --local-only     identity and hooks only
#
# It never runs `lake update` and never changes the toolchain or dependency pins.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd); cd "$root"
reuse=""; local_only=0
while [ $# -gt 0 ]; do
  case $1 in
    --reuse) reuse=$2; shift 2 ;;
    --local-only) local_only=1; shift ;;
    --update|--fork|--warm)
      echo "$1 belongs to a workspace that contributes to someone else's repository. This repository is" >&2
      echo "its own upstream: a cycle starts with \`scripts/nst preflight\` and \`scripts/nst branch <slug>\`." >&2
      exit 2 ;;
    *) echo "unknown option $1" >&2; exit 2 ;;
  esac
done

# Commits here are public: the hook refuses a personal address and private text.
git config core.hooksPath scripts/hooks
case $(git config user.email || true) in
  *@users.noreply.github.com) ;;
  *) login=$(gh api user -q .login </dev/null 2>/dev/null || true); id=$(gh api user -q .id </dev/null 2>/dev/null || true)
     if [ -n "$login" ] && [ -n "$id" ]; then
       git config user.email "$id+$login@users.noreply.github.com"; git config user.name "$login"
       echo "git identity for this repository set to the GitHub noreply address of $login"
     else
       echo "set a noreply address yourself: git config user.email <id>+<login>@users.noreply.github.com" >&2
     fi ;;
esac
mkdir -p inbox outbox runs
[ $local_only = 1 ] && { echo "identity and hooks ready"; exit 0; }

echo "toolchain: $(cat lean-toolchain)"
if [ -n "$reuse" ]; then
  [ -d "$reuse/.lake/packages/mathlib" ] || { echo "$reuse has no .lake/packages/mathlib" >&2; exit 1; }
  want=$(python3 -c "import json;print(next(p['rev'] for p in json.load(open('lake-manifest.json'))['packages'] if p['name']=='mathlib'))")
  have=$(git -C "$reuse/.lake/packages/mathlib" rev-parse HEAD)
  [ "$want" = "$have" ] || { echo "Mathlib differs: this project pins $want, $reuse has $have" >&2; exit 1; }
  if [ ! -d .lake/packages/mathlib ]; then
    mkdir -p .lake
    cp -cR "$reuse/.lake/packages" .lake/packages 2>/dev/null || cp -R "$reuse/.lake/packages" .lake/packages
  fi
  echo "packages cloned from $reuse (Mathlib $have)"
else
  free_gb=$(df -g "$root" | awk 'NR==2 {print $4}')
  if [ ! -d .lake/packages/mathlib ] && [ "$free_gb" -lt 15 ]; then
    echo "only ${free_gb} GB free; the Mathlib cache needs about 10 GB. Free space, or use --reuse." >&2; exit 1
  fi
  start=$(date +%s); lake exe cache get </dev/null; echo "cache: $(( $(date +%s) - start ))s"
fi

log="runs/setup-build-$(date +%Y%m%d-%H%M%S).log"; start=$(date +%s)
# If this starts compiling Mathlib's own files, the cache is wrong: stop and fix the setup.
lake build </dev/null >"$log" 2>&1 || { tail -n 20 "$log"; echo "build failed; log: $log" >&2; exit 1; }
if grep -qE '(Building|Compiling|Built) Mathlib\.' "$log"; then
  echo "STOP: lake compiled Mathlib itself. The cache did not apply; fix that before any proof work." >&2; exit 3
fi
echo "build ok in $(( $(date +%s) - start ))s (log: $log); ready @ $(git rev-parse --short HEAD)"
