import NavierStokesTao.PeriodicCalculus
import Mathlib.Analysis.InnerProductSpace.Calculus
import NavierStokesTao.Heat
import Mathlib.Analysis.Calculus.ContDiff.Comp
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.Topology.Order.ProjIcc
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

namespace NavierStokesTao

open MeasureTheory
open scoped BigOperators ContDiff InnerProductSpace

/-- Modewise Duhamel formula for the heat equation with prescribed forcing.
(Paper: Lemma 2.1) -/
noncomputable def forcedHeatCoefficients {E : Type*} [NormedAddCommGroup E]
    [NormedSpace ℝ E] (a : (Fin 3 → ℤ) → E) (F : ℝ → (Fin 3 → ℤ) → E)
    (t : ℝ) (k : Fin 3 → ℤ) : E :=
  heatCoefficients t a k + ∫ r in (0 : ℝ)..t, heatCoefficients (t - r) (F r) k

/-- The forced heat flow is continuous in order s and square integrable in time in
order s+1. Its bound is uniform over finite time intervals, including T = 0.
Mean zero is built into the data predicates. The coefficient space is generalized
to a complete real normed space for the modewise integral. (Paper: Lemma 2.1) -/
theorem forced_heat_energy_estimate {E : Type*} [NormedAddCommGroup E]
    [NormedSpace ℝ E] [CompleteSpace E] (s : ℝ) :
    ∃ C : ℝ, 0 < C ∧ ∀ (T : ℝ), 0 ≤ T →
      ∀ (F : ℝ → (Fin 3 → ℤ) → E) (a : (Fin 3 → ℤ) → E),
        SobolevTimeL2 (s - 1) T F → MeanZeroSobolev s a →
        InXT s T (forcedHeatCoefficients a F) ∧
          xTNorm s T (forcedHeatCoefficients a F) ≤
            C * (meanZeroSobolevNorm s a + sobolevTimeL2Norm (s - 1) T F) := sorry

