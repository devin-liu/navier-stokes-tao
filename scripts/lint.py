#!/usr/bin/env python3
"""Text rules for the Lean library. Zero model calls, no Lean run. Also run by CI.

  scripts/lint.py              every file of the library
  scripts/lint.py FILE ...     the named files

Rules (AGENTS.md, "Rules for Lean code"):
  * no `axiom`, `native_decide`, `#eval`, `admit`, `sorryAx`, `implemented_by`, `unsafe`,
    no raised `maxHeartbeats`, no `autoImplicit true`;
  * `sorry` only as the whole proof of a non-private theorem or lemma (that is what makes it a
    registered target), never inside a proof, a definition or a private helper;
  * every non-private theorem, lemma, definition and structure has a docstring with a
    `(Paper: <item>)` tag, or `(Paper: none)` for infrastructure the paper does not state;
  * lines of at most 100 characters.
"""
from __future__ import annotations

import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import nstlib as rv  # noqa: E402

FORBIDDEN = re.compile(r"\b(admit|sorryAx|native_decide|implemented_by|unsafe)\b|maxHeartbeats|#eval\b|^\s*axiom\b"
                       r"|autoImplicit\s+true", re.M)


def main() -> None:
    wt = rv.worktree()
    files = sys.argv[1:] or rv.lean_files(wt)
    problems = []
    for rel in files:
        text = (wt / rel).read_text(encoding="utf-8")
        code = rv.strip_comments(text)
        for m in FORBIDDEN.finditer(code):
            problems.append(f"{rel}: forbidden `{m.group(0).strip()}`")
        decls = rv.declarations(text)
        allowed = sum(d["sorry"] and not d["private"] for d in decls)
        found = len(re.findall(r"\bsorry\b", code))
        if found != allowed:
            problems.append(f"{rel}: {found} `sorry` in code, but only {allowed} are the whole proof of a public theorem. "
                            "A `sorry` inside a proof, a definition or a private helper is not allowed: state the gap as its own theorem.")
        for d in decls:
            if d["private"]:
                continue
            if not d["has_doc"]:
                problems.append(f"{rel}:{d['line']}: {d['kind']} {d['name']} has no docstring")
            elif not d["paper"]:
                problems.append(f"{rel}:{d['line']}: {d['kind']} {d['name']}: docstring has no `(Paper: …)` tag")
        for i, line in enumerate(text.splitlines(), 1):
            if len(line) > 100:
                problems.append(f"{rel}:{i}: line has {len(line)} characters (limit 100)")
    for p in problems[:60]:
        print(p)
    print(f"lint: {len(files)} files, {len(problems)} problems")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
