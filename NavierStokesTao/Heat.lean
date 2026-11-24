import NavierStokesTao.Sobolev

namespace NavierStokesTao

/-- Heat evolution of Fourier coefficients on the unit-period torus. Its Laplacian
eigenvalue at mode `k` is `-4π² |k|²` in Mathlib's Fourier normalization.
(Paper: eq. (5)) -/
noncomputable def heatCoefficients {E : Type*} [SMul ℝ E]
    (t : ℝ) (a : (Fin 3 → ℤ) → E) (k : Fin 3 → ℤ) : E :=
  Real.exp (-(4 * Real.pi ^ 2 * modeLengthSq k * t)) • a k

/-- Positive-time heat evolution gains any positive number of Sobolev derivatives
with a constant independent of time and the input coefficients. The assertion is
stated in the complexified Fourier representation. (Paper: eq. (5)) -/
theorem heat_smoothing {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (s δ : ℝ) (hδ : 0 < δ) :
    ∃ C : ℝ, 0 < C ∧ ∀ (t : ℝ) (a : (Fin 3 → ℤ) → E),
      0 < t → MeanZeroSobolev s a →
      MeanZeroSobolev (s + δ) (heatCoefficients t a) ∧
        meanZeroSobolevNorm (s + δ) (heatCoefficients t a) ≤
          C * t ^ (-δ / 2) * meanZeroSobolevNorm s a := sorry

end NavierStokesTao
