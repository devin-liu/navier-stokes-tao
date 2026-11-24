# Progress report

Generated 2026-11-24T13:58:41-05:00 by `scripts/nst report` from `ledger/`. Do not edit by hand.

Repository: [devin-liu/navier-stokes-tao](https://github.com/devin-liu/navier-stokes-tao). Every proof counted here was accepted by Lean in a build of the real module; none is counted on a model's say-so.

## Where the targets stand

| State | Count |
|---|---|
| proved-local | 2 |
| merged | 16 |
| stuck | 5 |
| **all targets taken on** | **23** |

Targets that were tried and not proved stay in the total.

## What the proved ones count as

| | Count |
|---|---|
| verified | 17 |
| conditional | 1 |
| unreviewed | 0 |

| Conditional result | Open statements it rests on |
|---|---|
| `regularityEquivalence` | `globalRegularity_implies_shortTermBound`, `longTermBound_implies_globalRegularity`, `shortTermBound_implies_longTermBound` |

`verified`: the module builds, the statement was frozen after an independent check against the paper, and the axioms are the standard three. `conditional`: the proof compiles and depends on declarations still `sorry`. `unreviewed`: proved, statement not yet checked against the paper.

Statements frozen: 49.

## How the proved ones were found

| Route | Proved | Merged |
|---|---|---|
| after a model pass | 16 | 14 |
| undisclosed method | 2 | 2 |

## Cost

- Lean runs with no model call: 58, 9 minutes, 316 proof attempts.
- Model passes: 44 (mid statement gpt-6: usage before unmeasured; mid review gpt-6.2-sol: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid review gpt-6.2-sol: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6.2-sol: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6.2-sol: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid proof claude-fable-5-2: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6: usage before unmeasured; mid statement gpt-6: usage before unmeasured; mid review gpt-6: usage before unmeasured; mid proof gpt-6: usage before unmeasured; mid proof claude-opus-5-5: usage before unmeasured).
- A usage figure of `unmeasured` means nobody read the meter; it is not zero.

## Targets

| Declaration | Paper | State | Counts as | Route | PR | Axioms |
|---|---|---|---|---|---|---|
| `longTermBound_implies_shortTermBound` | none | merged | verified | after a model pass | #12 | propext, Classical.choice, Quot.sound |
| `exists_small_gradient_energy` | Section 3.2, before eq. (7 | merged | verified | after a model pass | #20 | propext, Classical.choice, Quot.sound |
| `forced_heat_energy_estimate` | Lemma 2.1 | stuck |  |  |  |  |
| `hasDerivWithinAt_setIntegral_Icc` | none | proved-local | verified | after a model pass |  | propext, Classical.choice, Quot.sound |
| `kineticEnergy_hasDerivWithinAt` | none | proved-local | verified | after a model pass |  | propext, Classical.choice, Quot.sound |
| `kineticEnergy_identity` | Section 3.2, energy identity | merged | verified | after a model pass | #18 | propext, Classical.choice, Quot.sound |
| `kineticEnergy_spatialBalance` | none | merged | verified | undisclosed method | #21 | propext, Classical.choice, Quot.sound |
| `heat_smoothing` | eq. (5 | merged | verified | after a model pass | #20 | propext, Classical.choice, Quot.sound |
| `globalRegularity_implies_shortTermBound` | Section 3.4 | stuck |  |  |  |  |
| `longTermBound_implies_globalRegularity` | Section 3.1 | stuck |  |  |  |  |
| `shortTermBound_implies_longTermBound` | Section 3.2 | stuck |  |  |  |  |
| `regularityEquivalence` | Theorem 1.4 | merged | conditional | after a model pass | #20 | propext, sorryAx, Classical.choice, Quot.sound |
| `galileanVelocity_initial` | Section 2, mean-zero reduction | merged | verified | after a model pass | #13 | propext, Classical.choice, Quot.sound |
| `galileanVelocity_inverse` | Section 2, mean-zero reduction | merged | verified | after a model pass | #13 | propext, Classical.choice, Quot.sound |
| `h1Norm_sq_galilean_centered` | Section 2, mean-zero reduction | merged | verified | after a model pass | #20 | propext, Classical.choice, Quot.sound |
| `setIntegral_unitCube_translate` | none | merged | verified | after a model pass | #16 | propext, Classical.choice, Quot.sound |
| `smoothSolution_galilean` | Section 2, mean-zero reduction | stuck |  |  |  |  |
| `spatialMean_conserved` | Section 2, mean-zero reduction | merged | verified | undisclosed method | #21 | propext, Classical.choice, Quot.sound |
| `spatialMean_galileanVelocity` | Section 2, mean-zero reduction | merged | verified | after a model pass | #13 | propext, Classical.choice, Quot.sound |
| `integral_periodic_divergence_eq_zero` | none | merged | verified | after a model pass | #19 | propext, Classical.choice, Quot.sound |
| `integral_periodic_spatialPartial_eq_zero` | none | merged | verified | after a model pass | #21 | propext, Classical.choice, Quot.sound |
| `latticePeriodic_factors_torus` | none | merged | verified | after a model pass | #14 | propext, Classical.choice, Quot.sound |
| `setIntegral_torusPoint` | none | merged | verified | after a model pass | #15 | propext, Classical.choice, Quot.sound |
