import NavierStokesTao.Setting
import Mathlib.MeasureTheory.Integral.DivergenceTheorem

namespace NavierStokesTao

open MeasureTheory
open scoped BigOperators

/-- The integral over the unit cube of the divergence of a periodic C¹ flux vanishes.
The flux is specified by its scalar coordinate functions. (Paper: none) -/
theorem integral_periodic_divergence_eq_zero (f : Fin 3 → Position → ℝ)
    (hf : ∀ i, ContDiff ℝ 1 (f i)) (hper : ∀ i, LatticePeriodic (f i)) :
    (∫ x in Set.Icc (0 : Position) 1, ∑ i, spatialPartial i (f i) x) = 0 := by
  have hc : Continuous (fun x : Position ↦ ∑ i, spatialPartial i (f i) x) := by
    apply continuous_finsetSum
    intro i _
    exact ((hf i).continuous_fderiv one_ne_zero).clm_apply continuous_const
  have hint := hc.continuousOn.integrableOn_compact (μ := volume)
    (isCompact_Icc (a := (0 : Position)) (b := 1))
  simp only [spatialPartial]
  rw [integral_divergence_of_hasFDerivAt_off_countable' (0 : Position) 1
    (fun i ↦ zero_le_one) f (fun i ↦ fderiv ℝ (f i)) ∅ Set.countable_empty
    (fun i ↦ (hf i).continuous.continuousOn)
    (fun x _ i ↦ ((hf i).differentiable_one x).hasFDerivAt) hint]
  apply Finset.sum_eq_zero
  intro i _
  let shift : Fin 3 → ℤ := Pi.single i 1
  have hface (x : Fin 2 → ℝ) :
      i.insertNth (1 : ℝ) x = i.insertNth (0 : ℝ) x + fun j ↦ (shift j : ℝ) := by
    funext j
    refine Fin.succAboveCases i ?_ (fun k ↦ ?_) j
    · simp [shift]
    · simp [shift, Pi.single_eq_of_ne (Fin.succAbove_ne i k)]
  have hflux :
      (fun x : Fin 2 → ℝ ↦ f i (i.insertNth (1 : ℝ) x)) =
        fun x : Fin 2 → ℝ ↦ f i (i.insertNth (0 : ℝ) x) := by
    funext x
    rw [hface x]
    exact hper i shift (i.insertNth (0 : ℝ) x)
  simp only [Pi.one_apply, Pi.zero_apply, hflux, sub_self]

end NavierStokesTao
