import NavierStokesTao.Setting
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

namespace NavierStokesTao

open MeasureTheory
open scoped BigOperators NNReal

/-- The inhomogeneous H¹ norm of a smooth periodic field, given by the square root of the
integral of the squared Euclidean velocity and first derivatives over the unit cube.
The conjectures use H¹ without defining its normalization. The notation subsection defines
the homogeneous mean-zero spaces separately. (Paper: Section 1.5) -/
noncomputable def h1Norm (v : Position → Velocity) : ℝ≥0 :=
  let energy := ∫ x in Set.Icc (0 : Position) 1,
    ‖v x‖ ^ 2 + ∑ i : Fin 3, ‖spatialPartial i v x‖ ^ 2
  ⟨Real.sqrt energy, Real.sqrt_nonneg energy⟩

/-- The squared Euclidean length of an integer Fourier mode. (Paper: Section 1.5) -/
def modeLengthSq (k : Fin 3 → ℤ) : ℝ :=
  ∑ i, (k i : ℝ) ^ 2

/-- The homogeneous Sobolev weight times the squared norm of one Fourier coefficient.
The zero mode is omitted. (Paper: Section 1.5) -/
noncomputable def sobolevModeEnergy {E : Type*} [Norm E]
    (s : ℝ) (a : (Fin 3 → ℤ) → E) (k : Fin 3 → ℤ) : ℝ :=
  if k = 0 then 0 else modeLengthSq k ^ s * ‖a k‖ ^ 2

/-- The homogeneous Sobolev norm in Fourier coordinates. Use on sequences in
`MeanZeroSobolev`, where the sum converges. (Paper: Section 1.5) -/
noncomputable def meanZeroSobolevNorm {E : Type*} [Norm E]
    (s : ℝ) (a : (Fin 3 → ℤ) → E) : ℝ :=
  Real.sqrt (∑' k, sobolevModeEnergy s a k)

/-- Mean-zero Sobolev membership in Fourier coordinates, for complexified coefficients
when modeling real fields. For a real-field application the input coefficients must
also have conjugate symmetry. (Paper: Section 1.5) -/
def MeanZeroSobolev {E : Type*} [Norm E] [Zero E]
    (s : ℝ) (a : (Fin 3 → ℤ) → E) : Prop :=
  a 0 = 0 ∧ Summable (sobolevModeEnergy s a)

/-- Time-square-integrable mean-zero Sobolev data on the closed interval,
represented by coefficient functions. Require almost-everywhere Sobolev membership
and almost-everywhere strong measurability of each mode. (Paper: Section 1.5) -/
def SobolevTimeL2 {E : Type*} [Norm E] [Zero E] [TopologicalSpace E]
    (s T : ℝ) (u : ℝ → (Fin 3 → ℤ) → E) : Prop :=
  (∀ᵐ t ∂volume.restrict (Set.Icc 0 T), MeanZeroSobolev s (u t)) ∧
  (∀ k, AEStronglyMeasurable (fun t ↦ u t k) (volume.restrict (Set.Icc 0 T))) ∧
  IntegrableOn (fun t ↦ meanZeroSobolevNorm s (u t) ^ 2) (Set.Icc 0 T)

/-- Time L² norm of a curve of mean-zero Sobolev coefficients, on the domain
`SobolevTimeL2`. (Paper: Section 1.5) -/
noncomputable def sobolevTimeL2Norm {E : Type*} [Norm E]
    (s T : ℝ) (u : ℝ → (Fin 3 → ℤ) → E) : ℝ :=
  Real.sqrt (∫ t in Set.Icc 0 T, meanZeroSobolevNorm s (u t) ^ 2)

/-- Membership in X^s_T in Fourier coordinates. The curve takes values of order s at
every time and is continuous in the order-s norm. It has order s+1 in time L².
(Paper: Section 2) -/
def InXT {E : Type*} [NormedAddCommGroup E]
    (s T : ℝ) (u : ℝ → (Fin 3 → ℤ) → E) : Prop :=
  (∀ t ∈ Set.Icc 0 T, MeanZeroSobolev s (u t)) ∧
  (∀ t ∈ Set.Icc 0 T, Filter.Tendsto
    (fun r ↦ meanZeroSobolevNorm s (fun k ↦ u r k - u t k))
    (nhdsWithin t (Set.Icc 0 T)) (nhds 0)) ∧
  SobolevTimeL2 (s + 1) T u

/-- The X^s_T norm of a curve in `InXT`, adding the supremum in time at order s
and the time L² norm at order s+1. (Paper: Section 2) -/
noncomputable def xTNorm {E : Type*} [Norm E]
    (s T : ℝ) (u : ℝ → (Fin 3 → ℤ) → E) : ℝ :=
  sSup ((fun t ↦ meanZeroSobolevNorm s (u t)) '' Set.Icc 0 T) +
    sobolevTimeL2Norm (s + 1) T u

end NavierStokesTao
