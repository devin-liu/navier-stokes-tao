# The statement pass: paper items into Lean statements

You get one pass per group of paper items. Its output is definitions and theorem statements
whose proofs are `sorry`, in one file, that build. Record the pass before you start:
`scripts/nst model-pass --model <name> --tier mid --kind statement --targets <items> --purpose "…"`.

1. Read the rows of `docs/MAP.md` you are taking, and the paper passages for exactly those
   items (`scripts/paper.sh toc`, then line ranges). If a row is marked `?`, check it against
   the source first and correct the map.
2. Search before defining. For every notion (torus, Fourier coefficient, Sobolev norm,
   divergence, smoothness in time and space, heat semigroup) look in Mathlib:
   `grep -rn "<phrase>" .lake/packages/mathlib/Mathlib --include=*.lean | head`. Reuse what
   exists and name the lemma you rely on in the docstring. Write down what is missing.
3. Make each open choice listed in `docs/MAP.md` once, in that file, with the reason. A choice
   that changes what a conjecture says (the norm, the solution class, closed or open time
   interval) is flagged for the operator in `--needs`; do not settle it silently.
4. Write the declarations following "Rules for Lean code" in `AGENTS.md`: a docstring in
   words, a `(Paper: …)` tag, quantifiers in the paper's order, every hypothesis the paper
   has and no others. Where Lean needs more (measurability, a coercion, a nonemptiness), add
   it and say so in the docstring. Proofs are `sorry`. Definitions are complete: a definition
   cannot contain `sorry`.
5. Keep it small. State what the next proofs need, not the whole paper. A statement nobody
   will use for three milestones is a statement nobody will check.
6. `scripts/gate.py check <file>`: it lints, builds the module, registers the targets and
   commits. One repair round on a specific Lean error; after that, stop and write the note.
7. Update the rows of `docs/MAP.md` with the declaration names.

Sanity checks worth a line of Lean each, as `example`s in a scratch file, never committed:
the definitions are not vacuous (a known solution, such as the zero field, satisfies the
predicate), and not trivially false (the norm of a constant is what it should be).

The statements are drafts until someone who did not write them has reviewed them
(`prompts/statement-review.md`). Do not freeze your own.
