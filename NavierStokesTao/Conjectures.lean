import NavierStokesTao.Sobolev

namespace NavierStokesTao

open scoped ContDiff NNReal

/-- Every smooth periodic divergence-free initial velocity has a smooth periodic solution
with pressure for all forward time. (Paper: Conjecture 1.1) -/
def globalRegularity : Prop :=
  ∀ u₀ : Position → Velocity, ContDiff ℝ ∞ u₀ → LatticePeriodic u₀ →
    (∀ x, spatialDivergence u₀ x = 0) →
    ∃ (u : ℝ → Position → Velocity) (p : ℝ → Position → ℝ),
      SmoothSolution (Set.Ici 0) u₀ u p

/-- One nondecreasing function bounds the final H¹ norm of every smooth periodic solution
in terms of its initial H¹ norm for every positive finite time. (Paper: Conjecture 1.2) -/
def longTermBound : Prop :=
  ∃ F : ℝ≥0 → ℝ≥0, Monotone F ∧
    ∀ (T : ℝ), 0 < T →
      ∀ (u₀ : Position → Velocity) (u : ℝ → Position → Velocity) (p : ℝ → Position → ℝ),
        SmoothSolution (Set.Icc 0 T) u₀ u p → h1Norm (u T) ≤ F (h1Norm u₀)

/-- One nondecreasing function bounds the final H¹ norm of every smooth periodic solution
in terms of its initial H¹ norm at all positive times at most one. (Paper: Conjecture 1.3) -/
def shortTermBound : Prop :=
  ∃ G : ℝ≥0 → ℝ≥0, Monotone G ∧
    ∀ (T : ℝ), 0 < T → T ≤ 1 →
      ∀ (u₀ : Position → Velocity) (u : ℝ → Position → Velocity) (p : ℝ → Position → ℝ),
        SmoothSolution (Set.Icc 0 T) u₀ u p → h1Norm (u T) ≤ G (h1Norm u₀)

/-- The long-term bound implies the short-term bound with the same bounding function.
(Paper: none) -/
theorem longTermBound_implies_shortTermBound : longTermBound → shortTermBound := by
  sorry

end NavierStokesTao
