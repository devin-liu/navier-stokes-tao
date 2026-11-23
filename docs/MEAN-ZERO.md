# Mean-zero reduction

Tao uses conservation of the spatial mean and a Galilean change of coordinates at the
start of Section 2, then works with mean-zero solutions throughout Section 3. Here the
torus has volume one, and the H¹ norm is the inhomogeneous norm in the paper map.

## Conservation of the mean

Write `m(t) = ∫Ω u(t,x) dx`. Smoothness and compactness allow differentiation under
the integral. The integrals of `Δu` and `∇p` vanish by periodicity. Incompressibility
gives `(u · ∇)u = ∑ᵢ ∂ᵢ(uᵢu)`, so its integral also vanishes. In each case the
integral of a coordinate derivative cancels at the two opposite faces of the unit cube.
Thus `m(t) = m(0) = m` on the solution interval.

## Transformation of the solution

Let `x` be the old coordinate and `y = x − tm) the moving coordinate. In that frame
the fields and initial datum are

```text
v(t,y) = u(t,y + tm) − m
q(t,y) = p(t,y + tm)
v₀(y)  = u₀(y) − m.
```

The source at the start of Section 2 displays a shift of the argument by `−tm`.
The formulas above distinguish the old-to-new coordinate map from evaluation at its
inverse and make the subtraction of the frame velocity explicit. A spatial translation
alone preserves the spatial mean.

Composition with this affine coordinate change preserves smoothness, and the spatial
translations preserve periodicity. The time derivative of `v` is
`∂ₜu + (m · ∇)u`, evaluated at `(t,y+tm)`. This chain rule also holds for the
one-sided endpoint derivatives. The transport term there is `((u−m) · ∇)u`, so
their sum is the original momentum left-hand side. The spatial Laplacian, pressure
gradient, and divergence commute with translation, and spatial derivatives of the
subtracted constant vanish. The transformed fields therefore satisfy (1). The
translated spatial integral of a periodic field is unchanged, giving
`∫Ω v(t,y) dy = m(t) − m = 0`. The inverse change uses frame velocity `−m`.

## Consequences for the conjectures

Translation preserves the integrals of squared velocity and squared derivatives.
The cross term between `v(t)` and the constant `m` in the squared velocity integral
vanishes because `v(t)` has mean zero. Hence at every time, including zero,

```text
‖u(t)‖²_H¹ = ‖v(t)‖²_H¹ + |m|².
```

- **Conjecture 1.1.** Subtract the datum's mean, solve globally for the centered datum,
  and apply the inverse transformation to obtain a global solution for the original datum.
- **Conjectures 1.2 and 1.3.** Given any smooth solution on the required interval, center
  it in the moving frame. If the mean-zero bound is `F₀`, set
  `F(r) = √(F₀(r)² + r²)`, which is nondecreasing. The identity at time zero bounds both
  `‖v₀‖_H¹` and `|m|` by `‖u₀‖_H¹`. The identity at the final time then gives the
  required bound with `F`. The same argument uses `G₀` and `G` for times at most one.

The restrictions from general to mean-zero data follow directly.
