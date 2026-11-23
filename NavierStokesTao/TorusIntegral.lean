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
  classical
  have onto : Function.Surjective torusPoint := by
    intro z
    have representative (i : Fin 3) : ∃ r : ℝ, (r : UnitAddCircle) = z i :=
      QuotientAddGroup.mk_surjective (z i)
    choose r hr using representative
    exact ⟨r, funext hr⟩
  let representative := Function.surjInv onto
  refine ⟨fun z ↦ f (representative z), ?_⟩
  intro x
  have samePoint : torusPoint (representative (torusPoint x)) = torusPoint x :=
    Function.surjInv_eq onto _
  have shift (i : Fin 3) : ∃ n : ℤ, (n : ℝ) = representative (torusPoint x) i - x i := by
    have sameCoordinate :
        (representative (torusPoint x) i : UnitAddCircle) = (x i : UnitAddCircle) :=
      congrFun samePoint i
    obtain ⟨n, hn⟩ := AddSubgroup.mem_zmultiples_iff.mp
      (QuotientAddGroup.eq_iff_sub_mem.mp sameCoordinate)
    exact ⟨n, by simpa [zsmul_eq_mul] using hn⟩
  choose n hn using shift
  have shifted : representative (torusPoint x) = x + fun i ↦ (n i : ℝ) := by
    funext i
    change representative (torusPoint x) i = x i + (n i : ℝ)
    exact (sub_eq_iff_eq_add.mp (hn i).symm).trans (add_comm _ _)
  change f (representative (torusPoint x)) = f x
  rw [shifted, hPeriodic]

/-- The integral of a torus field against normalized Haar measure equals the integral
of its lift over the closed unit cube. (Paper: none) -/
theorem setIntegral_torusPoint {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (F : UnitAddTorus (Fin 3) → E) :
    (∫ x in Set.Icc (0 : Position) 1, F (torusPoint x)) = ∫ z, F z := by
  sorry

end NavierStokesTao
