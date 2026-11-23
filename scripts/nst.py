#!/usr/bin/env python3
"""State, turns and drafts for the navier-stokes-tao repository. Zero model calls.

  scripts/nst status                     # start here: turn, tree, every target, what is next
  scripts/nst turn start --agent NAME    # take the turn (fails if someone else holds it)
  scripts/nst turn end --did "…" --next "…" [--needs "…"]   # hand over; rewrites NEXT.md
  scripts/nst turn steal --agent NAME --why "…"             # only when the lock is stale
  scripts/nst sync [--file F]            # compare the Lean files with the ledger; register new `sorry` theorems
  scripts/nst scout                      # which file to work on: open targets per file, lowest imports first
  scripts/nst preflight                  # read-only look at GitHub: main moved? open PRs? who is in which file?
  scripts/nst branch SLUG                # start a cycle branch from an up-to-date main
  scripts/nst set DECL [DECL …] --state S [--pr N] [--note "…"]
  scripts/nst show DECL                  # one target and its recent attempts
  scripts/nst freeze DECL [DECL …] --reviewer NAME --basis "…"   # record an independent statement review
  scripts/nst restate DECL --why "…"     # a frozen statement had to change: record it, unfreeze
  scripts/nst model-pass --model NAME --tier mid|strong --targets a,b --purpose "…" [--lemma L] [--usage-before "…"]
  scripts/nst usage "what the usage meter showed, before and after"
  scripts/nst draft pr                   # write the pull request text and command to outbox/
  scripts/nst report                     # regenerate REPORT.md from the ledgers
  scripts/nst check                      # ledger consistency
"""
from __future__ import annotations

import argparse
import datetime
import json
import os
import pathlib
import re
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import nstlib as rv  # noqa: E402

LOCK = rv.STATE / ".turn" / "lock.json"
ROUTE_NAMES = {"lean-only": "Lean-only search", "model": "after a model pass",
               "private": "undisclosed method", "human": "by hand"}
PROVED = ("proved-local", "pr-open", "merged")


def hours_since(ts: str) -> float:
    return (datetime.datetime.now().astimezone() - datetime.datetime.fromisoformat(ts)).total_seconds() / 3600


def gh(args: list[str]) -> str:
    r = subprocess.run(["gh", *args], capture_output=True, text=True, stdin=subprocess.DEVNULL)
    if r.returncode != 0:
        rv.die(f"gh {' '.join(args[:4])} …: {r.stderr.strip()[:300]}")
    return r.stdout


def git(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["git", *args], cwd=rv.worktree(), capture_output=True, text=True, stdin=subprocess.DEVNULL)


def verdict(row: dict, frozen: dict) -> str:
    """What a proved target counts as (README, "What counts as verified?")."""
    if row["state"] not in PROVED + ("external",):
        return ""
    if row["state"] == "external":
        return "external"
    if row.get("inherited_sorry"):
        return "conditional"
    return "verified" if row["decl"] in frozen else "unreviewed"


def commit_ledger(message: str, extra: tuple[str, ...] = ()) -> None:
    """Ledger changes are part of the record: commit them when on a cycle branch."""
    if rv.STATE != rv.ROOT or not (rv.ROOT / ".git").exists():
        return
    branch = git("branch", "--show-current").stdout.strip()
    if not branch or branch == rv.cfg().get("branch", "main"):
        return
    git("add", "--", "ledger", *extra)
    r = git("commit", "-m", message)
    if r.returncode != 0 and "nothing to commit" not in r.stdout:
        print(f"  NOT COMMITTED: {rv.short(r.stderr or r.stdout, 200)}")


# ---------------------------------------------------------------- turns

def lock_info() -> dict | None:
    return json.loads(LOCK.read_text()) if LOCK.exists() else None