/-- A jointly continuous scalar family with jointly continuous time derivatives can be
differentiated under a compact set integral, including from within the time interval at
its endpoints. (Paper: none) -/
theorem hasDerivWithinAt_setIntegral_Icc {X : Type*} [TopologicalSpace X]
    [MeasurableSpace X] [BorelSpace X] [T2Space X] [SecondCountableTopology X]
    {μ : Measure X} [IsLocallyFiniteMeasure μ] {K : Set X} (hK : IsCompact K)
    {a b t : ℝ} (hab : a ≤ b) (ht : t ∈ Set.Icc a b) {f d : ℝ → X → ℝ}
    (hf : ContinuousOn f.uncurry (Set.Icc a b ×ˢ Set.univ))
    (hd : ContinuousOn d.uncurry (Set.Icc a b ×ˢ Set.univ))
    (hderiv : ∀ r ∈ Set.Icc a b, ∀ x : X,
      HasDerivWithinAt (f · x) (d r x) (Set.Icc a b) r) :
    HasDerivWithinAt (fun r ↦ ∫ x in K, f r x ∂μ)
      (∫ x in K, d t x ∂μ) (Set.Icc a b) t := by
  let times := Set.Icc a b
  let extend (r : ℝ) := (Set.projIcc a b hab r : ℝ)
  let D (r : ℝ) (x : X) := d (extend r) x
  have he (r : ℝ) (hr : r ∈ times) : extend r = r :=
    congrArg Subtype.val (Set.projIcc_of_mem hab hr)
  have hc : Continuous (Function.uncurry D) := by
    have hec : Continuous extend :=
      continuous_subtype_val.comp (continuous_projIcc (a := a) (b := b) (h := hab))
    exact hd.comp_continuous ((hec.comp continuous_fst).prodMk continuous_snd)
      (fun z ↦ ⟨(Set.projIcc a b hab z.1).property, Set.mem_univ _⟩)
  let G (r : ℝ) := ∫ x in K, D r x ∂μ
  have hG : Continuous G := continuous_parametric_integral_of_continuous hc hK
  have ha : a ∈ times := ⟨le_rfl, hab⟩
  have hval (r : ℝ) (hr : r ∈ times) : IntegrableOn (f r) K μ :=
    (hf.comp_continuous (continuous_const.prodMk continuous_id)
      (fun _ ↦ ⟨hr, Set.mem_univ _⟩)).continuousOn.integrableOn_compact hK
  have hident (r : ℝ) (hr : r ∈ times) :
      (∫ s in a..r, G s) = (∫ x in K, f r x ∂μ) - ∫ x in K, f a x ∂μ := by
    have hseg : Set.uIcc a r ⊆ times := by
      rw [← segment_eq_uIcc]
      exact (convex_Icc a b).segment_subset ha hr
    have hFTC (x : X) : (∫ s in a..r, D s x) = f r x - f a x := by
      apply intervalIntegral.integral_eq_sub_of_hasDeriv_right
      · exact hf.comp (continuous_id.prodMk continuous_const).continuousOn
          (fun _ hs ↦ ⟨hseg hs, Set.mem_univ _⟩)
      · intro s hs
        have hst := hseg (Set.mem_Icc_of_Ioo hs)
        rw [show D s x = d s x from congrArg (d · x) (he s hst)]
        exact ((hderiv s hst x).hasDerivAt
          (Filter.mem_of_superset (Ioo_mem_nhds hs.1 hs.2)
            (Set.Ioo_subset_Icc_self.trans hseg))).hasDerivWithinAt
      · exact (hc.comp (continuous_id.prodMk continuous_const)).intervalIntegrable _ _
    have hint : Integrable (Function.uncurry D)
        ((volume.restrict (Set.uIoc a r)).prod (μ.restrict K)) := by
      rw [Measure.prod_restrict]
      exact (hc.continuousOn.integrableOn_compact
        (isCompact_uIcc.prod hK)).mono_set
          (Set.prod_mono Set.uIoc_subset_uIcc (Set.Subset.rfl))
    have hswap : (∫ s in a..r, G s) = ∫ x in K, (∫ s in a..r, D s x) ∂μ := by
      simp only [G, intervalIntegral.intervalIntegral_eq_integral_uIoc, integral_smul,
        integral_integral_swap hint]
    rw [hswap]
    simp_rw [hFTC]
    exact integral_sub (hval r hr) (hval a ha)
  have hprim := intervalIntegral.integral_hasDerivAt_right (hG.intervalIntegrable a t)
    hG.aestronglyMeasurable.stronglyMeasurableAtFilter hG.continuousAt
  have hgt : G t = ∫ x in K, d t x ∂μ := by
    simp only [G, D, he t ht]
  rw [← hgt]
  apply (hprim.hasDerivWithinAt.add_const (∫ x in K, f a x ∂μ)).congr_of_mem _ ht
  intro r hr
  rw [hident r hr, sub_add_cancel]

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
      (Set.Icc 0 T) t := by
  let times := Set.Icc (0 : ℝ) T
  let cube := Set.Icc (0 : Position) 1
  let U (z : ℝ × Position) := u z.1 z.2
  let F (r : ℝ) (x : Position) := ‖u r x‖ ^ 2
  let d (r : ℝ) (x : Position) := derivWithin (fun s ↦ u s x) times r
  let D (r : ℝ) (x : Position) := 2 * ⟪u r x, d r x⟫_ℝ
  have hDiff := uniqueDiffOn_Icc hT
  have hUD : UniqueDiffOn ℝ (times ×ˢ (Set.univ : Set Position)) :=
    hDiff.prod uniqueDiffOn_univ
  have hd (r : ℝ) (hr : r ∈ times) (x : Position) :
      HasDerivWithinAt (fun s ↦ u s x)
        (fderivWithin ℝ U (times ×ˢ Set.univ) (r, x) (1, 0)) times r := by
    have hu' := (hu.differentiableOn (by simp) (x := (r, x))
      (show (r, x) ∈ times ×ˢ Set.univ from ⟨hr, Set.mem_univ _⟩)).hasFDerivWithinAt
    have hi : HasDerivAt (fun s : ℝ ↦ (s, x)) ((1 : ℝ), (0 : Position)) r := by
      simpa using ((hasFDerivAt_id (𝕜 := ℝ) r).prodMk
        (hasFDerivAt_const (𝕜 := ℝ) x r)).hasDerivAt
    have hm : Set.MapsTo (fun s : ℝ ↦ (s, x)) times (times ×ˢ Set.univ) :=
      fun _ hs ↦ ⟨hs, Set.mem_univ _⟩
    exact hu'.comp_hasDerivWithinAt r hi.hasDerivWithinAt hm
  have hD (r : ℝ) (hr : r ∈ times) (x : Position) :
      HasDerivWithinAt (F · x) (D r x) times r := by
    simpa only [F, D, d, (hd r hr x).derivWithin (hDiff r hr)] using (hd r hr x).norm_sq
  have hdc : ContinuousOn (Function.uncurry d) (times ×ˢ Set.univ) := by
    have hc := (hu.continuousOn_fderivWithin hUD (by simp)).clm_apply
      continuousOn_const (g := fun _ ↦ ((1 : ℝ), (0 : Position)))
    exact hc.congr fun z hz ↦ (hd z.1 hz.1 z.2).derivWithin (hDiff z.1 hz.1)
  have hDc : ContinuousOn (Function.uncurry D) (times ×ˢ Set.univ) :=
    continuousOn_const.mul (hu.continuousOn.inner hdc)
  have hFc : ContinuousOn (Function.uncurry F) (times ×ˢ Set.univ) :=
    hu.continuousOn.norm.pow 2
  exact hasDerivWithinAt_setIntegral_Icc isCompact_Icc hT.le ht hFc hDc hD

