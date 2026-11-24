import NavierStokesTao.Sobolev
import NavierStokesTao.TorusIntegral

namespace NavierStokesTao

open MeasureTheory
open scoped ContDiff

/-- The average velocity on the unit-volume torus, computed on the unit cube.
(Paper: Section 2, mean-zero reduction) -/
noncomputable def spatialMean (v : Position → Velocity) : Velocity :=
  ∫ x in Set.Icc (0 : Position) 1, v x

/-- Velocity in coordinates moving with constant velocity `c`. With new coordinate
`x = x_old - t • c`, the formula evaluates the old field at `x + t • c` and subtracts
`c` from its velocity. (Paper: Section 2, mean-zero reduction) -/
def galileanVelocity (c : Velocity) (u : ℝ → Position → Velocity)
    (t : ℝ) (x : Position) : Velocity :=
  u t (x + t • c.ofLp) - c

/-- Pressure in coordinates moving with constant velocity `c`.
(Paper: Section 2, mean-zero reduction) -/
def galileanPressure (c : Velocity) (p : ℝ → Position → ℝ) (t : ℝ) (x : Position) : ℝ :=
  p t (x + t • c.ofLp)

/-- The integral of a continuous periodic lift over the unit cube is invariant under
translation. This is the translation invariance of the torus integral in Cartesian
coordinates. (Paper: none) -/
theorem setIntegral_unitCube_translate {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [CompleteSpace E] (f : Position → E) (hSmooth : Continuous f)
    (hPeriodic : LatticePeriodic f) (a : Position) :
    (∫ x in Set.Icc (0 : Position) 1, f (x + a)) = ∫ x in Set.Icc (0 : Position) 1, f x := by
  obtain ⟨F, hF⟩ := latticePeriodic_factors_torus f hPeriodic
  have torusPoint_add (x : Position) : torusPoint (x + a) = torusPoint x + torusPoint a := by
    funext i
    exact AddCircle.coe_add (1 : ℝ) (x i) (a i)
  calc
    (∫ x in Set.Icc (0 : Position) 1, f (x + a)) =
        ∫ x in Set.Icc (0 : Position) 1, F (torusPoint x + torusPoint a) := by
      simp only [← torusPoint_add, hF]
    _ = ∫ z, F (z + torusPoint a) :=
      setIntegral_torusPoint (fun z ↦ F (z + torusPoint a))
    _ = ∫ z, F z := integral_add_right_eq_self F (torusPoint a)
    _ = ∫ x in Set.Icc (0 : Position) 1, f x := by
      simpa only [hF] using (setIntegral_torusPoint F).symm

/-- At time zero the boost subtracts its constant velocity from the initial field.
(Paper: Section 2, mean-zero reduction) -/
theorem galileanVelocity_initial (c : Velocity) (u : ℝ → Position → Velocity) :
    galileanVelocity c u 0 = fun x ↦ u 0 x - c := by
  funext x
  simp [galileanVelocity]

/-- Changing back to the original frame restores the original velocity field.
(Paper: Section 2, mean-zero reduction) -/
theorem galileanVelocity_inverse (c : Velocity) (u : ℝ → Position → Velocity) :
    galileanVelocity (-c) (galileanVelocity c u) = u := by
  funext t x
  have shift : x + t • (-c).ofLp + t • c.ofLp = x := by
    rw [WithLp.ofLp_neg, smul_neg, ← sub_eq_add_neg, sub_add_cancel]
  simp only [galileanVelocity, shift, sub_neg_eq_add, sub_add_cancel]

/-- A smooth solution has constant spatial mean on a convex time domain containing zero.
The time-domain hypotheses apply to the positive-length intervals and forward ray of Section 1.
(Paper: Section 2, mean-zero reduction) -/
theorem spatialMean_conserved {times : Set ℝ} (hConvex : Convex ℝ times) (hZero : 0 ∈ times)
    (hDiff : UniqueDiffOn ℝ times) {u₀ : Position → Velocity}
    {u : ℝ → Position → Velocity} {p : ℝ → Position → ℝ}
    (h : SmoothSolution times u₀ u p) {t : ℝ} (ht : t ∈ times) :
    spatialMean (u t) = spatialMean u₀ := by
  sorry

/-- Equation (1) is invariant under a change to coordinates moving with constant velocity.
Unique time derivatives include the one-sided derivatives in the conjectures' time domains.
(Paper: Section 2, mean-zero reduction) -/
theorem smoothSolution_galilean {times : Set ℝ} (hDiff : UniqueDiffOn ℝ times)
    {u₀ : Position → Velocity} {u : ℝ → Position → Velocity} {p : ℝ → Position → ℝ}
    (h : SmoothSolution times u₀ u p) (c : Velocity) :
    SmoothSolution times (fun x ↦ u₀ x - c) (galileanVelocity c u) (galileanPressure c p) := by
  sorry

/-- Spatial translation preserves the mean, and the boost subtracts its constant velocity.
(Paper: Section 2, mean-zero reduction) -/
theorem spatialMean_galileanVelocity (c : Velocity) (u : ℝ → Position → Velocity) (t : ℝ)
    (hSmooth : ContDiff ℝ ∞ (u t)) (hPeriodic : LatticePeriodic (u t)) :
    spatialMean (galileanVelocity c u t) = spatialMean (u t) - c := by
  let cube := Set.Icc (0 : Position) 1
  have continuousShift : Continuous (fun x : Position ↦ u t (x + t • c.ofLp)) :=
    hSmooth.continuous.comp (continuous_id.add continuous_const)
  have integrableShift : IntegrableOn (fun x : Position ↦ u t (x + t • c.ofLp)) cube :=
    continuousShift.integrableOn_Icc
  have integrableConst : IntegrableOn (fun _ : Position ↦ c) cube :=
    continuous_const.integrableOn_Icc
  unfold spatialMean galileanVelocity
  rw [integral_sub integrableShift integrableConst,
    setIntegral_unitCube_translate (u t) hSmooth.continuous hPeriodic, setIntegral_const]
  simp [cube, Measure.real, Real.volume_Icc_pi]

/-- A boost by the current spatial mean removes precisely the constant-mode contribution
to the squared inhomogeneous H¹ norm. For solutions the mean is constant in time.
This is the norm identity used in the reduction with the chosen H¹ normalization.
(Paper: Section 2, mean-zero reduction) -/
theorem h1Norm_sq_galilean_centered (u : ℝ → Position → Velocity) (t : ℝ)
    (hSmooth : ContDiff ℝ ∞ (u t)) (hPeriodic : LatticePeriodic (u t)) :
    (h1Norm (u t) : ℝ) ^ 2 =
      (h1Norm (galileanVelocity (spatialMean (u t)) u t) : ℝ) ^ 2 + ‖spatialMean (u t)‖ ^ 2 := by
  let v := u t
  let c := spatialMean v
  let a : Position := t • c.ofLp
  let cube := Set.Icc (0 : Position) 1
  let d (x : Position) : ℝ := ∑ i : Fin 3, ‖spatialPartial i v x‖ ^ 2
  let f (x : Position) : ℝ := ‖v x‖ ^ 2 + d x
  let g (x : Position) : ℝ := ‖v x - c‖ ^ 2 + d x
  have hdiff : Continuous (fderiv ℝ v) :=
    hSmooth.continuous_fderiv (by simp)
  have hd : Continuous d := by
    unfold d
    exact continuous_finsetSum _ (fun i _ ↦ ((hdiff.clm_apply continuous_const).norm).pow 2)
  have hf : Continuous f := (hSmooth.continuous.norm.pow 2).add hd
  have hg : Continuous g := ((hSmooth.continuous.sub continuous_const).norm.pow 2).add hd
  have hgper : LatticePeriodic g := by
    intro m x
    let b : Position := fun i ↦ (m i : ℝ)
    have heq : (fun y ↦ v (y + b)) = v := funext (hPeriodic m)
    have hsp (i : Fin 3) : spatialPartial i v (x + b) = spatialPartial i v x := by
      unfold spatialPartial
      rw [← fderiv_comp_add_right (f := v) (x := x) b, heq]
    change g (x + b) = g x
    have hv : v (x + b) = v x := hPeriodic m x
    simp only [g, d, hv, hsp]
  have htranslate (x : Position) : galileanVelocity c u t x = v (x + a) - c := rfl
  have hpartial (i : Fin 3) (x : Position) :
      spatialPartial i (galileanVelocity c u t) x = spatialPartial i v (x + a) := by
    change fderiv ℝ (fun y ↦ v (y + a) - c) x (Pi.single i 1) =
      fderiv ℝ v (x + a) (Pi.single i 1)
    rw [fderiv_sub_const, fderiv_comp_add_right]
  change (Real.sqrt (∫ x in cube, f x)) ^ 2 =
    (h1Norm (galileanVelocity c u t) : ℝ) ^ 2 + ‖c‖ ^ 2
  have hgal : (h1Norm (galileanVelocity c u t) : ℝ) =
      Real.sqrt (∫ x in cube, g x) := by
    change Real.sqrt (∫ x in cube, ‖galileanVelocity c u t x‖ ^ 2 +
      ∑ i : Fin 3, ‖spatialPartial i (galileanVelocity c u t) x‖ ^ 2) = _
    simp only [htranslate, hpartial, ← show ∀ x, ‖v x - c‖ ^ 2 +
      ∑ i : Fin 3, ‖spatialPartial i v x‖ ^ 2 = g x from fun _ ↦ rfl]
    rw [setIntegral_unitCube_translate g hg hgper a]
  have hfn : 0 ≤ ∫ x in cube, f x :=
    integral_nonneg (fun x ↦ add_nonneg (sq_nonneg _)
      (Finset.sum_nonneg (fun _ _ ↦ sq_nonneg _)))
  have hgn : 0 ≤ ∫ x in cube, g x :=
    integral_nonneg (fun x ↦ add_nonneg (sq_nonneg _)
      (Finset.sum_nonneg (fun _ _ ↦ sq_nonneg _)))
  rw [hgal, Real.sq_sqrt hfn, Real.sq_sqrt hgn]
  let ell : Velocity →L[ℝ] ℝ := innerSL ℝ c
  have hvint : IntegrableOn v cube :=
    hSmooth.continuous.continuousOn.integrableOn_compact isCompact_Icc
  have hfint : IntegrableOn f cube := hf.continuousOn.integrableOn_compact isCompact_Icc
  have hellint : IntegrableOn (fun x ↦ ell (v x)) cube :=
    (ell.continuous.comp hSmooth.continuous).continuousOn.integrableOn_compact isCompact_Icc
  have hconst : IntegrableOn (fun _ : Position ↦ ‖c‖ ^ 2) cube :=
    continuous_const.continuousOn.integrableOn_compact isCompact_Icc
  have hexpand (x : Position) : g x = f x - 2 * ell (v x) + ‖c‖ ^ 2 := by
    dsimp [g, f, ell]
    rw [norm_sub_sq_real, real_inner_comm c (v x)]
    ring
  have hcross : (∫ x in cube, ell (v x)) = ‖c‖ ^ 2 := by
    rw [ell.integral_comp_comm hvint]
    exact real_inner_self_eq_norm_sq c
  have hunit : (∫ _ in cube, ‖c‖ ^ 2) = ‖c‖ ^ 2 := by
    simp [cube, setIntegral_const, Measure.real, Real.volume_Icc_pi]
  simp_rw [hexpand]
  have hadd :
      (∫ x in cube, f x - 2 * ell (v x) + ‖c‖ ^ 2) =
        (∫ x in cube, f x - 2 * ell (v x)) + ∫ _ in cube, ‖c‖ ^ 2 :=
    integral_add (hfint.sub (hellint.const_mul 2)) hconst
  rw [hadd, integral_sub hfint (hellint.const_mul 2), integral_const_mul, hcross, hunit]
  ring

end NavierStokesTao
