# navier-stokes-tao

An independent community project to formalize Theorem 1.4 of Terence Tao’s *A quantitative formulation of the global regularity problem for the periodic Navier–Stokes equation* in Lean 4. We follow the numbering in [arXiv:0710.1604v5](https://arxiv.org/abs/0710.1604v5).

**Starting point.** The first milestone is to state the paper’s three conjectures in Lean and prove the implication from the long-term bound to the short-term bound. Contributors can help now by reviewing the statements, identifying reusable results in Mathlib, or mapping a step of the paper’s proof to the lemmas it needs.

## What does the theorem say?

Imagine starting two periodic fluid flows with very different shapes but the same initial bound on velocity and its first spatial derivatives, measured together in the Sobolev norm $H^1$. Could *every* such flow be controlled for one unit of time by a number that depends only on that initial bound? Tao proves that answering yes is equivalent to global smooth existence for every smooth, divergence-free initial velocity.

The setting is the unforced incompressible Navier–Stokes equation on the three-dimensional unit torus $\mathbb T^3=(\mathbb R/\mathbb Z)^3$, with viscosity one. Write $u$ for velocity, $p$ for pressure, and $u_0$ for the initial velocity. They satisfy

$$
\partial_t u + (u\cdot\nabla)u = \Delta u - \nabla p,
\qquad \nabla\cdot u=0,
\qquad u(0)=u_0.
$$

| Paper | Statement |
| --- | --- |
| Conjecture 1.1 · Global regularity | Every smooth divergence-free initial velocity admits a smooth solution for all forward time. |
| Conjecture 1.2 · Long-term bound | There exists a nondecreasing function $F$ such that every smooth solution on $[0,T]$, for every finite $T>0$, satisfies $\lVert u(T)\rVert_{H^1}\le F(\lVert u_0\rVert_{H^1})$. |
| Conjecture 1.3 · Short-term bound | The same estimate holds for every $0<T\le 1$, with a single nondecreasing function $G$ for all such times and solutions. |

**Theorem 1.4 says all three statements are equivalent.** That equivalence is the project’s finish line. Each bound quantifies over solutions that already exist on the indicated interval. The existence of a solution for all time appears in Conjecture 1.1. Preserving that distinction in Lean is part of the work. [Paper, §1](https://arxiv.org/pdf/0710.1604v5)

## Where to start

| If you know… | A useful first contribution | What to submit |
| --- | --- | --- |
| Lean and Mathlib | Look for existing definitions of periodic vector fields, divergence, and the spatial $H^1$ norm on the torus. | A minimal example with imports and declaration names, plus any mismatch with the paper. |
| PDE theory | Trace how the proof passes from general initial velocities to fields of mean zero. | A short derivation showing how velocity, pressure, and the initial norm transform, with a reference to the passage in the paper. |
| The basics of Lean proofs | Once the three statements are in place, prove Conjecture 1.2 implies Conjecture 1.3. | Reuse the same bounding function and specialize the estimate to $0<T\le1$. This tests the definitions before the harder analysis begins. |
| Analysis or formalization | Read Proposition 2.2 and follow one use of it in §3. | An issue identifying the precise hypothesis used, the conclusion needed, and any existing Lean lemma that supplies it. |

Beyond the first milestone, the main analytical work is to formalize the local theory and compactness results in §2, then use them in the implications of §3. A dependency map should make clear which estimates can be developed independently and which require a common definition of solution. [Paper, §§2–3](https://arxiv.org/pdf/0710.1604v5)

## How to contribute

1. Browse the repository’s **Issues** tab for the paper item you want to work on. If it has no issue yet, open one with the item number, the proposed statement, and what would count as finishing it.
2. Leave a comment before starting a proof so others can see who is working on it. A paper-level argument, a missing hypothesis, or a link to a reusable Lean theorem can be a contribution on its own.
3. Keep a proof PR focused on one statement or a small group of lemmas needed together. Include the paper reference, the Lean declaration names, and the command used to check them. If the Lean statement differs from the paper, explain the difference and justify it.
4. If a statement seems wrong, post the smallest example or derivation that shows the issue. This is especially valuable while the project is choosing its definitions.

## What counts as verified?

A result is **verified** when its module builds with the project’s pinned Lean and Mathlib versions, its statement has been checked against the cited paper item, and its axiom report contains only the standard axioms accepted by the project. A declaration that depends on an unfinished lemma stays marked **conditional**, even if its own proof compiles. Proof PRs should include the output of `#print axioms` for the result they close.

The first setup contribution should pin Lean and Mathlib and establish a clean build in CI. The reproducible build instructions belong here once that build exists.

## References

- Terence Tao, *A quantitative formulation of the global regularity problem for the periodic Navier–Stokes equation*, **Dynamics of Partial Differential Equations** 4 (2007), 293–302. [Version used for this project](https://arxiv.org/abs/0710.1604v5)
- Tao’s account of the compactness argument and its motivation. [Author’s exposition](https://terrytao.wordpress.com/2007/10/09/a-quantitative-formulation-of-the-global-regularity-problem-for-the-periodic-navier-stokes-equation/)
- For contributors learning Lean. [Mathematics in Lean](https://leanprover-community.github.io/mathematics_in_lean/) · [Mathlib documentation](https://leanprover-community.github.io/mathlib4_docs/)