private theorem kineticEnergy_partial_smooth_periodic {E : Type*}
    [NormedAddCommGroup E] [NormedSpace ℝ E] {f : Position → E}
    (hf : ContDiff ℝ ∞ f) (hp : LatticePeriodic f) (i : Fin 3) :
    ContDiff ℝ ∞ (spatialPartial i f) ∧ LatticePeriodic (spatialPartial i f) := by
  constructor
  · exact (hf.fderiv_right (by simp)).clm_apply contDiff_const
  · intro m x
    unfold spatialPartial
    rw [← fderiv_comp_add_right]
    rw [show (fun y : Position ↦ f (y + fun j ↦ (m j : ℝ))) = f from funext (hp m)]

/-- Pair the spatial terms of the momentum equation with a smooth periodic divergence-free
velocity. The advection and pressure integrals vanish, leaving the viscous dissipation.
(Paper: none) -/
theorem kineticEnergy_spatialBalance (v : Position → Velocity) (q : Position → ℝ)
    (hv : ContDiff ℝ ∞ v) (hq : ContDiff ℝ ∞ q)
    (hvper : LatticePeriodic v) (hqper : LatticePeriodic q)
    (hdiv : ∀ x, spatialDivergence v x = 0) :
    (∫ x in Set.Icc (0 : Position) 1, 2 * ⟪v x,
      spatialLaplacian v x - pressureGradient q x - fderiv ℝ v x (v x).ofLp⟫_ℝ) =
      -2 * ∫ x in Set.Icc (0 : Position) 1, ∑ i : Fin 3, ‖spatialPartial i v x‖ ^ 2 := by
  let e (x : Position) : ℝ := (1 / 2) * ⟪v x, v x⟫_ℝ
  let c (i : Fin 3) : Velocity →L[ℝ] ℝ := PiLp.proj 2 (fun _ : Fin 3 ↦ ℝ) i
  let flux (i : Fin 3) (x : Position) : ℝ :=
    ⟪v x, spatialPartial i v x⟫_ℝ - (q x + e x) * c i (v x)
  have hv1 (i) := (kineticEnergy_partial_smooth_periodic hv hvper i).1
  have he : ContDiff ℝ ∞ e := contDiff_const.mul (hv.inner ℝ hv)
  have hc (i) : ContDiff ℝ ∞ (fun x ↦ c i (v x)) := (c i).contDiff.comp hv
  have hf (i) : ContDiff ℝ ∞ (flux i) :=
    (hv.inner ℝ (hv1 i)).sub ((hq.add he).mul (hc i))
  have hper (i) : LatticePeriodic (flux i) := by
    intro m x
    simp only [flux, e, hvper m x, hqper m x,
      (kineticEnergy_partial_smooth_periodic hv hvper i).2 m x]
  have hflux := integral_periodic_divergence_eq_zero flux (fun i ↦ (hf i).of_le (by simp)) hper
  have hdiff (i : Fin 3) (x : Position) :
      spatialPartial i (flux i) x =
        ‖spatialPartial i v x‖ ^ 2 + ⟪v x, spatialPartial i (spatialPartial i v) x⟫_ℝ -
          ((spatialPartial i q x + ⟪v x, spatialPartial i v x⟫_ℝ) * v x i +
            (q x + e x) * spatialPartial i v x i) := by
    have dv := (hv.differentiable (by simp) x).hasFDerivAt
    have dq := (hq.differentiable (by simp) x).hasFDerivAt
    have dv1 := ((hv1 i).differentiable (by simp) x).hasFDerivAt
    have dc := (c i).hasFDerivAt.comp x dv
    have de := (dv.inner ℝ dv).const_mul (1 / 2 : ℝ)
    have dflux := (dv.inner ℝ dv1).sub ((dq.add de).mul dc)
    change fderiv ℝ (flux i) x (Pi.single i 1) = _
    have hd : HasFDerivAt (flux i) _ x := dflux
    rw [hd.fderiv]
    simp only [sub_apply, add_apply,
      smul_apply, ContinuousLinearMap.comp_apply,
      ContinuousLinearMap.prod_apply, fderivInnerCLM_apply, smul_eq_mul,
      spatialPartial, real_inner_self_eq_norm_sq]
    rw [real_inner_comm ((fderiv ℝ v x) (Pi.single i 1)) (v x)]
    simp only [Pi.add_apply, Function.comp_apply, e, c, PiLp.proj_apply,
      real_inner_self_eq_norm_sq]
    ring
  have hsum (x : Position) :
      (∑ i, spatialPartial i (flux i) x) =
        (∑ i, ‖spatialPartial i v x‖ ^ 2) +
          ⟪v x, spatialLaplacian v x - pressureGradient q x -
            fderiv ℝ v x (v x).ofLp⟫_ℝ := by
    have hvec : (∑ i : Fin 3, (v x i) • Pi.single i (1 : ℝ)) = (v x).ofLp := by
      ext i
      simp [Pi.single_apply]
    have hadv : (∑ i, ⟪v x, spatialPartial i v x⟫_ℝ * v x i) =
        ⟪v x, fderiv ℝ v x (v x).ofLp⟫_ℝ := by
      conv_rhs => rw [← hvec, map_sum, inner_sum]
      simp [spatialPartial, inner_smul_right, mul_comm]
    have hpress : (∑ i, spatialPartial i q x * v x i) =
        ⟪v x, pressureGradient q x⟫_ℝ := by
      rw [EuclideanSpace.inner_eq_star_dotProduct]
      simp [pressureGradient, dotProduct]
    have hz : (∑ i, spatialPartial i v x i) = 0 := hdiv x
    simp only [hdiff, Finset.sum_sub_distrib, Finset.sum_add_distrib, add_mul,
      ← Finset.mul_sum, hz, mul_zero, add_zero, hpress, hadv,
      ← inner_sum, spatialLaplacian, inner_sub_right]
    ring
  let A (x : Position) := ∑ i, ‖spatialPartial i v x‖ ^ 2
  let B (x : Position) := ⟪v x, spatialLaplacian v x - pressureGradient q x -
    fderiv ℝ v x (v x).ofLp⟫_ℝ
  have hA : Continuous A := continuous_finsetSum _ (fun i _ ↦ (hv1 i).continuous.norm.pow 2)
  have hF : Continuous (fun x ↦ ∑ i, spatialPartial i (flux i) x) :=
    continuous_finsetSum _ (fun i _ ↦
      ((hf i).continuous_fderiv (by simp)).clm_apply continuous_const)
  have hB : Continuous B := by
    convert hF.sub hA using 1
    funext x
    exact (eq_sub_of_add_eq' (hsum x).symm)
  change (∫ x in Set.Icc (0 : Position) 1, 2 * B x) =
    -2 * ∫ x in Set.Icc (0 : Position) 1, A x
  rw [integral_const_mul]
  simp_rw [hsum] at hflux
  rw [integral_add hA.integrableOn_Icc hB.integrableOn_Icc] at hflux
  linarith

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
      (Set.Icc 0 T) t := by
  have hslice : ContDiff ℝ ∞ (fun x : Position ↦ (t, x)) :=
    contDiff_const.prodMk contDiff_id
  have hv : ContDiff ℝ ∞ (u t) :=
    ContDiffOn.comp_contDiff (f := fun x : Position ↦ (t, x)) hu.velocitySmooth hslice
      (fun _ ↦ ⟨ht, Set.mem_univ _⟩)
  have hp : ContDiff ℝ ∞ (p t) :=
    ContDiffOn.comp_contDiff (f := fun x : Position ↦ (t, x)) hu.pressureSmooth hslice
      (fun _ ↦ ⟨ht, Set.mem_univ _⟩)
  have htime (x : Position) :
      derivWithin (fun s ↦ u s x) (Set.Icc 0 T) t =
        spatialLaplacian (u t) x - pressureGradient (p t) x -
          fderiv ℝ (u t) x (u t x).ofLp :=
    eq_sub_iff_add_eq.mpr (hu.momentum t ht x)
  have h := kineticEnergy_hasDerivWithinAt hT hu.velocitySmooth t ht
  simp only [htime] at h
  rw [kineticEnergy_spatialBalance (u t) (p t) hv hp
    (hu.velocityPeriodic t ht) (hu.pressurePeriodic t ht) (hu.incompressible t ht)] at h
  exact h

/-- On any positive initial subinterval, some interior time has squared gradient
energy at most the initial kinetic energy divided by twice the subinterval length.
This is the averaging step before Poincaré, and allows arbitrary spatial mean.
(Paper: Section 3.2, before eq. (7)) -/
theorem exists_small_gradient_energy {T L : ℝ} {u₀ : Position → Velocity}
    {u : ℝ → Position → Velocity} {p : ℝ → Position → ℝ}
    (hL : 0 < L) (hLT : L ≤ T) (hu : SmoothSolution (Set.Icc 0 T) u₀ u p) :
    ∃ t ∈ Set.Ioo 0 L,
      (∫ x in Set.Icc (0 : Position) 1, ∑ i : Fin 3, ‖spatialPartial i (u t) x‖ ^ 2) ≤
        (∫ x in Set.Icc (0 : Position) 1, ‖u₀ x‖ ^ 2) / (2 * L) := by
  let e (r : ℝ) : ℝ := ∫ x in Set.Icc (0 : Position) 1, ‖u r x‖ ^ 2
  let g (r : ℝ) : ℝ :=
    ∫ x in Set.Icc (0 : Position) 1, ∑ i : Fin 3, ‖spatialPartial i (u r) x‖ ^ 2
  have hwithin (r : ℝ) (hr : r ∈ Set.Icc 0 T) :
      HasDerivWithinAt e (-2 * g r) (Set.Icc 0 T) r :=
    kineticEnergy_identity (hL.trans_le hLT) hu r hr
  have hcont : ContinuousOn e (Set.Icc 0 L) := by
    intro r hr
    have hrT : r ∈ Set.Icc 0 T := ⟨hr.1, hr.2.trans hLT⟩
    exact (hwithin r hrT).continuousWithinAt.mono
      (fun _ hx ↦ ⟨hx.1, hx.2.trans hLT⟩)
  have hderiv (r : ℝ) (hr : r ∈ Set.Ioo 0 L) :
      HasDerivAt e (-2 * g r) r :=
    (hwithin r ⟨hr.1.le, hr.2.le.trans hLT⟩).hasDerivAt
      (Icc_mem_nhds hr.1 (hr.2.trans_le hLT))
  have hdiff : DifferentiableOn ℝ e (Set.Ioo 0 L) :=
    fun r hr ↦ (hderiv r hr).differentiableAt.differentiableWithinAt
  obtain ⟨r, hr, hslope⟩ := exists_deriv_eq_slope e hL hcont hdiff
  rw [(hderiv r hr).deriv, sub_zero] at hslope
  have hscaled := (eq_div_iff hL.ne').mp hslope
  have hend : 0 ≤ e L := integral_nonneg (fun _ ↦ sq_nonneg _)
  refine ⟨r, hr, ?_⟩
  change g r ≤ (∫ x in Set.Icc (0 : Position) 1, ‖u₀ x‖ ^ 2) / (2 * L)
  have hstart : e 0 = ∫ x in Set.Icc (0 : Position) 1, ‖u₀ x‖ ^ 2 := by
    simp only [e, hu.initial]
  rw [← hstart, le_div_iff₀ (mul_pos (by norm_num) hL)]
  nlinarith only [hscaled, hend]

end NavierStokesTao
