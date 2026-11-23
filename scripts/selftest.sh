#!/usr/bin/env bash
# Checks the scripts against a small Lean project (tests/probe), with no Mathlib and no network.
# Run it after changing anything under scripts/. It uses its own state directory and never
# touches ledger/, runs/, NEXT.md or the real Lean files.
set -uo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp -R "$root/tests/probe" "$tmp/wt"; mkdir -p "$tmp/state/inbox"
tc=""
[ -f "$root/lean-toolchain" ] && tc=$(cat "$root/lean-toolchain")
installed=$(elan toolchain list 2>/dev/null | sed 's/ (.*//')
if [ -z "$tc" ] || ! grep -qxF "$tc" <<<"$installed"; then tc=$(head -n 1 <<<"$installed"); fi
[ -n "$tc" ] || { echo "selftest: no Lean toolchain installed (elan toolchain list is empty); skipped"; exit 2; }
echo "$tc" >"$tmp/wt/lean-toolchain"
export NST_WORKTREE="$tmp/wt" NST_STATE="$tmp/state" NST_LEAN_ROOT=Probe
F=Probe/Basic.lean; S="$root/scripts"; fails=0; out="$tmp/out"

expect() {  # expect <name> <pattern>: the last command's output must contain the pattern
  if grep -qE -- "$2" "$out"; then echo "  ok   $1"; else echo "  FAIL $1 (wanted: $2)"; sed 's/^/       | /' "$out" | tail -n 12; fails=$((fails + 1)); fi
}
refuse() { if grep -qE -- "$2" "$out"; then echo "  FAIL $1 (unwanted: $2)"; fails=$((fails + 1)); else echo "  ok   $1"; fi; }
last_run() { ls "$tmp/state/runs" | tail -n 1; }

echo "selftest with $tc"
python3 "$S/firstpass.py" $F --outline >"$out" 2>&1
expect "outline marks bare sorries" 'hard_one +<- sorry'
refuse "outline does not mark a proved theorem" 'already_done +<- sorry'

python3 "$S/lint.py" $F >"$out" 2>&1; expect "lint passes a clean file" 'lint: 1 files, 0 problems'
printf 'namespace Probe\ntheorem no_doc : True := by\n  have h : True := by sorry\n  exact h\nend Probe\n' >"$tmp/wt/Probe/Bad.lean"
python3 "$S/lint.py" Probe/Bad.lean >"$out" 2>&1
expect "lint refuses a sorry inside a proof" 'only 0 are the whole proof'
expect "lint asks for a docstring" 'no_doc has no docstring'
rm "$tmp/wt/Probe/Bad.lean"
python3 "$S/nst.py" sync --file $F >"$out" 2>&1
expect "sync registers the sorry theorems as targets" '5 new targets'
python3 "$S/nst.py" show hard_one >"$out" 2>&1; expect "target carries its paper tag" '"paper": "Lemma 3"'

python3 "$S/firstpass.py" $F --all-sorry --timeout 300 >"$out" 2>&1
expect "hypothesis closes keep_hyp" 'WIN +(\[[^]]*\] )?keep_hyp +via assumption'
expect "cheap tactic closes step_up" 'WIN +(\[[^]]*\] )?step_up'
expect "hard_one is a miss" 'miss +(\[[^]]*\] )?hard_one'
expect "a false statement is a miss" 'miss +(\[[^]]*\] )?later_broken'
run1=$(last_run)
grep -q 'hf : ' "$tmp/state/runs/$run1/FAILURES.md" && echo "  ok   failure bundle has the goal" || { echo "  FAIL failure bundle has the goal"; fails=$((fails + 1)); }

python3 "$S/gate.py" time $F >"$out" 2>&1; expect "file time recorded" '0 errors'
python3 "$S/gate.py" apply $F keep_hyp --from-run "$run1" >"$out" 2>&1
expect "gate accepts a real win" 'ACCEPTED: keep_hyp'

