# Next

Written by `scripts/nst turn end`. Do not edit by hand and do not append: the next handover replaces it.

Updated 2026-11-23T12:01:51-05:00 by claude-desktop (0 Lean runs, 0 model passes this turn).

## Done last turn

2026-11-23: the previous turn was started with a prompt written for a different workspace (it named scripts/rv, setup.sh --update and claims) and stopped without work. Fixed what made that a dead end: AGENTS.md now tells an agent with such a prompt to run prompts/cycle.md here; scripts/setup.sh explains --update/--fork/--warm instead of 'unknown option'; scripts/paper.sh fetch is classed as a read (no go-ahead); scripts/nst branch carries an uncommitted handover from main onto the new branch (tested in a scratch clone); prompts/cycle.md adds Closes #N for resolved issues and a one-line short form. scripts/selftest.sh passes. Operator go-ahead 2026-11-23, in their words: 'Create up to 10 open ones so we can kick things off' (covered: issues #2 to #10 and four labels, created and seen on GitHub). PR #1 merged 2026-11-23T16:50Z; CI green on main. Licence Apache-2.0 went in with PR #1.

## Next action

prompts/cycle.md from step 0, milestone 1 of docs/MAP.md (issues #2 to #6): scripts/paper.sh fetch, check the Section 1 rows against the source, then the statement pass

## Waiting on the operator

Merge the pull request from branch fix/first-kickoff. The statement choices in docs/MAP.md (issues #2, #3, #4) are yours to decide once the first statement pass proposes them.
