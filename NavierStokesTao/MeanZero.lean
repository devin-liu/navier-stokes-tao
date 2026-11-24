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

private theorem spatialMean_partial_smooth_periodic {E : Type*}
    [NormedAddCommGroup E] [NormedSpace ℝ E] {f : Position → E}
    (hf : ContDiff ℝ ∞ f) (hp : LatticePeriodic f) (i : Fin 3) :
    ContDiff ℝ ∞ (spatialPartial i f) ∧ LatticePeriodic (spatialPartial i f) := by
  constructor
  · exact (hf.fderiv_right (by simp)).clm_apply contDiff_const
  · intro m x
    unfold spatialPartial
    rw [← fderiv_comp_add_right]
    rw [show (fun y : Position ↦ f (y + fun j ↦ (m j : ℝ))) = f from funext (hp m)]

private theorem spatialMean_integral_coordinateDerivative (f : Position → ℝ)
    (hf : ContDiff ℝ 1 f) (hp : LatticePeriodic f) (i : Fin 3) :
    (∫ x in Set.Icc (0 : Position) 1, spatialPartial i f x) = 0 := by
  let e : ℝ × (Fin 2 → ℝ) ≃ᵐ Position :=
    (MeasurableEquiv.piFinSuccAbove (fun _ : Fin 3 ↦ ℝ) i).symm
  have hem : MeasurePreserving e :=
    (volume_preserving_piFinSuccAbove (fun _ : Fin 3 ↦ ℝ) i).symm _
  have heπ : e ⁻¹' Set.Icc (0 : Position) 1 =
      Set.Icc (0 : ℝ) 1 ×ˢ Set.Icc (0 : Fin 2 → ℝ) 1 :=
    ((Fin.insertNthOrderIso (fun _ : Fin 3 ↦ ℝ) i).preimage_Icc _ _).trans
      (Set.Icc_prod_eq _ _)
  have hc : Continuous (spatialPartial i f) :=
    (hf.continuous_fderiv one_ne_zero).clm_apply continuous_const
  have hi := hc.integrableOn_Icc (μ := (volume : Measure Position)) (a := (0 : Position)) (b := 1)
  have heint :
      IntegrableOn (fun z ↦ spatialPartial i f (e z))
        (Set.Icc (0 : ℝ) 1 ×ˢ Set.Icc (0 : Fin 2 → ℝ) 1)
        ((volume : Measure ℝ).prod (volume : Measure (Fin 2 → ℝ))) := by
    rw [← Measure.volume_eq_prod, ← heπ]
    exact (hem.integrableOn_comp_preimage e.measurableEmbedding).2 hi
  have hline (y : Fin 2 → ℝ) (r : ℝ) :
      i.insertNth r y = i.insertNth (0 : ℝ) y + r • Pi.single i (1 : ℝ) := by
    let a : Position := i.insertNth r y
    let b : Position := i.insertNth (0 : ℝ) y + r • Pi.single i (1 : ℝ)
    change a = b
    apply funext
    refine i.forall_iff_succAbove.2 ⟨?_, fun k ↦ ?_⟩
    · simp [a, b]
    · simp [a, b]
  have htime (y : Fin 2 → ℝ) :
      (∫ r in Set.Icc (0 : ℝ) 1, spatialPartial i f (i.insertNth r y)) = 0 := by
    let g (r : ℝ) : Position := i.insertNth r y
    let dir : Position := Pi.single i 1
    have hgd (r : ℝ) : HasDerivAt g dir r := by
      rw [show g = fun s ↦ i.insertNth (0 : ℝ) y + s • dir from funext (hline y)]
      simpa only [id_eq, one_smul] using
        (hasDerivAt_id r).smul_const dir |>.const_add (i.insertNth (0 : ℝ) y)
    have hd (r : ℝ) : HasDerivAt (fun s ↦ f (g s)) (spatialPartial i f (g r)) r :=
      ((hf.differentiable_one (g r)).hasFDerivAt).comp_hasDerivAt r (hgd r)
    have hg : Continuous g := continuous_iff_continuousAt.2 fun r ↦ (hgd r).continuousAt
    have hci : IntervalIntegrable (fun r ↦ spatialPartial i f (g r)) volume 0 1 :=
      (hc.comp hg).intervalIntegrable 0 1
    have hends : f (g 1) = f (g 0) := by
      let shift : Fin 3 → ℤ := Pi.single i 1
      have hshift : (fun j ↦ (shift j : ℝ)) = dir := by
        ext j
        by_cases hj : j = i <;> simp [shift, dir, hj]
      simpa only [g, hline y 1, one_smul, hshift] using hp shift (i.insertNth (0 : ℝ) y)
    change (∫ r in Set.Icc (0 : ℝ) 1, spatialPartial i f (g r)) = 0
    rw [integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le zero_le_one,
      intervalIntegral.integral_eq_sub_of_hasDerivAt (fun r _ ↦ hd r) hci, hends, sub_self]
  rw [← hem.map_eq, setIntegral_map_equiv, heπ, Measure.volume_eq_prod, setIntegral_prod _ heint]
  have hprod :
      Integrable (Function.uncurry (fun r y ↦ spatialPartial i f (e (r, y))))
        ((volume.restrict (Set.Icc (0 : ℝ) 1)).prod
          (volume.restrict (Set.Icc (0 : Fin 2 → ℝ) 1))) := by
    rwa [Measure.prod_restrict]
  rw [integral_integral_swap hprod]
  change (∫ y in Set.Icc (0 : Fin 2 → ℝ) 1, ∫ r in Set.Icc (0 : ℝ) 1,
    spatialPartial i f (i.insertNth r y)) = 0
  simp only [htime, integral_zero]

