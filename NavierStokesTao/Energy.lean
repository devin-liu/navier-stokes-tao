import NavierStokesTao.Setting
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

namespace NavierStokesTao

open MeasureTheory
open scoped BigOperators

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
