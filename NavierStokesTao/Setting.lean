import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2

namespace NavierStokesTao

open scoped BigOperators ContDiff

/-- Real coordinates on the covering space of the unit three-torus. (Paper: eq. (1)) -/
abbrev Position := Fin 3 → ℝ

/-- The Euclidean value space of a velocity field. (Paper: eq. (1)) -/
abbrev Velocity := EuclideanSpace ℝ (Fin 3)

/-- A lifted torus field is invariant under every integer translation. (Paper: eq. (1)) -/
def LatticePeriodic {E : Type*} (f : Position → E) : Prop :=
  ∀ (m : Fin 3 → ℤ) (x : Position), f (x + fun i ↦ (m i : ℝ)) = f x

/-- The spatial partial derivative obtained from Mathlib's Fréchet derivative.
(Paper: eq. (1)) -/
noncomputable def spatialPartial {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (i : Fin 3) (f : Position → E) (x : Position) : E :=
  fderiv ℝ f x (Pi.single i 1)

/-- The sum of the diagonal spatial derivatives of a velocity field. (Paper: eq. (1)) -/
noncomputable def spatialDivergence (v : Position → Velocity) (x : Position) : ℝ :=
  ∑ i, spatialPartial i v x i

/-- The componentwise sum of the second spatial derivatives. (Paper: eq. (1)) -/
noncomputable def spatialLaplacian (v : Position → Velocity) (x : Position) : Velocity :=
  ∑ i, spatialPartial i (spatialPartial i v) x

/-- The vector of spatial partial derivatives of pressure. (Paper: eq. (1)) -/
noncomputable def pressureGradient (p : Position → ℝ) (x : Position) : Velocity :=
  WithLp.toLp 2 (fun i ↦ spatialPartial i p x)

/-- A smooth velocity-pressure pair solving (1) with smooth, divergence-free initial data.
The conjectures use a closed interval or ray as `times`. Joint smoothness is expressed by
`ContDiffOn`, and `derivWithin` uses the time derivative from within the interval at endpoints.
(Paper: eq. (1)) -/
structure SmoothSolution (times : Set ℝ) (u₀ : Position → Velocity)
    (u : ℝ → Position → Velocity) (p : ℝ → Position → ℝ) : Prop where
  initialSmooth : ContDiff ℝ ∞ u₀
  initialPeriodic : LatticePeriodic u₀
  initialDivergenceFree : ∀ x, spatialDivergence u₀ x = 0
  velocitySmooth : ContDiffOn ℝ ∞ (fun z : ℝ × Position ↦ u z.1 z.2) (times ×ˢ Set.univ)
  pressureSmooth : ContDiffOn ℝ ∞ (fun z : ℝ × Position ↦ p z.1 z.2) (times ×ˢ Set.univ)
  velocityPeriodic : ∀ t ∈ times, LatticePeriodic (u t)
  pressurePeriodic : ∀ t ∈ times, LatticePeriodic (p t)
  momentum : ∀ t ∈ times, ∀ x,
    derivWithin (fun s ↦ u s x) times t + fderiv ℝ (u t) x ((u t x).ofLp) =
      spatialLaplacian (u t) x - pressureGradient (p t) x
  incompressible : ∀ t ∈ times, ∀ x, spatialDivergence (u t) x = 0
  initial : u 0 = u₀

end NavierStokesTao