def cmd_turn(a) -> None:
    stale_h = rv.cfg().get("turn_stale_hours", 4)
    cur = lock_info()
    if a.action == "start":
        LOCK.parent.mkdir(exist_ok=True)
        try:
            fd = os.open(LOCK, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        except FileExistsError:
            age = hours_since(cur["since"])
            rv.die(f"the turn is held by {cur['agent']} since {cur['since']} ({age:.1f}h). "
                   + (f"It is stale (over {stale_h}h): `scripts/nst turn steal --agent {a.agent} --why …` if its work is not running."
                      if age > stale_h else "Do not work in this folder now; stop and tell the operator."), 75)
        with os.fdopen(fd, "w") as f:
            json.dump({"agent": a.agent, "since": rv.now()}, f)
        print(f"turn taken by {a.agent}.\n")
        cmd_status(a)
    elif a.action == "steal":
        if not cur:
            rv.die("nobody holds the turn; use `turn start`")
        if hours_since(cur["since"]) <= stale_h:
            rv.die(f"the lock is only {hours_since(cur['since']):.1f}h old (stale after {stale_h}h); ask the operator")
        rv.append("sessions.jsonl", {"start": cur["since"], "end": rv.now(), "agent": cur["agent"], "ended": "stolen",
                                     "did": f"(no handover; turn taken over by {a.agent}: {a.why})"})
        LOCK.write_text(json.dumps({"agent": a.agent, "since": rv.now()}))
        print(f"turn taken over by {a.agent}. Run `scripts/nst sync` for half-finished edits before anything else.")
    elif a.action == "end":
        if not cur:
            rv.die("nobody holds the turn")
        rows = [r for r in rv.read_jsonl("attempts.jsonl") if r.get("ts", "") >= cur["since"]]
        row = {"start": cur["since"], "end": rv.now(), "agent": cur["agent"], "ended": "handover",
               "did": a.did, "next": a.next, "needs": a.needs or "",
               "lean_runs": sum(r.get("type") in ("compile", "apply", "time", "statement-check") for r in rows),
               "model_passes": sum(r.get("type") == "model-pass" for r in rows)}
        rv.append("sessions.jsonl", row)
        (rv.STATE / "NEXT.md").write_text(
            "# Next\n\n"
            "Written by `scripts/nst turn end`. Do not edit by hand and do not append: the next handover replaces it.\n\n"
            f"Updated {row['end']} by {row['agent']} "
            f"({row['lean_runs']} Lean runs, {row['model_passes']} model passes this turn).\n\n"
            f"## Done last turn\n\n{a.did.strip()}\n\n"
            f"## Next action\n\n{a.next.strip()}\n\n"
            f"## Waiting on the operator\n\n{(a.needs or 'Nothing.').strip()}\n", encoding="utf-8")
        LOCK.unlink()
        # The handover is part of the record: commit it with the ledgers when on a cycle branch.
        commit_ledger(f"Turn handover ({row['agent']})", ("NEXT.md",))
        print("turn released; NEXT.md rewritten.")


# ---------------------------------------------------------------- status

def cmd_status(a) -> None:
    cur = lock_info()
    print("TURN      " + (f"held by {cur['agent']} since {cur['since']} ({hours_since(cur['since']):.1f}h)" if cur else "free"))
    wt = rv.worktree()
    if (wt / ".git").exists():
        branch = git("branch", "--show-current").stdout.strip() or "(detached)"
        dirty = [d for d in git("status", "--porcelain", "--untracked-files=no").stdout.split("\n") if d.strip()]
        main = rv.cfg().get("branch", "main")
        ahead = git("rev-list", "--count", f"origin/{main}..HEAD").stdout.strip() or "?"
        print(f"TREE      {branch} @ {rv.git_sha(wt)}, {ahead} commits ahead of origin/{main} (as of the last fetch)"
              + (f", {len(dirty)} uncommitted: " + ", ".join(d.split()[-1] for d in dirty[:4]) if dirty else ", clean"))
    if not (wt / ".lake" / "packages" / "mathlib").exists() and rv.STATE == rv.ROOT:
        print("LEAN      not set up: scripts/setup.sh (a download of several GB needs the operator's go-ahead; "
              "`--reuse <checkout>` copies an existing one on this disk instead)")
    t = rv.load_targets()
    frozen = rv.load_statements()
    by: dict[str, int] = {}
    for r in t.values():
        by[r["state"]] = by.get(r["state"], 0) + 1
    print(f"TARGETS   {len(t)}: " + (", ".join(f"{k} {v}" for k, v in sorted(by.items())) or "none yet")
          + f"; {len(frozen)} statements frozen")
    att = rv.read_jsonl("attempts.jsonl")
    for d, r in sorted(t.items(), key=lambda kv: (kv[1].get("file", ""), kv[0])):
        tries = [x for x in att if rv.same_decl(x.get("decl"), d) and x.get("type") == "try"]
        print(f"  {d:<38.38} {r['state']:<12} {verdict(r, frozen) or ('frozen' if d in frozen else 'draft'):<11} "
              f"{(r.get('route') or ''):<9} tries {len(tries):<3} {r.get('paper') or ''}"
              + (f" PR #{r['pr']}" if r.get("pr") else ""))
    passes = [x for x in att if x.get("type") == "model-pass"]
    compiles = [x for x in att if x.get("type") == "compile"]
    print(f"SPEND     Lean runs {len(compiles)} ({sum(x.get('secs', 0) for x in compiles) / 60:.0f} min), "
          f"model passes {len(passes)}"
          + (" (" + ", ".join(f"{x['tier']}:{x['model']}" for x in passes[-4:]) + ")" if passes else ""))
    inbox = sorted(p.name for p in (rv.STATE / "inbox").glob("*.lean")) if (rv.STATE / "inbox").exists() else []
    checked = {x.get("label") for x in att if x.get("type") == "try"}
    new = [n for n in inbox if n not in checked]
    if new:
        print(f"INBOX     {len(new)} candidate(s) not checked yet: " + ", ".join(new[:6]))
    nxt = rv.STATE / "NEXT.md"
    if nxt.exists():
        body = nxt.read_text(encoding="utf-8").split("## Done last turn", 1)[-1]
        print("NEXT.md   ## Done last turn" + body.rstrip())


def cmd_show(a) -> None:
    t = rv.load_targets().get(a.decl) or rv.die(f"{a.decl} is not a target")
    print(json.dumps(t, indent=1, ensure_ascii=False))
    fz = rv.load_statements().get(a.decl)
    print("frozen: " + (json.dumps(fz, ensure_ascii=False) if fz else "no (draft statement)"))
    for r in [x for x in rv.read_jsonl("attempts.jsonl") if x.get("decl") == a.decl][-a.n:]:
        print(f"  {r['ts'][5:16]} {r.get('type'):<7} {r.get('route', ''):<12} {r.get('label', '') or r.get('to', ''):<22.22} "
              f"{r.get('result', ''):<7} {rv.short(str(r.get('detail') or r.get('note') or ''), 110)}")


# ---------------------------------------------------------------- the tree against the ledger

def cmd_sync(a) -> None:
    """Two views of the same thing: what the Lean files say and what the ledger says."""
    wt = rv.worktree()
    t = rv.load_targets()
    frozen = rv.load_statements()
    att = rv.read_jsonl("attempts.jsonl")
    files = [a.file] if a.file else rv.lean_files(wt)
    problems, added, seen = [], [], set()
    for rel in files:
        decls = rv.declarations((wt / rel).read_text(encoding="utf-8"))
        ns_open = 0
        for d in decls:
            name = d["name"]
            seen.add(name)
            fz = frozen.get(name)
            if fz and fz["hash"] != d["hash"]:
                problems.append(f"{name}: FROZEN statement changed ({fz['hash']} -> {d['hash']}). Restore it, or `scripts/nst restate {name} --why …`")
            if d["kind"] not in ("theorem", "lemma") or d["private"]:
                continue
            row = t.get(name)
            if d["sorry"]:
                ns_open += 1
                if row is None:
                    rv.set_target(name, file=rel, paper=d["paper"], state="open")
                    added.append(name)
                elif row["state"] in PROVED + ("external",):
                    problems.append(f"{name}: ledger says {row['state']}, but its proof in {rel} is `sorry`. The record is wrong.")
                elif row.get("file") != rel or row.get("paper") != d["paper"]:
                    rv.set_target(name, file=rel, paper=d["paper"], state=row["state"])
            elif row is not None and row["state"] in ("open", "stuck"):
                problems.append(f"{name}: has a proof in {rel} that no accepted `gate.py apply` explains "
                                "(interrupted gate, hand edit, or someone else's merged PR: restore it, or set `external` with a note)")
            elif row is not None and row["state"] in PROVED:
                won = [x for x in att if x.get("type") == "apply" and rv.same_decl(x.get("decl"), name) and x.get("result") == "win"]
                if won and won[-1].get("stmt_hash") and won[-1]["stmt_hash"] != d["hash"]:
                    problems.append(f"{name}: its statement changed after the gate accepted the proof "
                                    f"({won[-1]['stmt_hash']} -> {d['hash']}); it is no longer the theorem that was checked")
        if not a.quiet:
            print(f"  {rel}: {len(decls)} declarations, {ns_open} open")
    if not a.file:
        for name, row in t.items():
            if name not in seen:
                problems.append(f"{name}: in the ledger ({row['state']}) but in no Lean file (renamed or removed?)")
        for name in frozen:
            if name not in seen:
                problems.append(f"{name}: frozen, but in no Lean file")
    for p in problems:
        print("  !! " + p)
    print(f"sync: {len(files)} files, {len(added)} new targets"
          + (" (" + ", ".join(added[:8]) + ")" if added else "") + f", {len(problems)} problems")
    sys.exit(1 if problems else 0)


def cmd_scout(a) -> None:
    """Where to work: open targets per file, files low in the import order first."""
    wt = rv.worktree()
    root = rv.lean_root()
    t = rv.load_targets()
    info = {}
    for rel in rv.lean_files(wt):
        text = (wt / rel).read_text(encoding="utf-8")
        imports = [m.replace(".", "/") + ".lean" for m in re.findall(rf"^(?:public )?import (?:all )?({re.escape(root)}\.[\w.]+)", text, re.M)]
        decls = [d for d in rv.declarations(text) if d["kind"] in ("theorem", "lemma") and not d["private"]]
        info[rel] = {"imports": imports, "sorry": [d["name"] for d in decls if d["sorry"]], "n": len(decls)}

    def depth(rel: str, seen: tuple = ()) -> int:
        return 0 if rel in seen or rel not in info else 1 + max([depth(i, seen + (rel,)) for i in info[rel]["imports"]] or [-1])

    rows = sorted(info.items(), key=lambda kv: (depth(kv[0]), kv[0]))
    print(f"{'depth':>5} {'open':>4} {'stuck':>5} {'all':>4}  file   (open = `sorry` and not marked stuck)")
    for rel, d in rows:
        stuck = [n for n in d["sorry"] if t.get(n, {}).get("state") == "stuck"]
        free = [n for n in d["sorry"] if n not in stuck]
        if d["sorry"] or a.all:
            print(f"{depth(rel):>5} {len(free):>4} {len(stuck):>5} {d['n']:>4}  {rel}  " + " ".join(free[:6]))
    todo = (rv.ROOT / "docs" / "MAP.md")
    if todo.exists():
        missing = re.findall(r"^\|\s*([^|]+?)\s*\|[^|]*\|\s*—\s*\|", todo.read_text(encoding="utf-8"), re.M)
        if missing:
            print(f"docs/MAP.md: {len(missing)} paper items have no Lean declaration yet: " + "; ".join(missing[:8]))


def cmd_preflight(a) -> None:
    """GitHub moves while nobody is looking: read it before branching and before the pull request."""
    c = rv.cfg()
    repo, main = c["repo"], c.get("branch", "main")
    git("fetch", "--quiet", "origin", main)
    behind = git("rev-list", "--count", f"HEAD..origin/{main}").stdout.strip() or "?"
    ahead = git("rev-list", "--count", f"origin/{main}..HEAD").stdout.strip() or "?"
    mine = set(git("diff", "--name-only", f"origin/{main}...HEAD").stdout.split())
    me = gh(["api", "user", "--jq", ".login"]).strip()
    prs = json.loads(gh(["pr", "list", "-R", repo, "--state", "open", "--limit", "100",
                         "--json", "number,title,author,isDraft,files,headRefName"]))
    issues = json.loads(gh(["issue", "list", "-R", repo, "--state", "open", "--limit", "200", "--json", "number,title,comments"]))
    print(f"GITHUB    {repo}: this branch is {ahead} ahead, {behind} behind origin/{main}; "
          f"{len(prs)} open PRs, {len(issues)} open issues")
    overlap = []
    for p in prs:
        files = {f["path"] for f in p.get("files") or []}
        who = (p.get("author") or {}).get("login", "?")
        hit = sorted(files & mine) if who != me or p["headRefName"] != git("branch", "--show-current").stdout.strip() else []
        overlap += hit
        print(f"  PR #{p['number']} by {who}{' (draft)' if p['isDraft'] else ''}: {rv.short(p['title'], 70)}"
              + (f"   !! touches files this branch edits: {', '.join(hit)}" if hit else ""))
    others = [i for i in issues if any((cm.get("author") or {}).get("login") not in (me, None) for cm in i.get("comments") or [])]
    for i in others[:10]:
        print(f"  issue #{i['number']} has comments from other people: {rv.short(i['title'], 70)}")
    v = ("another open PR edits the same files: read `gh pr diff` before handing in" if overlap
         else "main moved: rebase the cycle branch before handing in" if behind not in ("0", "?")
         else "clear")
    print(f"VERDICT   {v}")
    rv.append("attempts.jsonl", {"ts": rv.now(), "type": "preflight", "behind": behind, "ahead": ahead,
                                 "open_prs": [p["number"] for p in prs], "overlap": sorted(set(overlap)), "verdict": v})


def cmd_branch(a) -> None:
    main = rv.cfg().get("branch", "main")
    if git("status", "--porcelain", "--untracked-files=no").stdout.strip():
        rv.die("uncommitted changes; commit or sort them out first (scripts/nst sync)")
    cur = git("branch", "--show-current").stdout.strip()
    if cur != main:
        rv.die(f"already on `{cur}`. Finish that cycle (hand-in, PR, merge) or switch to {main} yourself.")
    git("fetch", "--quiet", "origin", main)
    r = git("merge", "--ff-only", f"origin/{main}")
    if r.returncode != 0:
        rv.die(f"local {main} does not fast-forward to origin/{main}: {rv.short(r.stderr, 200)}")
    name = f"cycle/{datetime.date.today().strftime('%m%d')}-{re.sub(r'[^a-z0-9]+', '-', a.slug.lower()).strip('-')}"
    r = git("switch", "-c", name)
    print(f"on {name} from {main} @ {rv.git_sha(rv.worktree())}" if r.returncode == 0 else rv.short(r.stderr, 200))


# ---------------------------------------------------------------- targets and statements

def cmd_set(a) -> None:
    for d in a.decl:
        if d not in rv.load_targets():
            rv.die(f"{d} is not a target; targets are registered from the Lean files by `scripts/nst sync`")
        if a.state == "proved-local":
            rv.die("only `scripts/gate.py apply` sets proved-local")
        if a.state in ("stuck", "finding", "external") and not (a.note or rv.load_targets()[d].get("note")):
            rv.die(f"--state {a.state} needs --note (what was tried and where it stopped; for a finding, where the evidence is)")
        row = rv.set_target(d, state=a.state, pr=a.pr, note=a.note)
        print(f"{d}: {row['state']}" + (f" (PR #{row['pr']})" if row.get("pr") else ""))
    commit_ledger(f"Set {', '.join(a.decl)}: {a.state}")


def cmd_freeze(a) -> None:
    cur = lock_info()
    if cur and cur["agent"] == a.reviewer and not a.operator_ok:
        rv.die(f"the reviewer must not be the agent holding the turn ({cur['agent']}): a statement is frozen on an "
               "independent reading (prompts/statement-review.md). Name the reviewer, or ask the operator and add --operator-ok.")
    fz = rv.load_statements()
    for name in a.decl:
        hit = rv.find_decl(name) or rv.die(f"{name}: no such declaration in {rv.lean_root()}/")
        rel, d = hit
        if not d["paper"]:
            rv.die(f"{name}: its docstring has no `(Paper: …)` tag; a statement is frozen against a paper item (or `(Paper: none)`)")
        fz[d["name"]] = {"file": rel, "kind": d["kind"], "hash": d["hash"], "paper": d["paper"], "statement": d["statement"],
                         "reviewer": a.reviewer, "basis": a.basis, "frozen_at": rv.now()}
        rv.append("attempts.jsonl", {"ts": rv.now(), "type": "freeze", "decl": d["name"], "file": rel, "hash": d["hash"],
                                     "reviewer": a.reviewer, "basis": a.basis, "operator_ok": bool(a.operator_ok)})
        print(f"frozen: {d['name']} ({d['kind']}, {d['paper']}) hash {d['hash']}, reviewed by {a.reviewer}")
    rv.save_statements(fz)
    commit_ledger(f"Freeze {', '.join(a.decl)} (reviewed by {a.reviewer})")


def cmd_restate(a) -> None:
    fz = rv.load_statements()
    old = fz.pop(a.decl, None) or rv.die(f"{a.decl} is not frozen; a draft statement can simply be edited")
    rv.save_statements(fz)
    hit = rv.find_decl(a.decl)
    rv.append("attempts.jsonl", {"ts": rv.now(), "type": "restate", "decl": a.decl, "old_hash": old["hash"],
                                 "new_hash": hit[1]["hash"] if hit else None, "old_statement": old["statement"], "why": a.why})
    commit_ledger(f"Restate {a.decl}: {rv.short(a.why, 60)}")
    t = rv.load_targets()
    dependents = [d for d, r in t.items() if r["state"] in PROVED]
    print(f"{a.decl}: unfrozen ({old['hash']}); the old statement is kept in the ledger. It needs a new review before it is frozen again.")
    if old["kind"] not in ("theorem", "lemma") and dependents:
        print(f"  a definition changed: {len(dependents)} proved targets may now say something else. "
              "Rebuild (scripts/gate.py handin) and re-review the statements that use it.")


def cmd_model_pass(a) -> None:
    b = rv.cfg()["budget"]
    targets = [x for x in a.targets.split(",") if x]
    files = {rv.load_targets().get(x, {}).get("file") for x in targets}
    prior = [r for r in rv.read_jsonl("attempts.jsonl") if r.get("type") == "model-pass" and r.get("kind", "proof") == a.kind
             and set(r.get("targets", [])) & set(targets)]
    problems = []
    if a.tier == "strong" and (not a.lemma or len(targets) < 2):
        problems.append(f"a strong-model pass needs {b['strong_model_requires']} (--lemma, and two or more --targets)")
    if a.tier == "mid" and len([r for r in prior if r["tier"] == "mid"]) >= b["model_passes_per_batch"]:
        problems.append(f"some of these targets already had {b['model_passes_per_batch']} mid-tier {a.kind} pass(es); "
                        "the budget is one per target. A new statement, lemma or candidate from elsewhere is a new input; "
                        "the same input again is not")
    if problems and not a.operator_ok:
        rv.die("; ".join(problems) + ". Ask the operator, then repeat with --operator-ok.")
    rv.append("attempts.jsonl", {"ts": rv.now(), "type": "model-pass", "kind": a.kind, "model": a.model, "tier": a.tier,
                                 "targets": targets, "files": sorted(f for f in files if f), "purpose": a.purpose,
                                 "lemma": a.lemma, "usage_before": a.usage_before or "unmeasured",
                                 "operator_ok": bool(a.operator_ok)})
    print(f"recorded: {a.tier} {a.kind} pass with {a.model} on {len(targets)} targets"
          + ("" if a.usage_before else "; usage before the pass: unmeasured"))


def cmd_usage(a) -> None:
    rv.append("attempts.jsonl", {"ts": rv.now(), "type": "usage", "note": a.note})
    print("usage note recorded")


# ---------------------------------------------------------------- outgoing drafts

def cmd_draft(a) -> None:
    c = rv.cfg()
    repo, main = c["repo"], c.get("branch", "main")
    out = rv.STATE / "outbox"
    out.mkdir(exist_ok=True)
    t = rv.load_targets()
    frozen = rv.load_statements()
    rows = sorted((r for r in t.values() if r["state"] == "proved-local"), key=lambda r: (r.get("file", ""), r["decl"]))
    branch = git("branch", "--show-current").stdout.strip()
    changed = [f for f in git("diff", "--name-only", f"origin/{main}...HEAD", "--", rv.lean_root()).stdout.split() if f]
    stated = sorted(r["decl"] for r in t.values() if r["state"] in ("open", "stuck") and r.get("file") in changed)
    if not rows and not changed:
        rv.die(f"nothing to hand in: no `proved-local` target and no Lean change against origin/{main}")
    tree = git("rev-parse", f"HEAD:{rv.lean_root()}").stdout.strip()
    checks = [r for r in rv.read_jsonl("attempts.jsonl") if r.get("type") == "handin-check"]
    checked = bool(checks) and checks[-1]["ok"] and checks[-1].get("lean_tree") == tree
    sha = checks[-1]["sha"] if checks else ""
    stems = ", ".join(sorted({pathlib.Path(f).stem for f in changed})) or "the library"
    title = (f"Prove {len(rows)} declaration{'s' if len(rows) != 1 else ''} in {stems}" if rows
             else f"State {len(stated)} declaration{'s' if len(stated) != 1 else ''} in {stems}")
    body = [title, ""]
    if rows:
        body += ["## Proved", "", "| Declaration | Paper | Counts as | Route | `#print axioms` |", "|---|---|---|---|---|"]
        for r in rows:
            body.append(f"| `{r['decl']}` | {r.get('paper') or ''} | {verdict(r, frozen)} | {ROUTE_NAMES.get(r.get('route'), '')} | "
                        f"{', '.join(r.get('axioms') or []) or 'none'} |")
        body += ["", "`conditional`: the proof compiles and uses declarations that are still `sorry` (Lean reports `sorryAx`). "
                     "`unreviewed`: the statement has not had its independent check against the paper yet."]
    if stated:
        body += ["", "## Stated, not proved (`sorry`)", ""] + [f"- `{d}` ({t[d].get('paper') or 'no paper tag'})" for d in stated]
    body += ["", "## Checks", "",
             ("`scripts/gate.py handin` passed locally at " + sha + ": `lake build`, `scripts/lint.py`, frozen statements unchanged, ledger check."
              if checked else "No passing local hand-in check is recorded for this commit.")]
    (out / "PR.md").write_text("\n".join(body) + "\n", encoding="utf-8")
    (out / "pr.sh").write_text(
        f"git push -u origin {branch}\n"
        f'gh pr create -R {repo} --base {main} --head {branch} --title "{title}" --body-file <(tail -n +3 outbox/PR.md)\n')
    if not checked:
        print("WARNING: no passing `scripts/gate.py handin` for this commit. Run it first.")
    if branch in ("", main):
        print(f"WARNING: on `{branch}`; a pull request comes from a cycle branch (scripts/nst branch <slug>).")
    print(f"drafted outbox/PR.md and outbox/pr.sh: {len(rows)} proved, {len(stated)} stated. Nothing was sent.")
    print("Sending is an outward action (AGENTS.md, \"Outward actions\").")
    print(f"After the PR is visible: scripts/nst set {' '.join(r['decl'] for r in rows) or '<decl>'} --state pr-open --pr <number>")


# ---------------------------------------------------------------- report and check

def cmd_report(a) -> None:
    t = rv.load_targets()
    frozen = rv.load_statements()
    att = rv.read_jsonl("attempts.jsonl")
    done = [r for r in t.values() if r["state"] in PROVED]
    repo = rv.cfg()["repo"]
    lines = ["# Progress report", "",
             f"Generated {rv.now()} by `scripts/nst report` from `ledger/`. Do not edit by hand.", "",
             f"Repository: [{repo}](https://github.com/{repo}). "
             "Every proof counted here was accepted by Lean in a build of the real module; none is counted on a model's say-so.", "",
             "## Where the targets stand", "", "| State | Count |", "|---|---|"]
    for s in rv.STATES:
        n = sum(r["state"] == s for r in t.values())
        if n:
            lines.append(f"| {s} | {n} |")
    lines += [f"| **all targets taken on** | **{len(t)}** |", "",
              "Targets that were tried and not proved stay in the total.", "",
              "## What the proved ones count as", "", "| | Count |", "|---|---|"]
    for v in ("verified", "conditional", "unreviewed"):
        lines.append(f"| {v} | {sum(verdict(r, frozen) == v for r in done)} |")
    lines += ["", "`verified`: the module builds, the statement was frozen after an independent check against the paper, and the "
                  "axioms are the standard three. `conditional`: the proof compiles and depends on declarations still `sorry`. "
                  "`unreviewed`: proved, statement not yet checked against the paper.", "",
              f"Statements frozen: {len(frozen)}.", "",
              "## How the proved ones were found", "", "| Route | Proved | Merged |", "|---|---|---|"]
    for route, label in ROUTE_NAMES.items():
        mine = [r for r in done if r.get("route") == route]
        if mine:
            lines.append(f"| {label} | {len(mine)} | {sum(r['state'] == 'merged' for r in mine)} |")
    compiles = [x for x in att if x.get("type") == "compile"]
    passes = [x for x in att if x.get("type") == "model-pass"]
    usage = [f"usage before {x.get('usage_before', 'unmeasured')}" for x in passes]
    notes = [x for x in att if x.get("type") == "usage"]
    lines += ["", "## Cost", "",
              f"- Lean runs with no model call: {len(compiles)}, {sum(x.get('secs', 0) for x in compiles) / 60:.0f} minutes, "
              f"{sum(x.get('attempts', 0) for x in compiles)} proof attempts.",
              f"- Model passes: {len(passes)}"
              + (" (" + "; ".join(f"{x['tier']} {x.get('kind', 'proof')} {x['model']}: {u}" for x, u in zip(passes, usage)) + ")" if passes else "") + ".",
              *[f"- Usage read off the meter, {x['ts'][:16]}: {x['note']}" for x in notes],
              "- A usage figure of `unmeasured` means nobody read the meter; it is not zero.", "",
              "## Targets", "", "| Declaration | Paper | State | Counts as | Route | PR | Axioms |", "|---|---|---|---|---|---|---|"]
    for d, r in sorted(t.items(), key=lambda kv: (kv[1].get("file", ""), kv[0])):
        ax = ", ".join(r.get("axioms") or []) if r.get("axioms") is not None else ""
        lines.append(f"| `{d}` | {r.get('paper') or ''} | {r['state']} | {verdict(r, frozen)} | "
                     f"{ROUTE_NAMES.get(r.get('route'), '')} | {('#' + str(r['pr'])) if r.get('pr') else ''} | {ax} |")
    (rv.STATE / "REPORT.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"REPORT.md written: {len(t)} targets, {len(done)} proved, {len(passes)} model passes")


def cmd_check(a) -> None:
    problems = []
    t = rv.load_targets()
    att = rv.read_jsonl("attempts.jsonl")
    rv.read_jsonl("sessions.jsonl")
    for d, r in t.items():
        if r["state"] not in rv.STATES:
            problems.append(f"{d}: unknown state {r['state']}")
        if r["state"] in ("pr-open", "merged") and not r.get("pr"):
            problems.append(f"{d}: state {r['state']} without a PR number")
        if r["state"] in PROVED:
            if r.get("route") not in rv.ROUTES:
                problems.append(f"{d}: proved without a route")
            if not any(x.get("type") == "apply" and rv.same_decl(x.get("decl"), d) and x.get("result") == "win" for x in att):
                problems.append(f"{d}: marked proved, but the ledger has no accepted `gate.py apply` for it")
        if r["state"] in ("stuck", "finding", "external") and not r.get("note"):
            problems.append(f"{d}: {r['state']} without a note for the next person")
    for d, f in rv.load_statements().items():
        if not f.get("reviewer") or not f.get("basis"):
            problems.append(f"{d}: frozen without a reviewer or a basis")
    cur = lock_info()
    if cur and hours_since(cur["since"]) > rv.cfg().get("turn_stale_hours", 4):
        problems.append(f"turn lock held by {cur['agent']} is stale")
    for p in problems:
        print("  " + p)
    print(f"check: {len(t)} targets, {len(att)} ledger rows, {len(problems)} problems")
    sys.exit(1 if problems else 0)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("status").set_defaults(fn=cmd_status)
    p = sub.add_parser("turn"); p.add_argument("action", choices=["start", "end", "steal"])
    p.add_argument("--agent"); p.add_argument("--did"); p.add_argument("--next"); p.add_argument("--needs"); p.add_argument("--why")
    p.set_defaults(fn=cmd_turn)
    p = sub.add_parser("sync"); p.add_argument("--file"); p.add_argument("--quiet", action="store_true"); p.set_defaults(fn=cmd_sync)
    p = sub.add_parser("scout"); p.add_argument("--all", action="store_true"); p.set_defaults(fn=cmd_scout)
    sub.add_parser("preflight").set_defaults(fn=cmd_preflight)
    p = sub.add_parser("branch"); p.add_argument("slug"); p.set_defaults(fn=cmd_branch)
    p = sub.add_parser("set"); p.add_argument("decl", nargs="+"); p.add_argument("--state", choices=rv.STATES, required=True)
    p.add_argument("--pr", type=int); p.add_argument("--note"); p.set_defaults(fn=cmd_set)
    p = sub.add_parser("show"); p.add_argument("decl"); p.add_argument("-n", type=int, default=12); p.set_defaults(fn=cmd_show)
    p = sub.add_parser("freeze"); p.add_argument("decl", nargs="+"); p.add_argument("--reviewer", required=True)
    p.add_argument("--basis", required=True); p.add_argument("--operator-ok", action="store_true"); p.set_defaults(fn=cmd_freeze)
    p = sub.add_parser("restate"); p.add_argument("decl"); p.add_argument("--why", required=True); p.set_defaults(fn=cmd_restate)
    p = sub.add_parser("model-pass"); p.add_argument("--model", required=True); p.add_argument("--tier", required=True, choices=["mid", "strong"])
    p.add_argument("--kind", default="proof", choices=["proof", "statement", "review"])
    p.add_argument("--targets", required=True); p.add_argument("--purpose", required=True); p.add_argument("--lemma")
    p.add_argument("--usage-before"); p.add_argument("--operator-ok", action="store_true")
    p.set_defaults(fn=cmd_model_pass)
    p = sub.add_parser("usage"); p.add_argument("note"); p.set_defaults(fn=cmd_usage)
    p = sub.add_parser("draft"); p.add_argument("kind", choices=["pr"]); p.set_defaults(fn=cmd_draft)
    sub.add_parser("report").set_defaults(fn=cmd_report)
    sub.add_parser("check").set_defaults(fn=cmd_check)
    a = ap.parse_args()
    if a.cmd == "turn":
        need = {"start": ["agent"], "steal": ["agent", "why"], "end": ["did", "next"]}[a.action]
        missing = [n for n in need if not getattr(a, n)]
        if missing:
            rv.die(f"turn {a.action} needs " + ", ".join("--" + m for m in missing))
    a.fn(a)


if __name__ == "__main__":
    main()
