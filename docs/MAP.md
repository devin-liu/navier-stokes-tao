# Paper map

Paper: T. Tao, *A quantitative formulation of the global regularity problem for the periodic
Navier–Stokes equation*, arXiv:0710.1604v5. Item numbers are the paper's.

This is the plan of record: which paper item becomes which Lean declaration, in which file,
and what it needs. A `—` in the Lean column means nothing is stated yet; `scripts/nst scout`
counts those. Update the row in the same change that adds or renames the declaration. The
state of each declaration is not kept here: `scripts/nst status` has it.

**How far to trust this page.** It was seeded on 2026-11-23 from the arXiv HTML rendering.
Sections 1 and 2 and the openings of 3.1, 3.2 and 3.4 were read in full. The body of 3.4,
Section 4, footnotes 8 to 10 and equations (12) and (13) were not, and no page numbers were
visible. Rows marked `?` rest on a summary. The first statement pass checks every row it uses
against the source (`scripts/paper.sh`) and removes the mark.

## Milestones

1. **Statements.** The setting, the notion of smooth solution, the `H¹` norm, Conjectures 1.1
   to 1.3 and Theorem 1.4, all frozen. Prove the one implication that needs no analysis: a
   long-term bound gives a short-term bound, with the same function.
2. **Reductions.** Mean-zero reduction, the Duhamel form (4), the energy identity.
3. **Local theory (Section 2).** Lemma 2.1, the smoothing estimate (5), Proposition 2.2.
4. **The three implications (Section 3).** 1.2 ⇒ 1.1, 1.3 ⇒ 1.2, 1.1 ⇒ 1.3, then Theorem 1.4.

Milestone 1 is deliberately small: it exercises every step of the loop, hand-in included,
before anything large is tried, and it tests the definitions before analysis is built on them.

## Choices the first statement pass has to make, and write down here

- **The torus and fields.** Model `Ω = (ℝ/ℤ)³` by its integer-periodic lifts on `Fin 3 → ℝ`,
  with values in `EuclideanSpace ℝ (Fin 3)` for velocity and `ℝ` for pressure. The lifts
  give global Cartesian coordinates for Mathlib's `fderiv` and `Pi.single`. The quotient
  `UnitAddTorus (Fin 3)` has Mathlib's `UnitAddTorus.mFourier` and `UnitAddTorus.mFourierCoeff`.
  Connect the lifts to the quotient when the Fourier theory is introduced. Time is curried
  for slices, with joint smoothness on the product.
- **Smooth solution on `[0,T]`.** The conjectures quantify over smooth `(u, p)` on the closed
  interval. Use `ContDiffOn ℝ ∞` jointly on the closed time interval times all spatial
  coordinates and `derivWithin` on the time slice for the equation, including its endpoints.
  Use the same convention on the closed forward ray for Conjecture 1.1. The source leaves
  the endpoint smoothness convention implicit.
- **The `H¹` norm in the conjectures.** Use the inhomogeneous norm, given on smooth fields
  by the square root of the integral of `|u|² + ∑ᵢ |∂ᵢu|²` over a unit cube. The cube has
  unit Lebesgue measure (`Real.volume_Icc_pi`), so a constant field has its Euclidean norm.
  The notation subsection defines the homogeneous norm only in the mean-zero case, and
  Section 3.2 uses Poincaré to bound `H¹` by the derivative norm there. Equivalent
  inhomogeneous norms give equivalent conjectures by rescaling the bounding functions.
- **Pressure.** Keep a smooth pressure as a separate argument to `SmoothSolution`, as in
  equation (1) and Conjectures 1.1–1.3. Only Conjecture 1.1 asserts existence of a solution
  pair. Section 2 uses Leray projection to eliminate pressure and later recovers it.
- **`F` and `G`.** Nondecreasing `ℝ₊ → ℝ₊`; the same function for all times and solutions.
- **`u(0)` and `u₀`** are used interchangeably in the paper.

## Section 1: statements

