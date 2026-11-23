import NavierStokesTao.Setting
import Mathlib.Analysis.Fourier.AddCircleMulti

namespace NavierStokesTao

open MeasureTheory

/-- The point of Mathlib's unit three-torus represented by a vector of real coordinates.
(Paper: eq. (1)) -/
def torusPoint (x : Position) : UnitAddTorus (Fin 3) :=
  fun i ↦ (x i : UnitAddCircle)

/-- Every integer-periodic field on the cover factors through the unit three-torus, with
no regularity assumption. (Paper: none) -/
theorem latticePeriodic_factors_torus {E : Type*} (f : Position → E)
    (hPeriodic : LatticePeriodic f) :
    ∃ F : UnitAddTorus (Fin 3) → E, ∀ x, F (torusPoint x) = f x := by
  sorry

/-- The integral of a torus field against normalized Haar measure equals the integral
of its lift over the closed unit cube. (Paper: none) -/
theorem setIntegral_torusPoint {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (F : UnitAddTorus (Fin 3) → E) :
    (∫ x in Set.Icc (0 : Position) 1, F (torusPoint x)) = ∫ z, F z := by
  sorry

end NavierStokesTao
