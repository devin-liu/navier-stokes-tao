import NavierStokesTao.Setting
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

namespace NavierStokesTao

open MeasureTheory
open scoped BigOperators ContDiff InnerProductSpace

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
      (Set.Icc 0 T) t := sorry

end NavierStokesTao
