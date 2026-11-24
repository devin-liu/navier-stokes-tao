import NavierStokesTao.Heat
import Mathlib.Analysis.Calculus.ContDiff.Comp
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

namespace NavierStokesTao

open MeasureTheory
open scoped BigOperators ContDiff InnerProductSpace

/-- Modewise Duhamel formula for the heat equation with prescribed forcing.
(Paper: Lemma 2.1) -/
noncomputable def forcedHeatCoefficients {E : Type*} [NormedAddCommGroup E]
    [NormedSpace ℝ E] (a : (Fin 3 → ℤ) → E) (F : ℝ → (Fin 3 → ℤ) → E)
    (t : ℝ) (k : Fin 3 → ℤ) : E :=
  heatCoefficients t a k + ∫ r in (0 : ℝ)..t, heatCoefficients (t - r) (F r) k

/-- The forced heat flow is continuous in order s and square integrable in time in
order s+1. Its bound is uniform over finite time intervals, including T = 0.
Mean zero is built into the data predicates. The coefficient space is generalized
to a complete real normed space for the modewise integral. (Paper: Lemma 2.1) -/
theorem forced_heat_energy_estimate {E : Type*} [NormedAddCommGroup E]
    [NormedSpace ℝ E] [CompleteSpace E] (s : ℝ) :
    ∃ C : ℝ, 0 < C ∧ ∀ (T : ℝ), 0 ≤ T →
      ∀ (F : ℝ → (Fin 3 → ℤ) → E) (a : (Fin 3 → ℤ) → E),
        SobolevTimeL2 (s - 1) T F → MeanZeroSobolev s a →
        InXT s T (forcedHeatCoefficients a F) ∧
          xTNorm s T (forcedHeatCoefficients a F) ≤
            C * (meanZeroSobolevNorm s a + sobolevTimeL2Norm (s - 1) T F) := sorry

/-- Differentiate the squared velocity norm integrated over the cube along a smooth time
family, with inward derivatives at the endpoints. (Paper: none) -/
theorem kineticEnergy_hasDerivWithinAt {T : ℝ} {u : ℝ → Position → Velocity}
    (hT : 0 < T)
    (hu : ContDiffOn ℝ ∞ (fun z : ℝ × Position ↦ u z.1 z.2) (Set.Icc 0 T ×ˢ Set.univ))
    (t : ℝ) (ht : t ∈ Set.Icc 0 T) :
    HasDerivWithinAt
      (fun s ↦ ∫ x in Set.Icc (0 : Position) 1, ‖u s x‖ ^ 2)
      (∫ x in Set.Icc (0 : Position) 1,
        2 * ⟪u t x, derivWithin (fun s ↦ u s x) (Set.Icc 0 T) t⟫_ℝ)
      (Set.Icc 0 T) t := sorry

/-- Pair the spatial terms of the momentum equation with a smooth periodic divergence-free
velocity. The advection and pressure integrals vanish, leaving the viscous dissipation.
(Paper: none) -/
theorem kineticEnergy_spatialBalance (v : Position → Velocity) (q : Position → ℝ)
    (hv : ContDiff ℝ ∞ v) (hq : ContDiff ℝ ∞ q)
    (hvper : LatticePeriodic v) (hqper : LatticePeriodic q)
    (hdiv : ∀ x, spatialDivergence v x = 0) :
    (∫ x in Set.Icc (0 : Position) 1, 2 * ⟪v x,
      spatialLaplacian v x - pressureGradient q x - fderiv ℝ v x (v x).ofLp⟫_ℝ) =
      -2 * ∫ x in Set.Icc (0 : Position) 1, ∑ i : Fin 3, ‖spatialPartial i v x‖ ^ 2 := sorry

/-- The kinetic energy identity on the unit torus for a smooth solution on a finite interval.
The time derivative is taken within the interval, including at its endpoints, as in
`SmoothSolution`. No spatial mean condition is needed. (Paper: Section 3.2, energy identity) -/
theorem kineticEnergy_identity {T : ℝ} {u₀ : Position → Velocity}
    {u : ℝ → Position → Velocity} {p : ℝ → Position → ℝ}
    (hT : 0 < T) (hu : SmoothSolution (Set.Icc 0 T) u₀ u p)
    (t : ℝ) (ht : t ∈ Set.Icc 0 T) :
    HasDerivWithinAt
      (fun s ↦ ∫ x in Set.Icc (0 : Position) 1, ‖u s x‖ ^ 2)
      (-2 * ∫ x in Set.Icc (0 : Position) 1, ∑ i : Fin 3, ‖spatialPartial i (u t) x‖ ^ 2)
      (Set.Icc 0 T) t := by
  have hslice : ContDiff ℝ ∞ (fun x : Position ↦ (t, x)) :=
    contDiff_const.prodMk contDiff_id
  have hv : ContDiff ℝ ∞ (u t) :=
    ContDiffOn.comp_contDiff (f := fun x : Position ↦ (t, x)) hu.velocitySmooth hslice
      (fun _ ↦ ⟨ht, Set.mem_univ _⟩)
  have hp : ContDiff ℝ ∞ (p t) :=
    ContDiffOn.comp_contDiff (f := fun x : Position ↦ (t, x)) hu.pressureSmooth hslice
      (fun _ ↦ ⟨ht, Set.mem_univ _⟩)
  have htime (x : Position) :
      derivWithin (fun s ↦ u s x) (Set.Icc 0 T) t =
        spatialLaplacian (u t) x - pressureGradient (p t) x -
          fderiv ℝ (u t) x (u t x).ofLp :=
    eq_sub_iff_add_eq.mpr (hu.momentum t ht x)
  have h := kineticEnergy_hasDerivWithinAt hT hu.velocitySmooth t ht
  simp only [htime] at h
  rw [kineticEnergy_spatialBalance (u t) (p t) hv hp
    (hu.velocityPeriodic t ht) (hu.pressurePeriodic t ht) (hu.incompressible t ht)] at h
  exact h

/-- On any positive initial subinterval, some interior time has squared gradient
energy at most the initial kinetic energy divided by twice the subinterval length.
This is the averaging step before Poincaré, and allows arbitrary spatial mean.
(Paper: Section 3.2, before eq. (7)) -/
theorem exists_small_gradient_energy {T L : ℝ} {u₀ : Position → Velocity}
    {u : ℝ → Position → Velocity} {p : ℝ → Position → ℝ}
    (hL : 0 < L) (hLT : L ≤ T) (hu : SmoothSolution (Set.Icc 0 T) u₀ u p) :
    ∃ t ∈ Set.Ioo 0 L,
      (∫ x in Set.Icc (0 : Position) 1, ∑ i : Fin 3, ‖spatialPartial i (u t) x‖ ^ 2) ≤
        (∫ x in Set.Icc (0 : Position) 1, ‖u₀ x‖ ^ 2) / (2 * L) := sorry

end NavierStokesTao
