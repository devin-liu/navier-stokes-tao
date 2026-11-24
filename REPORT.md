# Progress report

Generated 2026-11-23T23:57:40-05:00 by `scripts/nst report` from `ledger/`. Do not edit by hand.

Repository: [devin-liu/navier-stokes-tao](https://github.com/devin-liu/navier-stokes-tao). Every proof counted here was accepted by Lean in a build of the real module; none is counted on a model's say-so.

## Where the targets stand

| State | Count |
|---|---|
| proved-local | 4 |
| merged | 9 |
| stuck | 8 |
| **all targets taken on** | **21** |

Targets that were tried and not proved stay in the total.

## What the proved ones count as

| | Count |
|---|---|
| verified | 9 |
| conditional | 4 |
| unreviewed | 0 |

`verified`: the module builds, the statement was frozen after an independent check against the paper, and the axioms are the standard three. `conditional`: the proof compiles and depends on declarations still `sorry`. `unreviewed`: proved, statement not yet checked against the paper.

Statements frozen: 47.

## How the proved ones were found

| Route | Proved | Merged |
|---|---|---|
| after a model pass | 13 | 9 |

## Cost

- Lean runs with no model call: 48, 7 minutes, 296 proof attempts.
- Model passes: 38 (mid statement gpt-6: usage before unmeasured; mid review gpt-6.2-sol: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid review gpt-6.2-sol: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6.2-sol: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6.2-sol: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid proof claude-fable-5-2: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured).
- A usage figure of `unmeasured` means nobody read the meter; it is not zero.

## Targets

| Declaration | Paper | State | Counts as | Route | PR | Axioms |
|---|---|---|---|---|---|---|
| `longTermBound_implies_shortTermBound` | none | merged | verified | after a model pass | #12 | propext, Classical.choice, Quot.sound |
| `exists_small_gradient_energy` | Section 3.2, before eq. (7 | proved-local | conditional | after a model pass |  | propext, sorryAx, Classical.choice, Quot.sound |
| `forced_heat_energy_estimate` | Lemma 2.1 | stuck |  |  |  |  |
| `kineticEnergy_hasDerivWithinAt` | none | stuck |  |  |  |  |
| `kineticEnergy_identity` | Section 3.2, energy identity | merged | conditional | after a model pass | #18 | propext, sorryAx, Classical.choice, Quot.sound |
| `kineticEnergy_spatialBalance` | none | stuck |  |  |  |  |
| `heat_smoothing` | eq. (5 | proved-local | verified | after a model pass |  | propext, Classical.choice, Quot.sound |
| `globalRegularity_implies_shortTermBound` | Section 3.4 | stuck |  |  |  |  |
| `longTermBound_implies_globalRegularity` | Section 3.1 | stuck |  |  |  |  |
| `shortTermBound_implies_longTermBound` | Section 3.2 | stuck |  |  |  |  |
| `regularityEquivalence` | Theorem 1.4 | proved-local | conditional | after a model pass |  | propext, sorryAx, Classical.choice, Quot.sound |
| `galileanVelocity_initial` | Section 2, mean-zero reduction | merged | verified | after a model pass | #13 | propext, Classical.choice, Quot.sound |
| `galileanVelocity_inverse` | Section 2, mean-zero reduction | merged | verified | after a model pass | #13 | propext, Classical.choice, Quot.sound |
| `h1Norm_sq_galilean_centered` | Section 2, mean-zero reduction | proved-local | verified | after a model pass |  | propext, Classical.choice, Quot.sound |
| `setIntegral_unitCube_translate` | none | merged | verified | after a model pass | #16 | propext, Classical.choice, Quot.sound |
| `smoothSolution_galilean` | Section 2, mean-zero reduction | stuck |  |  |  |  |
| `spatialMean_conserved` | Section 2, mean-zero reduction | stuck |  |  |  |  |
| `spatialMean_galileanVelocity` | Section 2, mean-zero reduction | merged | conditional | after a model pass | #13 | propext, sorryAx, Classical.choice, Quot.sound |
| `integral_periodic_divergence_eq_zero` | none | merged | verified | after a model pass | #19 | propext, Classical.choice, Quot.sound |
| `latticePeriodic_factors_torus` | none | merged | verified | after a model pass | #14 | propext, Classical.choice, Quot.sound |
| `setIntegral_torusPoint` | none | merged | verified | after a model pass | #15 | propext, Classical.choice, Quot.sound |