| Paper item | What it says | Lean | File | Needs |
|---|---|---|---|---|
| eq. (1) | Periodic incompressible Navier–Stokes on `Ω`, viscosity 1, smooth `u`, `p`, divergence-free smooth data | `SmoothSolution` | `Setting.lean` | |
| Section 1.5, `H¹` in (2)–(3) | Inhomogeneous norm on smooth periodic fields, with the normalization above | `h1Norm` | `Sobolev.lean` | spatial partial derivatives |
| Section 1.5, `H^s_0` | Mean-zero distributions with the norm from nonzero Fourier modes | — | `Sobolev.lean` | |
| Section 2, `X^s_T` | `C⁰_t H^s_0 ∩ L²_t H^{s+1}_0` on `[0,T] × Ω`, with the sum norm | — | `Sobolev.lean` | `H^s_0` |
| Conjecture 1.1 | Every smooth divergence-free datum has a global smooth solution on `[0,∞)` | `globalRegularity` | `Conjectures.lean` | eq. (1) |
| Conjecture 1.2, eq. (2) | A nondecreasing `F` bounds `‖u(T)‖_{H¹}` by `F(‖u₀‖_{H¹})` for every finite `T > 0` and every smooth solution on `[0,T]` | `longTermBound` | `Conjectures.lean` | eq. (1), `H¹` |
| Conjecture 1.3, eq. (3) | The same with a nondecreasing `G` and `0 < T ≤ 1` | `shortTermBound` | `Conjectures.lean` | eq. (1), `H¹` |
| Theorem 1.4 | Conjectures 1.1, 1.2 and 1.3 are equivalent | `regularityEquivalence` | `Main.lean` | Section 3 |
| (not in the paper) | 1.2 ⇒ 1.3 with `G = F` | `longTermBound_implies_shortTermBound` | `Conjectures.lean` | the two statements |

## Section 2: review of the `H¹` theory

| Paper item | What it says | Lean | File | Needs |
|---|---|---|---|---|
| Mean-zero reduction | The mean is conserved; a Galilean change of variables reduces to mean zero. The exact formula must be read from the source | — | `MeanZero.lean` | eq. (1) |
| eq. (4) | Duhamel form with a first-order Fourier multiplier `D` whose range is divergence-free and mean-zero; a smooth solution of (4) with smooth divergence-free data solves (1) for a suitable pressure | — | `Duhamel.lean` | heat semigroup |
| Lemma 2.1 | Energy estimate for the forced heat equation: `‖u‖_{X^s_T} ≲_s ‖u₀‖_{H^s_0} + ‖F‖_{L²_t H^{s-1}_0}` | — | `Energy.lean` | `X^s_T` |
| eq. (5) | Heat smoothing: `‖e^{tΔ} f‖_{H^{s+δ}_0} ≲_{s,δ} t^{-δ/2} ‖f‖_{H^s_0}` | — | `Heat.lean` | `H^s_0` |
| Proposition 2.2(i), eq. (6) | For `‖u₀‖_{H¹_0} ≤ A` and `T = cA⁻⁴`: a unique strong solution in `X¹_T`, bounded by `≲ A`, depending in a Lipschitz way on the data | — | `LocalTheory.lean` | Lemma 2.1, (5), (4) |
| Proposition 2.2(ii) | That solution is smooth for `t > 0` | — | `LocalTheory.lean` | 2.2(i) |
| Proposition 2.2(iii) | Data converging weakly in the ball give solutions converging strongly in `C⁰_t H¹_0([ε,T] × Ω)` | — | `LocalTheory.lean` | 2.2(i), (ii) |
| Energy identity | Called well known and used in 3.2 | — | `Energy.lean` | eq. (1) |

The paper quotes the energy identity, the mean-zero reduction, the existence of `D` and (5)
as standard. In Lean each is its own target.

## Section 3: proof of Theorem 1.4

| Paper item | What it says | Lean | File | Needs |
|---|---|---|---|---|
| 3.1 | 1.2 ⇒ 1.1, by iterating Proposition 2.2: the existence time depends only on the norm, which the bound controls | — | `Implications.lean` | 2.2(i), (ii) |
| 3.2, eq. (7) | From the energy identity and pigeonholing: for `T ≥ ε⁻²` a time `T' ≤ ε⁻²` with `‖u(T')‖_{H¹} ≲_E ε` | — | `Implications.lean` | energy identity, Poincaré |
| 3.2, eq. (8), (9) | Small data stay small: repeat the proof of 2.2 and compare with the heat flow | — | `Implications.lean` | 2.2, (5) |
| 3.2, eq. (10) | Iterate Conjecture 1.3 on `[0,T']` | — | `Implications.lean` | Conjecture 1.3 |
| 3.2 | 1.3 ⇒ 1.2 | — | `Implications.lean` | (7) to (10) |
| Remark 3.3, eq. (11) | A decaying strengthening of (2) in the mean-zero case. Not needed for Theorem 1.4 | — | later | |
| 3.4 `?` | 1.1 ⇒ 1.3, by contradiction and compactness: a sequence of solutions with bounded data and unbounded norm, a weak limit, and 2.2(iii) | — | `Implications.lean` | 2.2(i), (iii), Conjecture 1.1 |
| Section 4 `?` | Remarks. Not read | — | later | |

## Files, in import order

`Basic`, `Setting` → `Sobolev` → `Conjectures` → `MeanZero`, `Heat`, `Energy`, `Duhamel` →
`LocalTheory` → `Implications` → `Main`. One file per row group; split a file when it passes
about 400 lines or when two people would want it at once.
