# Why this repository works the way it does

The process here was first used to contribute proofs to someone else's formalization, with
several agents taking turns in one folder. This page keeps what that taught and says where
each lesson lives here. Read it before changing a script or `AGENTS.md`.

## What carried over unchanged

- **Start with the smallest change that exercises the whole sequence.** Milestone 1 in
  `docs/MAP.md` is a handful of statements and one easy implication, taken through every step
  including the merge, before anything large.
- **Let the records explain the project, and generate the status from them.** `AGENTS.md` for
  how to work, `ledger/attempts.jsonl` for what happened, `ledger/targets.json` and
  `ledger/statements.json` for where things stand, `NEXT.md` for the handover, and
  `scripts/nst report` for the summary. Nobody writes a status from memory.
- **Check where two views of the same thing disagree.** A scratch win against a real module
  build; a local build against CI; the Lean files against the ledger (`scripts/nst sync`); a
  statement's text against the text that was reviewed; the Lean statement against the paper.
- **Give each kind of work to whatever has shown it can do it.** Scripts take the repeatable
  operations, a model takes statements, reviews and the misses, and the operator takes
  judgment about what the project claims.
- **When friction recurs, fix it upstream of the handover.** A script or guide change in the
  same turn, not another warning in `NEXT.md`.
- **The folder is the only memory.** Logs under `runs/`, state in `ledger/`, the handover in
  `NEXT.md`. A scratchpad or a chat transcript is gone for the next agent.
- **A lock is stale only when nothing it started is still running.**

## What the first project got wrong, and what is different here

| What happened | What it cost | Here |
|---|---|---|
| Each outward step waited for its own approval. | Proofs that were ready were overtaken while a question sat unanswered. | The kickoff prompt carries the operator's go-ahead for the session; the hand-in sequence and its skip conditions are fixed in `AGENTS.md`. A skip condition skips that item and the cycle carries on. |
| Accepted proofs stayed as uncommitted edits in the checkout. | Later turns could not update the checkout, and had to work out which edits were still wanted. | Every gate accept is a commit on a cycle branch. Uncommitted Lean edits fail the hand-in. |
| Permissions were written in two files that came to disagree. | An agent could not tell which one held. | One place: "Outward actions" in `AGENTS.md`. |
| The model budget was one pass per file. | Legitimate passes on new targets in a file already visited were refused. | One pass of each kind per target; new input makes a new pass legitimate. |
| A status label was trusted where a slower-moving source of truth disagreed with it. | Work started on items that were not actually available. | State is recomputed from the files themselves by `sync`; GitHub is read by `preflight` before branching and before the pull request. |
| A candidate that timed out was a dead end with no owner. | The time limit was hit and nothing was learned. | A timeout is never rerun as is; the candidate goes back to its author with that note. |
| Proofs that passed could still add minutes to a file's build. | Warnings arrived after the work was done. | The gate compares against the file's recorded time and warns at once; a proof that adds more than a minute is not handed in. |
| A list of stuck targets was sent for a long attempt without rechecking it. | Most of the list was already resolved when the attempt began. | `scripts/nst status` is read at the start of any attempt; it costs one command. |

## What is new because the statements are ours

In the first project the statements were given and frozen by their owner. Here they are
written from the paper, and a formal statement that does not say what the paper says makes
every proof of it worthless while every check stays green.

- **Two gates.** A proof is accepted by a build. A statement is frozen by a reader who did not
  write it, who translates the Lean back into words before opening the paper
  (`prompts/statement-review.md`). The script refuses a review by the agent holding the turn.
- **Definitions are statements.** Changing a definition changes every theorem about it without
  touching their text, so definitions are hashed and frozen with them.
- **A verdict is computed, not typed.** `verified`, `conditional` and `unreviewed` come from
  the axioms Lean reports and from whether the statement is frozen.
- **A gap becomes a target, never a `sorry` inside a proof.** The only `sorry` the lint allows
  is the whole proof of a public theorem, which is what registers it in the ledger.
- **Frozen means frozen, and a change is recorded.** `scripts/nst restate` keeps the old
  statement in the ledger with the reason.

## General principles

- **What a rule can decide, code decides.** Lean is the judge of every proof. A model's
  confidence is never the reason something is counted.
- **Failures stay in the denominator.** Targets tried and not proved are counted in every total.
- **Unmeasured is not zero.** Usage nobody read off the meter is recorded as `unmeasured`.
- **Preserve everything, commit what is small.** Raw run output stays on disk under `runs/`;
  the ledgers are the compact, committed record.
- **Query the ledger; do not re-read the history.**
- **A budget is an authorization, and a past spend is not.**
- **Record where a result came from at the time it is made.** Routes are never reconstructed.
- **Drafted, sent and visible are three states.** Each has its own check.
