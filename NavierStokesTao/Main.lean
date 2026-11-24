import NavierStokesTao.Implications

namespace NavierStokesTao

/-- The qualitative global regularity conjecture and the two quantitative bound conjectures
are equivalent. (Paper: Theorem 1.4) -/
theorem regularityEquivalence :
    (globalRegularity ↔ longTermBound) ∧ (globalRegularity ↔ shortTermBound) := by
  exact ⟨⟨shortTermBound_implies_longTermBound ∘ globalRegularity_implies_shortTermBound,
      longTermBound_implies_globalRegularity⟩,
    ⟨globalRegularity_implies_shortTermBound,
      longTermBound_implies_globalRegularity ∘ shortTermBound_implies_longTermBound⟩⟩

end NavierStokesTao
