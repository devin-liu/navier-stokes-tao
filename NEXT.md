# Next

Written by `scripts/nst turn end`. Do not edit by hand and do not append: the next handover replaces it.

Updated 2026-11-23T12:48:01-05:00 by claude-desktop (0 Lean runs, 0 model passes this turn).

## Done last turn

Review turn as claude-desktop, no Lean run, no model pass, nothing sent. Operator request in this session, in their words: “Review the latest progress and update ./NEXT.md if needed”; no go-ahead for outward actions was given or used. Commands read: nst status, sync (7 files, 0 problems), scout, preflight, gh pr list, gh issue list, nst show on the six unfinished targets. State: 11 targets, merged 5 (4 verified, 1 conditional), open 1, stuck 5; 27 statements frozen. GitHub as observed 2026-11-23 17:47Z: PRs #1, #11, #12, #13, #14 merged, 0 open PRs, issues #7, #9, #10 open; preflight verdict clear. Local cycle/1123-periodic-cube is 3 commits ahead of origin/main and 0 behind before this handover; those commits touch only NEXT.md, REPORT.md and the ledger, are not pushed, and contain no Lean change. Gaps: (1) Theorem 1.4 (regularityEquivalence) is frozen with 0 tries and waits on Section 3. (2) docs/MAP.md has 17 paper items with no Lean declaration, starting at Section 1.5 H^s_0, then X^s_T, eq. (4), Lemma 2.1, eq. (5), Proposition 2.2(i)-(iii); H^s_0 is the root dependency of the others, and stating them needs no operator decision. (3) All five stuck targets have used their one mid-tier proof pass, so by the spending rules none may be retried without new input or the operator's agreement. (4) spatialMean_galileanVelocity is conditional on setIntegral_unitCube_translate; the stuck notes of that target and of setIntegral_torusPoint both go through UnitAddTorus.integral_preimage. (5) inbox/setIntegral_torusPoint.c01.lean still fails only at the last step: ae volume on Position versus ae of Measure.pi of real volume. MeasureTheory.volume_pi exists at Mathlib/MeasureTheory/Constructions/Pi.lean:662 (grep), still untested. The other five inbox files are candidates already applied and merged.

## Next action

On cycle/1123-periodic-cube, run the statement pass (prompts/statement-pass.md, after scripts/nst model-pass --kind statement) for Section 1.5 H^s_0 in NavierStokesTao/Sobolev.lean, then scripts/gate.py check NavierStokesTao/Sobolev.lean.

## Waiting on the operator

Decide for setIntegral_torusPoint: agree to one extra mid-tier proof pass that tests the volume_pi rewrite on inbox/setIntegral_torusPoint.c01.lean (outside the one-pass rule, so it needs your word), or send it to a private attempt. Stuck targets for private-attempt selection: setIntegral_torusPoint, setIntegral_unitCube_translate, spatialMean_conserved, smoothSolution_galilean, h1Norm_sq_galilean_centered. Also yours: whether the three local report and handover commits on cycle/1123-periodic-cube go out now or ride with the next hand-in.
