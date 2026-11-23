import NavierStokesTao.Conjectures

namespace NavierStokesTao

/-- The qualitative global regularity conjecture and the two quantitative bound conjectures
are equivalent. (Paper: Theorem 1.4) -/
theorem regularityEquivalence :
    (globalRegularity ↔ longTermBound) ∧ (globalRegularity ↔ shortTermBound) := by
  sorry

end NavierStokesTao
