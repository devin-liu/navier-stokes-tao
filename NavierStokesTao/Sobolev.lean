import NavierStokesTao.Setting
import Mathlib.Analysis.Real.Sqrt
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

end NavierStokesTao
