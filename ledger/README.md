# Ledgers

Read them through `scripts/nst status`, `scripts/nst show <decl>` and `scripts/nst report`.
Write them only through the scripts. `scripts/nst check` and `scripts/nst sync` verify them.

- `targets.json`: one row per public theorem taken on, keyed by name. The only source for the
  current state of a proof. Fields: `file`, `paper`, `state`, `route`, `model`, `pr`, `axioms`,
  `inherited_sorry`, `stmt_hash`, `build_secs`, `note`, `updated`.
- `statements.json`: one row per frozen declaration (theorem, definition or structure): the
  statement verbatim, its hash, the paper item, who reviewed it and on what basis.
- `attempts.jsonl`: append-only, one JSON object per line. `type` is one of
  `compile` (a Lean run: tier, seconds, attempts, `model_calls: 0`),
  `try` (one tactic or candidate on one declaration: `route`, `label`, `result`, `detail`),
  `apply` (the gate: `result`, `axioms`, `stmt_hash`, `build_secs`),
  `statement-check`, `freeze`, `restate`, `time`, `state` (a transition), `preflight`,
  `model-pass`, `usage`, `handin-check`.
- `sessions.jsonl`: append-only, one row per turn: who, when, what was done, what is next.

States: `open`, `proved-local`, `pr-open`, `merged`, `stuck`, `finding`, `external`.
Routes: `lean-only`, `model`, `private`, `human`.

What a proved target counts as is computed from these, never stored: `verified` (frozen
statement, standard axioms only), `conditional` (`sorryAx` among the axioms), `unreviewed`
(statement not frozen).

`result` values for a `try`: `win` (no error, no `sorry`, Lean finished), `miss`, `timeout`
(Lean did not finish; says nothing about the proof), `invalid` (the file itself failed before
the target; nothing was tested).
