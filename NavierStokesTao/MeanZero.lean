import NavierStokesTao.Sobolev

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
  sorry

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
  sorry

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
  sorry

/-- A boost by the current spatial mean removes precisely the constant-mode contribution
to the squared inhomogeneous H¹ norm. For solutions the mean is constant in time.
This is the norm identity used in the reduction with the chosen H¹ normalization.
(Paper: Section 2, mean-zero reduction) -/
theorem h1Norm_sq_galilean_centered (u : ℝ → Position → Velocity) (t : ℝ)
    (hSmooth : ContDiff ℝ ∞ (u t)) (hPeriodic : LatticePeriodic (u t)) :
    (h1Norm (u t) : ℝ) ^ 2 =
      (h1Norm (galileanVelocity (spatialMean (u t)) u t) : ℝ) ^ 2 + ‖spatialMean (u t)‖ ^ 2 := by
  sorry

end NavierStokesTao