private theorem spatialMean_integral_momentumRhs (v : Position → Velocity) (q : Position → ℝ)
    (hv : ContDiff ℝ ∞ v) (hq : ContDiff ℝ ∞ q)
    (hvper : LatticePeriodic v) (hqper : LatticePeriodic q)
    (hdiv : ∀ x, spatialDivergence v x = 0) :
    (∫ x in Set.Icc (0 : Position) 1, spatialLaplacian v x - pressureGradient q x -
      fderiv ℝ v x (v x).ofLp) = 0 := by
  classical
  let R (x : Position) :=
    spatialLaplacian v x - pressureGradient q x - fderiv ℝ v x (v x).ofLp
  let c (j : Fin 3) : Velocity →L[ℝ] ℝ := PiLp.proj 2 (fun _ : Fin 3 ↦ ℝ) j
  have hv1 (i) := (spatialMean_partial_smooth_periodic hv hvper i).1
  have hc (i : Fin 3) : ContDiff ℝ ∞ (fun x ↦ c i (v x)) := (c i).contDiff.comp hv
  have hR : Continuous R := by
    apply Continuous.sub
    · apply Continuous.sub
      · exact continuous_finsetSum _ fun i _ ↦
          ((hv1 i).continuous_fderiv (by simp)).clm_apply continuous_const
      · have hp : Continuous (fun x : Position ↦ fun i ↦ spatialPartial i q x) :=
          continuous_pi fun i ↦ (spatialMean_partial_smooth_periodic hq hqper i).1.continuous
        exact (PiLp.continuous_toLp 2 _).comp hp
    · exact (hv.continuous_fderiv (by simp)).clm_apply
        ((PiLp.continuous_ofLp 2 _).comp hv.continuous)
  ext j
  change c j (∫ x in Set.Icc (0 : Position) 1, R x) = 0
  rw [← (c j).integral_comp_comm hR.integrableOn_Icc]
  let flux (i : Fin 3) (x : Position) :=
    c j (spatialPartial i v x) - (if i = j then q x else 0) - c i (v x) * c j (v x)
  have hf (i) : ContDiff ℝ ∞ (flux i) := by
    refine (((c j).contDiff.comp (hv1 i)).sub ?_).sub ((hc i).mul (hc j))
    split_ifs
    · exact hq
    · exact contDiff_const
  have hper (i) : LatticePeriodic (flux i) := by
    intro m x
    simp only [flux, hvper m x, hqper m x,
      (spatialMean_partial_smooth_periodic hv hvper i).2 m x]
  have hC (i : Fin 3) : Continuous (spatialPartial i (flux i)) :=
    ((hf i).continuous_fderiv (by simp)).clm_apply continuous_const
  have hflux : (∫ x in Set.Icc (0 : Position) 1, ∑ i, spatialPartial i (flux i) x) = 0 := by
    rw [integral_finsetSum _ (fun i _ ↦ (hC i).integrableOn_Icc)]
    exact Finset.sum_eq_zero fun i _ ↦
      spatialMean_integral_coordinateDerivative (flux i) ((hf i).of_le (by simp)) (hper i) i
  have hdiff (i : Fin 3) (x : Position) : spatialPartial i (flux i) x =
      c j (spatialPartial i (spatialPartial i v) x) -
        (if i = j then spatialPartial i q x else 0) -
        (c i (spatialPartial i v x) * c j (v x) +
          c i (v x) * c j (spatialPartial i v x)) := by
    have dv := (hv.differentiable (by simp) x).hasFDerivAt
    have dv1 := ((hv1 i).differentiable (by simp) x).hasFDerivAt
    have dq : HasFDerivAt (fun y ↦ if i = j then q y else 0)
        (if i = j then fderiv ℝ q x else 0) x := by
      split_ifs
      · exact (hq.differentiable (by simp) x).hasFDerivAt
      · exact hasFDerivAt_const _ _
    have h := (((c j).hasFDerivAt.comp x dv1).sub dq).sub
      (((c i).hasFDerivAt.comp x dv).mul ((c j).hasFDerivAt.comp x dv))
    unfold spatialPartial
    have hF : HasFDerivAt (flux i) _ x := h
    rw [hF.fderiv]
    split_ifs <;> simp [mul_comm, add_comm] <;> rfl
  have hsum (x : Position) : (∑ i, spatialPartial i (flux i) x) = c j (R x) := by
    have hvec : (∑ i : Fin 3, (v x i) • Pi.single i (1 : ℝ)) = (v x).ofLp := by
      ext i
      simp [Pi.single_apply]
    have hadv : (∑ i, c i (v x) * c j (spatialPartial i v x)) =
        c j (fderiv ℝ v x (v x).ofLp) := by
      conv_rhs => rw [← hvec, map_sum, map_sum]
      simp [spatialPartial, c]
    have hz : (∑ i, c i (spatialPartial i v x)) = 0 := hdiv x
    simp only [hdiff, Finset.sum_sub_distrib, Finset.sum_add_distrib, ← Finset.sum_mul,
      hz, zero_mul, zero_add, hadv, Finset.sum_ite_eq', Finset.mem_univ, ite_true,
      R, spatialLaplacian, map_sub, map_sum]
    rfl
  simpa only [hsum] using hflux

