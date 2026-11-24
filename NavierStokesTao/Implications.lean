import NavierStokesTao.Conjectures

namespace NavierStokesTao

/-- A uniform bound at all finite times gives global smooth solvability.
The statement uses the inhomogeneous norm and arbitrary mean in the conjectures,
so it includes the reduction to the mean-zero case. (Paper: Section 3.1) -/
theorem longTermBound_implies_globalRegularity :
    longTermBound → globalRegularity := sorry

/-- A uniform bound on intervals of length at most one gives a bound at all times.
The statement includes the mean-zero reduction used before the energy argument.
(Paper: Section 3.2) -/
theorem shortTermBound_implies_longTermBound :
    shortTermBound → longTermBound := sorry

/-- Global smooth solvability implies the uniform short-time bound.
The statement includes the mean-zero reduction used before the compactness argument.
(Paper: Section 3.4) -/
theorem globalRegularity_implies_shortTermBound :
    globalRegularity → shortTermBound := sorry

end NavierStokesTao
