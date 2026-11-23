# The statement review: an independent reading

A statement is frozen when a reader who did not write it finds that it says what the paper
says. The reviewer is a fresh context: a subagent started for this, another desktop agent, or
a person. It gets this page, the Lean declarations, and the paper. It does not get the
author's notes or reasoning. Record it first:
`scripts/nst model-pass --model <name> --tier mid --kind review --targets A,B --purpose "…"`.

For each declaration, in this order:

1. **Back-translate first.** Read only the Lean (the declaration and every definition it
   unfolds to, by line range) and write, in plain mathematical English, exactly what it
   asserts: every quantifier in order, every hypothesis, every norm and space. Do this before
   opening the paper.
2. **Then compare** with the paper item named in the `(Paper: …)` tag
   (`scripts/paper.sh`). List every difference, however small: a missing or extra hypothesis,
   a quantifier in a different place, `<` against `≤`, a closed against an open interval, a
   different norm, a constant made explicit, an existence claim where the paper assumes
   existence.
3. **Probe the definitions.** Is the predicate satisfiable (name an object that satisfies
   it)? Is the statement vacuous, or true for a trivial reason the paper does not intend? Does
   a degenerate case (zero data, `T` at an endpoint, a constant field) behave as the paper says?
4. **Verdict per declaration:** `matches`; `differs, intended` (the difference is stated in
   the docstring and is harmless or necessary, say why); or `differs, wrong`.

Write the review to `runs/review-<date>-<file>.md`. Then, for each `matches` or
`differs, intended`:

`scripts/nst freeze <decl> … --reviewer <who> --basis "<what was compared, and the review file>"`

The reviewer named must not be the agent holding the turn; a subagent is named
`<model>:subagent`. For `differs, wrong`, the author fixes it once and it is reviewed again.
A statement the reviewer cannot decide stays a draft, with the question in `--needs`.

Definitions are reviewed and frozen with the statements that use them.
