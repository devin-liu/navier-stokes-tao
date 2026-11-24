import NavierStokesTao.Sobolev

namespace NavierStokesTao

/-- Heat evolution of Fourier coefficients on the unit-period torus. Its Laplacian
eigenvalue at mode `k` is `-4π² |k|²` in Mathlib's Fourier normalization.
(Paper: eq. (5)) -/
noncomputable def heatCoefficients {E : Type*} [SMul ℝ E]
    (t : ℝ) (a : (Fin 3 → ℤ) → E) (k : Fin 3 → ℤ) : E :=
  Real.exp (-(4 * Real.pi ^ 2 * modeLengthSq k * t)) • a k

private theorem heat_smoothing_modeLengthSq_pos (k : Fin 3 → ℤ) (hk : k ≠ 0) :
    0 < modeLengthSq k := by
  have hex : ∃ i, k i ≠ 0 := by
    by_contra! hn
    exact hk (funext hn)
  obtain ⟨i, hi⟩ := hex
  have hcast : (k i : ℝ) ≠ 0 := by exact_mod_cast hi
  have hle : (k i : ℝ) ^ 2 ≤ modeLengthSq k :=
    Finset.single_le_sum (fun j _ => sq_nonneg (k j : ℝ)) (Finset.mem_univ i)
  exact (sq_pos_of_ne_zero hcast).trans_le hle

/-- Positive-time heat evolution gains any positive number of Sobolev derivatives
with a constant independent of time and the input coefficients. The assertion is
stated in the complexified Fourier representation. (Paper: eq. (5)) -/
theorem heat_smoothing {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (s δ : ℝ) (hδ : 0 < δ) :
    ∃ C : ℝ, 0 < C ∧ ∀ (t : ℝ) (a : (Fin 3 → ℤ) → E),
      0 < t → MeanZeroSobolev s a →
      MeanZeroSobolev (s + δ) (heatCoefficients t a) ∧
        meanZeroSobolevNorm (s + δ) (heatCoefficients t a) ≤
          C * t ^ (-δ / 2) * meanZeroSobolevNorm s a := by
  let b : ℝ := 8 * Real.pi ^ 2
  have hb : 0 < b := by dsimp [b]; positivity
  let m : ℝ := δ / b
  have hm : 0 < m := div_pos hδ hb
  refine ⟨Real.exp (Real.log m * δ / 2), Real.exp_pos _, ?_⟩
  intro t a ht ha
  let K : ℝ := Real.exp (Real.log m * δ / 2) * t ^ (-δ / 2)
  have hK : 0 ≤ K := by dsimp [K]; positivity
  have hbound (k : Fin 3 → ℤ) :
      sobolevModeEnergy (s + δ) (heatCoefficients t a) k ≤
        K ^ 2 * sobolevModeEnergy s a k := by
    by_cases hk : k = 0
    · simp [sobolevModeEnergy, hk]
    have hq := heat_smoothing_modeLengthSq_pos k hk
    let q := modeLengthSq k
    change 0 < q at hq
    have hratio : 0 < t * q / m := div_pos (mul_pos ht hq) hm
    have hlog := mul_le_mul_of_nonneg_right (Real.log_le_sub_one_of_pos hratio) hδ.le
    rw [Real.log_div (mul_ne_zero ht.ne' hq.ne') hm.ne',
      Real.log_mul ht.ne' hq.ne'] at hlog
    have hscale : (t * q / m) * δ = b * (t * q) := by
      dsimp [m]
      field_simp
    simp only [sub_mul, one_mul, hscale] at hlog
    have hexp : q ^ δ * Real.exp (-(b * (t * q))) ≤ K ^ 2 := by
      rw [Real.rpow_def_of_pos hq, ← Real.exp_add]
      dsimp [K]
      rw [Real.rpow_def_of_pos ht, ← Real.exp_add, pow_two, ← Real.exp_add,
        Real.exp_le_exp]
      nlinarith only [hlog, hδ]
    simp only [sobolevModeEnergy, ite_eq_right hk, heatCoefficients, norm_smul, Real.norm_eq_abs,
      abs_of_pos (Real.exp_pos _)]
    rw [Real.rpow_add hq, mul_pow, pow_two (Real.exp _), ← Real.exp_add]
    have harg :
        -(4 * Real.pi ^ 2 * modeLengthSq k * t) +
          -(4 * Real.pi ^ 2 * modeLengthSq k * t) = -(b * (t * q)) := by
      dsimp [b, q]
      ring
    rw [harg]
    calc
      q ^ s * q ^ δ * (Real.exp (-(b * (t * q))) * ‖a k‖ ^ 2) =
          (q ^ δ * Real.exp (-(b * (t * q)))) * (q ^ s * ‖a k‖ ^ 2) := by ring
      _ ≤ K ^ 2 * (q ^ s * ‖a k‖ ^ 2) :=
        mul_le_mul_of_nonneg_right hexp (by positivity)
  have hout (k : Fin 3 → ℤ) :
      0 ≤ sobolevModeEnergy (s + δ) (heatCoefficients t a) k := by
    unfold sobolevModeEnergy
    split_ifs with hk
    · exact le_rfl
    · exact mul_nonneg (Real.rpow_nonneg (heat_smoothing_modeLengthSq_pos k hk).le _)
        (sq_nonneg _)
  have hs := (ha.2.mul_left (K ^ 2)).of_nonneg_of_le hout hbound
  refine ⟨⟨?_, hs⟩, ?_⟩
  · simp [heatCoefficients, ha.1]
  have hsum := hs.tsum_le_tsum hbound (ha.2.mul_left (K ^ 2))
  rw [tsum_mul_left] at hsum
  change Real.sqrt (∑' k, sobolevModeEnergy (s + δ) (heatCoefficients t a) k) ≤
    K * Real.sqrt (∑' k, sobolevModeEnergy s a k)
  have hroot := Real.sqrt_le_sqrt hsum
  rwa [Real.sqrt_mul (sq_nonneg K), Real.sqrt_sq hK] at hroot

end NavierStokesTao
