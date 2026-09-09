# GPT / Repository SOP — Tick Survival Lab

Status: **canonical development process**.

Newest explicit user direction overrides older process text. This file owns repository-working procedure; `README_CONTEXT.md` owns the current exact handoff.

## 1. Continuation-first execution

For an active/recent coding continuation:

1. read `README_CONTEXT.md` once;
2. fetch current `main` once;
3. if the checkpoint matches, continue directly from `NEXT OPERATION`;
4. inspect only exact source/API or concrete failing evidence needed for that operation.

Do not broadly rediscover architecture, reread unrelated design docs, retrace ownership, reconstruct history, or repeat searches already settled in context.

A targeted extra read is justified only by a concrete compiler/import error, a focused verifier failure, an unexpected head mismatch, a blocking contradiction in context, or one exact API needed for the edit that was never established.

A broader refresh is allowed only for genuinely new work with no usable handoff or when the requested change enters a system whose current contract is absent from context.

## 2. Direct-to-main standing authorization

Direct `main` is the normal Tick Lab workflow unless the user explicitly requests otherwise.

The user permanently approved direct-to-main publication on 2026-09-05 and asked not to be asked again. Commit/push implementation, focused repairs, documentation closure, and Pages deployment without requesting another approval.

## 3. Scope: one coherent operation

**User direction, 2026-09-09:** work in small, bounded pieces toward completion, balance, bug fixing and UI/UX. Complete and publish one piece through focused verification and handoff, then ask for approval before starting the next piece so the user can inspect usage. This is a continuation gate between pieces, not a new approval requirement for already-authorized commits/pushes within a piece.

One code prompt normally touches one subsystem or one tightly coupled wiring/refactor operation. Small seam edits needed to connect the requested play path are allowed; unrelated neighbor rewrites are not.

Prefer wiring existing authoritative systems to ordinary production player surfaces over inventing parallel state or replacement systems. Search/inspect the known owner before creating a new owner.

Do not reopen already-closed systems unless a concrete defect in the active play path requires it.

## 4. Design and ownership discipline

Major new systems or meaningful rewrites use:

> **DESCRIBE -> APPROVE -> IMPLEMENT -> VERIFY**

Existing approved-system wiring, repairs, and bounded content/profile additions do not need ceremony that recreates settled design work.

Core ownership rules:

- Main/root is composition and dependency wiring only.
- WHERE owns spatial geometry/language.
- WHAT owns authoritative persistent world entities/current physical truth.
- WHEN owns deterministic time/action scheduling.
- System 00D owns global planning/coherence.
- System 20 owns local physical generation.
- System 19 owns building interiors/grammar.
- System 00F owns logical materialization/technical activation, not morphology.
- Rendering owns presentation, never gameplay truth or physics.
- Input emits intent; simulation owns consequences.
- UI owns no gameplay truth.

Technical streaming/chunk boundaries never become logical geography or persistent identity. Generation creates virgin truth once; afterward WHAT and typed mechanic stores own current reality.

## 5. No fake completion

Do not add placeholders and present them as finished systems. Do not create fake persistence, fake physics, fake world infrastructure, fake utility state, fake AI, fake outbreak results, or presentation-only substitutes for missing canonical truth.

Clearly labeled DEV fixtures are allowed only for focused verification and may not silently become production gameplay state.

## 6. Prompt-local disposable verification — NO STANDING GAMEPLAY GATES

**Permanent user direction, 2026-09-07:** gameplay CI is prompt-local and disposable. There are no standing broad gameplay gates.

For every code prompt:

1. **Delete the previous code prompt's prompt-owned smoke/test script and workflow.**
2. **Create a brand-new smoke/test script and brand-new workflow for this prompt.**
3. The fresh verifier may assert **only the exact module/play path being touched in this prompt**.
4. Do not invoke, chain, or treat any pre-existing historical smoke/test/workflow as a current gate.
5. Do not run unrelated protected-regression suites, architecture gates, whole-project gameplay suites, seed matrices, rendering/world/vehicle/UI suites, or neighbor-module smokes merely for confidence.
6. If the fresh verifier fails, inspect that exact workflow/job log and repair only the touched module or the focused verifier/toolchain setup named by the evidence.
7. Keep the prompt-local verifier through documentation/context closure so the exact active path continues to verify on those pushes.
8. The next code prompt deletes it and creates its own new module-local pair.

Historical smoke/test source may remain only when it has independent documentary/recovery value, but it is not a gate and must not be executed as part of normal prompt closure. The prior fleet of standing gameplay Actions workflows was retired on 2026-09-07.

### What counts as a focused verifier

A focused verifier may boot the production scene when that is required to prove the actual user-facing path, but its assertions must remain restricted to the active module. Toolchain setup needed to load Godot (for example creating the project class cache before invoking a script) is preparation, not permission to run unrelated regressions.

### Generation exception

Even when the touched module is generation, test only the exact generation behavior being changed. Do not revive the old twelve-seed matrix as a routine gate. Use a specific seed or the smallest contrasting cases required by that exact change; broader matrices are explicit one-off diagnostics only when the user requests or the concrete defect genuinely requires them.