printf 'by\n  intro k\n  omega\n' >"$tmp/state/inbox/hard_one.c01.lean"
printf 'private theorem hard_one_aux (f : Nat → Nat) (hf : ∀ k, f (k + 1) = f k + 2)\n    (h0 : f 0 = 0) (k : Nat) : f k = 2 * k := by\n  induction k with\n  | zero => simpa using h0\n  | succ j ih => rw [hf, ih]; omega\n\n-- rv:proof\nby\n  intro k\n  exact hard_one_aux f hf h0 k\n' >"$tmp/state/inbox/hard_one.c02.lean"
printf 'by\n  intro k\n  sorry\n' >"$tmp/state/inbox/hard_one.c03.lean"
python3 "$S/firstpass.py" $F --decl hard_one --candidates inbox --route model:selftest --timeout 300 >"$out" 2>&1
expect "candidate with sorry is skipped" 'skip hard_one.c03.lean'
expect "the right candidate wins" 'WIN +(\[[^]]*\] )?hard_one +via hard_one.c02.lean'
python3 "$S/gate.py" apply $F hard_one --from-run "$(last_run)" >"$out" 2>&1
expect "gate accepts candidate with helper" 'ACCEPTED: hard_one'
printf 'by\n  exact Nat.le_trans (Nat.le_trans (Nat.le_trans (Nat.le_refl n) h) (Nat.le_refl m)) (Nat.le_succ m) -- padding\n' >"$tmp/long.lean"
python3 "$S/gate.py" apply $F step_up --proof-file "$tmp/long.lean" --route human >"$out" 2>&1
expect "gate refuses an over-long line before building" 'REJECTED before building'
printf 'def extra : Nat := 1\n\n-- nst:proof\nby omega\n' >"$tmp/helper.lean"
python3 "$S/gate.py" apply $F step_up --proof-file "$tmp/helper.lean" --route human >"$out" 2>&1
expect "gate refuses a new definition smuggled in as a helper" 'helpers must be'

cp "$tmp/wt/$F" "$tmp/before.lean"
python3 "$S/gate.py" apply $F step_up --proof-file "$tmp/state/inbox/hard_one.c01.lean" --route human >"$out" 2>&1
expect "gate rejects a wrong proof" 'REJECTED'
cmp -s "$tmp/wt/$F" "$tmp/before.lean" && echo "  ok   rejected edit is rolled back" || { echo "  FAIL rejected edit is rolled back"; fails=$((fails + 1)); }
python3 "$S/gate.py" apply $F step_up --proof-file "$tmp/state/inbox/hard_one.c03.lean" --route human >"$out" 2>&1
expect "gate refuses proof text with sorry" 'contains `sorry`'

printf 'by exact Nat.le_succ_of_le (step_up h)\n' >"$tmp/inherit.lean"
python3 "$S/gate.py" apply $F uses_earlier --proof-file "$tmp/inherit.lean" --route human >"$out" 2>&1
expect "inherited sorryAx is accepted and disclosed" 'sorryAx is inherited'

python3 "$S/gate.py" audit-axioms >"$out" 2>&1; rc=$?
expect "audit permits recorded inherited sorry" '3 accepted proofs checked, 0 failures'
[ "$rc" = 0 ] || { echo "  FAIL audit should pass (rc=$rc)"; fails=$((fails + 1)); }
targets="$tmp/state/ledger/targets.json"
cp "$targets" "$tmp/targets.json"
sed 's/"inherited_sorry": true/"inherited_sorry": false/' "$tmp/targets.json" >"$targets"
python3 "$S/gate.py" audit-axioms >"$out" 2>&1; rc=$?
expect "audit detects unrecorded inherited sorry" 'uses_earlier: unexpected axioms: sorryAx'
[ "$rc" = 1 ] || { echo "  FAIL audit should reject (rc=$rc)"; fails=$((fails + 1)); }
cp "$tmp/targets.json" "$targets"

sed 's/^namespace Probe$/import Does.Not.Exist\nnamespace Probe/' "$tmp/wt/$F" >"$tmp/wt/Probe/Broken.lean"
before=$(grep -c '"type": "try"' "$tmp/state/ledger/attempts.jsonl")
python3 "$S/firstpass.py" Probe/Broken.lean --decl step_up --timeout 300 >"$out" 2>&1; rc=$?
expect "a broken file is an environment problem" 'ENVIRONMENT PROBLEM'
after=$(grep -c '"type": "try"' "$tmp/state/ledger/attempts.jsonl")
[ "$rc" = 3 ] && [ "$before" = "$after" ] && echo "  ok   and logs nothing against the target" || { echo "  FAIL and logs nothing against the target (rc=$rc, $before -> $after)"; fails=$((fails + 1)); }
rm "$tmp/wt/Probe/Broken.lean"

