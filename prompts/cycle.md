# Running cycles

Paste this into a fresh desktop agent whose working folder is this one. Replace the name. A
cycle takes one file, or one group of paper items, from the map to a merged pull request. The
agent keeps running cycles until one of the stop conditions at the end holds.

The second paragraph is the operator's go-ahead for that session. Delete or narrow it before
pasting if you want to be asked first.

> You are running cycles in this folder as `claude-desktop`. Read `AGENTS.md`, then run
> `scripts/nst status`, `scripts/nst turn start --agent claude-desktop` and `scripts/nst sync`.
> If the turn is held by someone else, or `pgrep -fl 'lake|setup.sh|firstpass|gate.py'` shows a
> run, say so and stop. If `sync` reports problems, sort them out first.
>
> My go-ahead for this session, without asking again: `scripts/paper.sh fetch` once; and for
> work that passed `scripts/gate.py handin`, the whole hand-in sequence in `AGENTS.md` ("What a
> go-ahead for hand-in covers"): push the cycle branch, open the pull request, and squash-merge
> it once CI is green. Its skip conditions apply: skip and carry on, do not stop to ask.
> Everything else that leaves this machine, ask me first.
>
> Each cycle, cheapest step first, using only the scripts:
>
> 0. **Sync.** On `main` with a clean tree: `scripts/nst preflight`, then
>    `scripts/nst branch <slug>`. If a cycle branch is already checked out, finish it instead.
> 1. **Inbox.** For each file in `inbox/` that `scripts/nst status` lists as not checked:
>    `scripts/firstpass.py <file> --decl … --candidates inbox --route private`, then
>    `scripts/gate.py apply` for each win.
> 2. **Open pull requests.** For each target in `pr-open`, read `gh pr view <n>`; merge and set
>    `merged` if CI is green, fix and push if it failed.
> 3. **Pick the work.** Follow "Next action" in `NEXT.md` if it names one; otherwise
>    `scripts/nst scout`: the lowest file in the import order with open targets, or, if the map
>    has items with no Lean declaration that those targets need, the next milestone in
>    `docs/MAP.md`.
> 4. **Statements, if needed.** One statement pass (`prompts/statement-pass.md`), then
>    `scripts/gate.py check <file>`. Then an independent review of each new statement by a
>    fresh subagent that did not write it (`prompts/statement-review.md`), and
>    `scripts/nst freeze` for the ones it passes. A statement the review rejects is fixed once
>    and reviewed again; after that it stays a draft with a note for me.
> 5. **Proofs.** `scripts/firstpass.py <file> --all-sorry`, `scripts/gate.py apply` for each
>    win, then one model pass over the misses (`prompts/model-pass.md`). If two or more misses
>    wait on the same missing fact, state it as its own theorem (step 4) and prove the others
>    from it. Mark what is still unproved `stuck` with a note.
> 6. **Hand-in, in the same turn.** `scripts/gate.py handin` in the background with its log
>    under `runs/`, `scripts/nst draft pr`, read the diff and the draft, then the hand-in
>    sequence under my go-ahead. After the merge, `scripts/nst report` and commit `REPORT.md`
>    with the next cycle's branch.
>
> Then start the next cycle. Stop, and run
> `scripts/nst turn end --did "…" --next "…" --needs "…"`, when: every open target has had its
> one proof pass and nothing new can be stated without a decision from me; or a statement
> choice in `docs/MAP.md` needs my judgment; or the same failure happened twice and the fix is
> not a script or guide change you can make; or you have run three cycles. List the stuck
> targets in `--needs` so I can decide which go to a private attempt. Then tell me in three
> lines what changed, what is next, and what you need from me.

Stuck targets that the operator sends for a private attempt come back as `inbox/` files, and
step 1 of the next cycle picks them up. How that attempt is started is in the untracked
`LOCAL.md`, not here.