/-- A smooth solution has constant spatial mean on a convex time domain containing zero.
The time-domain hypotheses apply to the positive-length intervals and forward ray of Section 1.
(Paper: Section 2, mean-zero reduction) -/
theorem spatialMean_conserved {times : Set ℝ} (hConvex : Convex ℝ times) (hZero : 0 ∈ times)
    (hDiff : UniqueDiffOn ℝ times) {u₀ : Position → Velocity}
    {u : ℝ → Position → Velocity} {p : ℝ → Position → ℝ}
    (h : SmoothSolution times u₀ u p) {t : ℝ} (ht : t ∈ times) :
    spatialMean (u t) = spatialMean u₀ := by
  let cube := Set.Icc (0 : Position) 1
  let U (z : ℝ × Position) := u z.1 z.2
  let d (r : ℝ) (x : Position) := derivWithin (fun s ↦ u s x) times r
  have hseg : Set.uIcc 0 t ⊆ times := by
    rw [← segment_eq_uIcc]
    exact hConvex.segment_subset hZero ht
  have hUD : UniqueDiffOn ℝ (times ×ˢ (Set.univ : Set Position)) :=
    hDiff.prod uniqueDiffOn_univ
  have hd (r : ℝ) (hr : r ∈ times) (x : Position) :
      HasDerivWithinAt (fun s ↦ u s x)
        (fderivWithin ℝ U (times ×ˢ Set.univ) (r, x) (1, 0)) times r := by
    have hu := (h.velocitySmooth.differentiableOn (by simp) (x := (r, x))
      (show (r, x) ∈ times ×ˢ Set.univ from ⟨hr, Set.mem_univ _⟩)).hasFDerivWithinAt
    have hi : HasDerivAt (fun s : ℝ ↦ (s, x)) ((1 : ℝ), (0 : Position)) r := by
      simpa using ((hasFDerivAt_id (𝕜 := ℝ) r).prodMk
        (hasFDerivAt_const (𝕜 := ℝ) x r)).hasDerivAt
    have hm : Set.MapsTo (fun s : ℝ ↦ (s, x)) times (times ×ˢ Set.univ) :=
      fun _ hs ↦ ⟨hs, Set.mem_univ _⟩
    exact hu.comp_hasDerivWithinAt r hi.hasDerivWithinAt hm
  have hd' (r : ℝ) (hr : r ∈ times) (x : Position) :
      HasDerivWithinAt (fun s ↦ u s x) (d r x) times r := by
    simpa only [d, (hd r hr x).derivWithin (hDiff r hr)] using hd r hr x
  have hdc : ContinuousOn (Function.uncurry d) (times ×ˢ Set.univ) := by
    have hc := (h.velocitySmooth.continuousOn_fderivWithin hUD (by simp)).clm_apply
      continuousOn_const (g := fun _ ↦ ((1 : ℝ), (0 : Position)))
    exact hc.congr fun z hz ↦ (hd z.1 hz.1 z.2).derivWithin (hDiff z.1 hz.1)
  have hsli (x : Position) :
      Set.MapsTo (fun r : ℝ ↦ (r, x)) (Set.uIcc 0 t) (times ×ˢ Set.univ) :=
    fun _ hr ↦ ⟨hseg hr, Set.mem_univ _⟩
  have hFTC (x : Position) : (∫ r in (0 : ℝ)..t, d r x) = u t x - u 0 x := by
    apply intervalIntegral.integral_eq_sub_of_hasDeriv_right
    · exact h.velocitySmooth.continuousOn.comp
        (continuous_id.prodMk continuous_const).continuousOn (hsli x)
    · intro r hr
      exact ((hd' r (hseg (Set.mem_Icc_of_Ioo hr)) x).hasDerivAt
        (Filter.mem_of_superset (Ioo_mem_nhds hr.1 hr.2)
          (Set.Ioo_subset_Icc_self.trans hseg))).hasDerivWithinAt
    · exact (hdc.comp (continuous_id.prodMk continuous_const).continuousOn
        (hsli x)).intervalIntegrable
  have hz (r : ℝ) (hr : r ∈ times) : (∫ x in cube, d r x) = 0 := by
    have hs : ContDiff ℝ ∞ (fun x : Position ↦ (r, x)) :=
      contDiff_const.prodMk contDiff_id
    have hu : ContDiff ℝ ∞ (u r) :=
      h.velocitySmooth.comp_contDiff hs (fun _ ↦ ⟨hr, Set.mem_univ _⟩)
    have hp : ContDiff ℝ ∞ (p r) :=
      h.pressureSmooth.comp_contDiff hs (fun _ ↦ ⟨hr, Set.mem_univ _⟩)
    simp only [d, fun x ↦ eq_sub_iff_add_eq.mpr (h.momentum r hr x)]
    exact spatialMean_integral_momentumRhs (u r) (p r) hu hp
      (h.velocityPeriodic r hr) (h.pressurePeriodic r hr) (h.incompressible r hr)
  have hint : Integrable (Function.uncurry d)
      ((volume.restrict (Set.uIoc 0 t)).prod (volume.restrict cube)) := by
    rw [Measure.prod_restrict]
    exact ((hdc.mono (Set.prod_mono hseg (Set.subset_univ _))).integrableOn_compact
      (isCompact_uIcc.prod isCompact_Icc)).mono_set
        (Set.prod_mono Set.uIoc_subset_uIcc (Set.Subset.rfl))
  have hswap : (∫ x in cube, ∫ r in (0 : ℝ)..t, d r x) = 0 := by
    simp only [intervalIntegral.intervalIntegral_eq_integral_uIoc, integral_smul,
      ← integral_integral_swap hint]
    rw [setIntegral_congr_fun measurableSet_uIoc
      (g := fun _ ↦ (0 : Velocity)) (fun r hr ↦ hz r (hseg (Set.uIoc_subset_uIcc hr)))]
    simp
  have hval (r : ℝ) (hr : r ∈ times) : IntegrableOn (u r) cube :=
    (h.velocitySmooth.continuousOn.comp_continuous
      (continuous_const.prodMk continuous_id) (fun _ ↦ ⟨hr, Set.mem_univ _⟩)).integrableOn_Icc
  simp_rw [hFTC] at hswap
  rw [integral_sub (hval t ht) (hval 0 hZero), sub_eq_zero] at hswap
  simpa only [spatialMean, ← h.initial] using hswap

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