python3 "$S/firstpass.py" Probe/Use.lean --all-sorry --timeout 300 >"$out" 2>&1
expect "module-system file: replayed dependency warnings are not misattributed" 'WIN +(\[[^]]*\] )?carry_over +via assumption'
printf 'by exact ⟨hidden_fact, open_fact_3⟩\n' >"$tmp/state/inbox/needs_hidden.c01.lean"
python3 "$S/firstpass.py" Probe/Use.lean --decl needs_hidden --candidates inbox --route private --timeout 300 >"$out" 2>&1
expect "scratch copy keeps import-all access" 'WIN +(\[[^]]*\] )?needs_hidden'
python3 "$S/gate.py" apply Probe/Use.lean needs_hidden --from-run "$(last_run)" >"$out" 2>&1
expect "private-route candidate passes the same gate" 'ACCEPTED: needs_hidden'
expect "and its inherited sorryAx is reported" 'sorryAx is inherited'

python3 - "$S" >"$out" 2>&1 <<'PY'
import sys; sys.path.insert(0, sys.argv[1])
import firstpass
r = [{"decl": "d", "label": "simp", "first": 10, "last": 11, "proof": "by simp", "helpers": ""}]
firstpass.classify(r, [], True, 10); print("timeout-result:", r[0]["result"])
PY
expect "a run cut off by the time limit is not a win" 'timeout-result: timeout'

python3 "$S/nst.py" turn start --agent tester-a >"$out" 2>&1; expect "turn can be taken" 'turn taken by tester-a'
python3 "$S/nst.py" turn start --agent tester-b >"$out" 2>&1; expect "second agent is refused" 'held by tester-a'
python3 "$S/nst.py" turn end --did "selftest" --next "nothing" >"$out" 2>&1; expect "turn is released" 'turn released'
grep -q '## Next action' "$tmp/state/NEXT.md" && echo "  ok   handover file written" || { echo "  FAIL handover file written"; fails=$((fails + 1)); }
python3 "$S/nst.py" check >"$out" 2>&1; expect "ledger check passes" ' 0 problems'
python3 "$S/nst.py" turn start --agent tester-a >/dev/null 2>&1
python3 "$S/nst.py" freeze level hard_one --reviewer tester-a --basis x >"$out" 2>&1; expect "the turn holder cannot review its own statement" 'must not be the agent holding the turn'
python3 "$S/nst.py" freeze level hard_one --reviewer tester-b --basis "read against the paper" >"$out" 2>&1; expect "an independent review freezes" 'frozen: hard_one'
python3 "$S/nst.py" turn end --did "selftest" --next "nothing" >/dev/null 2>&1
python3 "$S/nst.py" sync >"$out" 2>&1; expect "tree and ledger agree" 'sync: .* 0 problems'
python3 "$S/nst.py" status >"$out" 2>&1; expect "a frozen, sorry-free proof counts as verified" 'hard_one +proved-local +verified'
expect "a proof resting on sorry counts as conditional" 'uses_earlier +proved-local +conditional'
cp "$tmp/wt/$F" "$tmp/frozen.lean"
sed -i.bak 's/def level (k : Nat) : Prop := big(k)/def level (k : Nat) : Prop := big(k + 1)/' "$tmp/wt/$F"
python3 "$S/nst.py" sync >"$out" 2>&1; expect "a changed frozen definition is caught" 'level: FROZEN statement changed'
cp "$tmp/frozen.lean" "$tmp/wt/$F"
sed -i.bak 's/f k = 2 \* k := by/f k = 2 * k + 0 := by/' "$tmp/wt/$F"
python3 "$S/nst.py" sync >"$out" 2>&1; expect "a changed frozen theorem is caught" 'hard_one: FROZEN statement changed'
cp "$tmp/frozen.lean" "$tmp/wt/$F"; rm -f "$tmp/wt/$F.bak"
python3 "$S/nst.py" report >"$out" 2>&1; expect "report generated" 'REPORT.md written: 37 targets, 4 proved'
python3 "$S/nst.py" model-pass --model x --tier strong --targets hard_one --purpose t >"$out" 2>&1
expect "strong pass without a shared lemma is refused" 'needs a named intermediate lemma'

echo
[ $fails = 0 ] && echo "selftest: all passed" || { echo "selftest: $fails FAILED"; exit 1; }
