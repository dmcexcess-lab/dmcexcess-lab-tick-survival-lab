# Tick Survival Lab — Repository SOP

Status: **repository execution procedure**

This file owns mechanics of working the repo. It is not project memory and must not compete with the active context stack.

For reasoning/decision behavior use `AI_OPERATING_MODEL.md`. For game identity use `PROJECT_NORTH_STAR.md`; settled ownership `ARCHITECTURE.md`; phase order `ROADMAP.md`; exact active state `CURRENT.md`.

Newest explicit user direction overrides older repository text.

## 1. Continuation bootstrap

For active Tick Lab work:

1. read the compatibility pointer `README_CONTEXT.md` if the harness requires it;
2. read this SOP once;
3. fetch current `main` once;
4. load/compile the active context stack: `AI_OPERATING_MODEL.md`, `PROJECT_NORTH_STAR.md`, `ARCHITECTURE.md`, `ROADMAP.md`, `CURRENT.md`;
5. continue directly from `CURRENT.md -> NEXT` unless the newest user instruction explicitly changes it;
6. inspect only the exact current source/API/evidence required for that operation.

Do not broadly rediscover architecture, reconstruct history or search old commits for confidence. Historical archaeology is allowed only when a concrete current contradiction/failure cannot be resolved from active context/current source.

## 2. Direct-to-main authorization

Direct `main` is the normal workflow. The user permanently approved direct-to-main publication on 2026-09-05. Do not ask again unless the user explicitly changes this.

## 3. Operation scope

One operation is one coherent vertical outcome with one definition of done. The user approves/chooses slices; the AI chooses internal engineering steps and executes through closure.

Do not reopen closed systems without a concrete active-play defect. Prefer existing authoritative owners and ordinary production player surfaces over parallel state/replacement systems.

Major genuinely new player-visible systems or meaningful design rewrites use **DESCRIBE -> APPROVE -> IMPLEMENT -> VERIFY**. Existing approved-system wiring, repairs and ordinary engineering do not need repeated approval ceremony.

## 4. No fake completion

No placeholder/demo/UI-only substitute may be presented as finished gameplay truth. DEV fixtures are allowed only for focused verification and may not become production state.

## 5. Prompt-local disposable gameplay verification

For every **code-changing** prompt:

1. delete the previous code prompt's prompt-owned smoke/test script and workflow;
2. create a fresh smoke/test script + workflow scoped only to this operation;
3. assert only the touched module/play path;
4. do not invoke historical broad gameplay suites, architecture gates, seed matrices or neighbor-module smokes merely for confidence;
5. repair failures from the exact current job evidence;
6. keep the verifier through documentation/current-state closure;
7. the next code prompt deletes it.

A focused verifier may boot the production scene when needed to prove the real path. Toolchain preparation is not permission for unrelated regressions.

Documentation-only context/process changes do not require a gameplay verifier because they alter no production behavior.

## 6. Pages

`.github/workflows/pages.yml` is deployment only, never gameplay CI. It may do only the toolchain/export work needed for the web artifact.

For production/code changes, exact-head Pages success is part of publication closure. Documentation-only changes that cannot affect the artifact do not require a redundant deployment gate unless Pages is actually triggered or the user requests it.

## 7. Failure handling

Do not call a code operation complete until its fresh verifier reaches terminal success and concrete failures have been repaired from actual evidence. Pending CI is not completion.

Do not invent tool/token/time/platform blockers. A blocker exists only when a current tool/platform response proves the required remaining operation cannot continue.

## 8. Documentation roles

### Active context

- `AI_OPERATING_MODEL.md` — how the AI reasons/decides/executes;
- `PROJECT_NORTH_STAR.md` — what game is being made;
- `ARCHITECTURE.md` — settled owners/invariants; where not to reinvent;
- `ROADMAP.md` — finite phase order/definitions of done;
- `CURRENT.md` — tiny current working state and NEXT.

### Reference / cold storage

- `PERFORMANCE_NORTH_STAR.md` — load when performance is materially relevant;
- `DESIGN_DECISIONS.md` — settled cross-system decision record/reference;
- `SYSTEM_DESIGNS/*` — subsystem detail when the active slice enters that subsystem;
- changelogs/Git history — implementation history/evidence;
- `README_CONTEXT.md` — compatibility pointer only; no longer project working memory.

Do not duplicate current state/history into active files unnecessarily.

## 9. Final write rule

For future repository operations, `CURRENT.md` is the **final repository write** before the user-facing response.

It records only:

- current phase/slice;
- completed/closed facts materially relevant to continuation;
- exact unfinished outcome and definition of done;
- boundaries/protected behavior;
- current prompt-local verifier pair when applicable;
- `NEXT` from the established roadmap/newest explicit user decision.

Do not turn `CURRENT.md` into a changelog. Commit hashes/run IDs belong in Git/changelogs unless one is essential to continuation.

After the final `CURRENT.md` write: zero repository writes; only read-only exact-head verification. If an unexpected failure is discovered after final write, report it and make repair the next operation.

**Migration exception:** the 2026-09-26 context-stack migration began under the old SOP requiring `README_CONTEXT.md` to be final. That one operation closes with a final compatibility-pointer write; subsequent operations use `CURRENT.md` as final.

## 10. Anti-thrashing

Once necessary context is known, execute. Preparation is not progress.

Do not reread the same docs/source/log repeatedly, rediscover settled tool schemas, perform speculative branches, or substitute progress commentary for available implementation work.

Reason deeply where something is genuinely novel/uncertain. For settled project architecture and mature engineering practice: retrieve pattern -> execute -> verify.

## 11. Platform/performance baseline

Phone/Safari is first-class. Relevant input/lifecycle changes account for touch/mouse de-duplication, focus loss/backgrounding and hard pause.

Turn-based systems do not wake because a render frame occurred. Avoid whole-world scans and accidental per-entity Nodes/timers/process loops when bounded/cached/coarse alternatives preserve truth.

Historical recovery references remain available in Git if a concrete recovery need arises; they are not normal continuation context.