## 7. Pages is deployment, not gameplay CI

`.github/workflows/pages.yml` exists only to build/export and deploy the live game.

Pages may perform the minimum Godot/toolchain work required to produce the web artifact. It must not contain gameplay smokes, architecture assertions, protected-regression suites, source-boundary gates, historical tests, or general correctness matrices.

A Pages failure is a deployment/build problem. Inspect and repair only the deployment evidence needed to restore the live build; do not use Pages as a back door for gameplay gates.

At the end of a completed repository prompt, verify exact-head Pages deployment success because the live build is part of publication closure—not because Pages is a gameplay test suite.

## 8. Verification and failure handling

Do not call a coding operation complete until:

- the fresh prompt-local verifier has reached terminal **success** on its owning functional head;
- any concrete failure was repaired from its actual job log rather than guessed around;
- relevant documentation is updated;
- `README_CONTEXT.md` has been written last;
- after that final context write, exact final head and publication state are verified read-only.

Pending CI/Pages is not completion. Continue checking required current-prompt workflow/Pages runs to terminal state.

Do not claim a blocker based on speculative model/tool/time/token limits. A blocker exists only when a concrete current tool/platform response makes the required remaining operation impossible.

## 9. Documentation discipline

Canonical documents have separate jobs:

- `PROJECT_NORTH_STAR.md` — game/experience identity;
- `PERFORMANCE_NORTH_STAR.md` — computational bargain;
- `DESIGN_DECISIONS.md` — settled cross-system decisions;
- `ROADMAP.md` — major phase order;
- `README_CONTEXT.md` — exact current handoff and next operation;
- `SYSTEM_DESIGNS/<system>.md` — current subsystem contract;
- `README_SOPS.md` — repository working process;
- changelog/history documents — implementation history.

Update only documentation materially affected by the current operation. Do not create duplicate process authorities.

## 10. `README_CONTEXT.md` is always the FINAL repository write

Every coding/repository-change prompt must update `README_CONTEXT.md` before the final user-facing response, even when the requested implementation is incomplete.

The prompt-close context must record at minimum:

- exact current checkpoint;
- functional/executable owning head when different from final documentation head;
- what this prompt completed;
- fresh prompt-local verifier script/workflow and its successful owning head/run;
- Pages status known at close;
- any new user decision/superseded behavior;
- exact unfinished work and `NEXT OPERATION`;
- protected neighboring behavior that must not be reopened;
- the explicit instruction for the next code prompt to delete this prompt's verifier pair and create a new pair for its module.

**After the `README_CONTEXT.md` commit/push, perform zero repository writes.** Everything afterward is read-only verification. If something unexpectedly fails after the final context write, inspect/report it without mutating the repository; the repair becomes the next operation unless the final write has not yet occurred.

## 11. Exact prompt-close read-only verification

After the final context write:

1. confirm branch `main` equals the final context commit SHA;
2. confirm the final head has zero failed, cancelled, queued, or in-progress Actions;
3. confirm the current prompt-local workflow succeeded on its owning functional head and, when it triggered on the final docs head, that final-head run is also successful;
4. inspect combined statuses/checks relevant to the exact head when available;
5. confirm exact-head `Build and deploy Tick Survival Lab` / `.github/workflows/pages.yml` completed successfully;
6. do not run historical gameplay tests or add repair commits after this point.

## 12. Anti-thrashing / usage discipline

Once the necessary context is known, execute. Preparation is not progress.

Do not reread the same SOP/source/workflow/log repeatedly, rediscover tool schemas already available, perform speculative branches, issue redundant searches, or poll unrelated workflows. Focused required CI polling is necessary verification.

Progress updates should communicate concrete findings or completed changes, not substitute for a write/fix operation that is available.

## 13. Performance and platform rules

Phone/Safari is first-class. Relevant input/lifecycle changes must account for touch/mouse de-duplication, keyboard availability, focus loss, and real-life pause behavior.

For new systems/meaningful rewrites, consider recurring cost per frame, simulation action/tick, active entity, and streamed-region activation. Avoid whole-world scans and accidental per-entity Nodes/timers/process loops when bounded/cached/coarse alternatives preserve truth.

Turn-based systems must not wake merely because a render frame occurred. Performance representation/scheduling may change; causal persistent world truth may not be silently removed.

## 14. Game identity / anti-drift

Primary shorthand:

> **Sprite-based zombie survival game.**

Core rule:

> **Mini means reduced complexity, not reduced consequence or mood.**

Performance rule:

> **The low-resolution 2D presentation and turn-based simulation are deliberate performance advantages. Spend that budget on simulation depth, persistence, world scale and responsiveness—not avoidable work.**

Do not use third-party franchise comparisons as canonical architecture or design-rule names.

## 15. Recovery

Historical code is archaeology, not active architecture. Recover it only when the current task genuinely requires it.

Known recovery references:

- mature visual/system archaeology commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`;
- golden `TacticalTiles.gd` blob: `3d8a0a70ac983408bb48f58fc659dfb07e216ed3`.

Normal continuation work must not reopen historical code merely to regain confidence.
