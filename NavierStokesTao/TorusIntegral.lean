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
  have cube : (Set.pi Set.univ fun i : Fin 3 ↦ Set.Ioc ((0 : Position) i) ((1 : Position) i))
      =ᵐ[(volume : Measure Position)] Set.Icc (0 : Position) 1 := by
    rw [volume_pi]
    exact Measure.univ_pi_Ioc_ae_eq_Icc
  have sameSet :
      {x : Position | ∀ i, x i ∈ Set.Ioc ((0 : Position) i) ((0 : Position) i + 1)} =
        Set.pi Set.univ fun i : Fin 3 ↦ Set.Ioc ((0 : Position) i) ((1 : Position) i) := by
    ext x
    simp [Set.mem_pi]
  have circleVolume : (volume : Measure UnitAddCircle) = AddCircle.haarAddCircle := by
    simpa using (AddCircle.volume_eq_smul_haarAddCircle (T := (1 : ℝ)))
  have torusVolume : (volume : Measure (UnitAddTorus (Fin 3))) =
      Measure.pi (fun _ : Fin 3 ↦ AddCircle.haarAddCircle) := by
    change Measure.pi (fun _ : Fin 3 ↦ (volume : Measure UnitAddCircle)) = _
    simp only [circleVolume]
  rw [torusVolume]
  refine Eq.trans ?_ (UnitAddTorus.integral_preimage F (0 : Position)).symm
  rw [sameSet]
  exact setIntegral_congr_set cube.symm

end NavierStokesTao
