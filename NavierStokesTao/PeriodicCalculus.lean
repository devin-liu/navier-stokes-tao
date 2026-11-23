import NavierStokesTao.Setting
import Mathlib.MeasureTheory.Integral.DivergenceTheorem

namespace NavierStokesTao

open MeasureTheory
open scoped BigOperators

/-- The integral over the unit cube of the divergence of a periodic C¹ flux vanishes.
The flux is specified by its scalar coordinate functions. (Paper: none) -/
theorem integral_periodic_divergence_eq_zero (f : Fin 3 → Position → ℝ)
    (hf : ∀ i, ContDiff ℝ 1 (f i)) (hper : ∀ i, LatticePeriodic (f i)) :
    (∫ x in Set.Icc (0 : Position) 1, ∑ i, spatialPartial i (f i) x) = 0 := sorry

end NavierStokesTao
