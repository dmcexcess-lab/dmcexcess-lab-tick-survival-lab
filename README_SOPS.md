# GPT / Repository SOP — Tick Survival Lab

Status: **canonical development process**.

## 1. Continuation-first context rule

`README_CONTEXT.md` is the authoritative handoff file for ongoing repository work.

### Continuation prompts

If the user is continuing an active/recent coding task, **do not perform a broad repository refresh**. Read `README_CONTEXT.md` once, fetch current `main` once, and continue from the recorded checkpoint.

If `README_CONTEXT.md` records unfinished work, the next operation listed there is the starting point. Do not rediscover architecture, reread the North Stars, retrace source ownership, repeat searches, or reconstruct already-established history just to regain confidence.

Only perform a targeted additional read when one of these is true:

- a concrete compiler/import error names the file or symbol;
- a concrete failing test names the implicated behavior;
- current `main` differs unexpectedly from the context checkpoint;
- the recorded context is internally contradictory in a way that blocks the edit;
- an exact symbol/API needed for the next edit was never established.

When one of those exceptions applies, inspect only the smallest implicated source/test/workflow and return immediately to execution.

### New work that is not a continuation

A broader canonical refresh is allowed only when starting genuinely new work with no usable current handoff, or when the requested change explicitly crosses into a system whose current contract is not represented in `README_CONTEXT.md`.

When such a refresh is actually required, read only the relevant subset of:

1. `PROJECT_NORTH_STAR.md`;
2. `PERFORMANCE_NORTH_STAR.md`;
3. `DESIGN_DECISIONS.md` if cross-system direction is touched;
4. `README_CONTEXT.md`;
5. `ROADMAP.md` if order/scope matters;
6. this SOP;
7. `SYSTEM_DESIGNS/README.md`;
8. the active owning system design(s);
9. current `main` and directly relevant source/history.

Never repeat that refresh within the same coherent task.

Newest explicit user direction beats older repository design. Material direction changes must be written back into canonical docs in the same coherent task.

## 2. Mandatory prompt-close context update

**Every coding/repository-change prompt must update `README_CONTEXT.md` before the final user-facing response. This is mandatory even when the requested implementation is incomplete.**

The prompt-close update must record, at minimum:

- current repository/head checkpoint;
- executable head if different from a documentation-only head;
- what was completed in this prompt;
- what remains unfinished;
- exact next operation for the next continuation;
- focused test/CI/Pages status known at close;
- new user decisions or superseded behavior;
- protected neighboring behavior that must not regress;
- any concrete blocker, if one truly exists.

If the prompt is interrupted, tooling fails, or full closure is otherwise impossible, **update `README_CONTEXT.md` first with the exact partial checkpoint before ending the response whenever write tools remain available**.

Do not leave the next session dependent on chat reconstruction, memory, or archaeology when the repository can carry the handoff itself.

## 3. Do not close before the requested coding task is complete

Progress updates are not completion.

Do not voluntarily end an active code-change prompt because several minutes, several tool calls, a convenient intermediate milestone, or pending CI have elapsed. Continue through the requested implementation, focused validation, commit/push, exact-head verification, required CI/Pages completion when applicable, documentation/context close, and requested links/reporting.

### Evidence-only blocker rule

Never claim or imply that work must stop because of a supposed context window, token/context limit, usage/tool allowance, model budget, session timeout, elapsed-time limit, platform cutoff, or similar internal constraint **unless a concrete tool/system response in the current task explicitly demonstrates that the required operation cannot continue**.

Do not speculate that OpenAI, the model, the harness, or another unseen system is forcing an early close. If there is no direct evidence of a blocker, continue executing the task.

A pending check is not a blocker and is not completion. When required CI/Pages checks are still running:

- continue checking until the required checks reach terminal status;
- if a required check fails, inspect the concrete failing evidence, make the smallest principled repair, push, and verify again;
- do not close merely because checks have not finished yet;
- do not call a partially green suite complete.

A coding prompt may end before requested closure only when:

- the user explicitly cancels, pauses, or redirects the task; or
- a concrete current tool/platform error makes the remaining required operation impossible.

When a genuine blocker exists, report the exact observed error/evidence, leave the maximum tangible work completed, and write the precise remaining operations into `README_CONTEXT.md` before closing whenever repository write tools still work.

Never terminate a repair prompt with preparation-only work while required read/write tools remain available.

## 4. Game identity / anti-drift check

Primary shorthand:

> **Sprite-based zombie survival game.**

Do not use third-party game titles or franchise comparisons as canonical project identity, architecture shorthand, or design-rule names. Describe Tick Survival Lab in its own terms.

Core rule:

> **Mini means reduced complexity, not reduced consequence or mood.**

Performance rule:

> **The low-resolution 2D presentation and turn-based simulation are deliberate performance advantages. Spend that budget on simulation depth, persistence, world scale and responsiveness — not avoidable work.**

Do not optimize around superseded raid/extraction assumptions.

`ROADMAP.md` controls major-phase order but does not override the North Star, performance doctrine, or subsystem ownership rules.

## 5. Design lifecycle

Major new systems and meaningful rewrites use:

> **DESCRIBE -> APPROVE -> IMPLEMENT -> VERIFY**

Statuses:

- `DRAFT` — discussion only;
- `APPROVED` — implementation authorized;
- `IMPLEMENTED` — approved behavior exists in canonical source and required tests pass;
- `SUPERSEDED` — historical only;
- `RECOVERY SOURCE` — historical behavior/art worth mining, not current architecture.

A content/profile addition inside an established system does not automatically require a new peer system document.

## 6. Scope gate

One implementation prompt should normally target one major subsystem or one tightly coupled refactor.

If several unrelated domains are requested, establish dependency order. If the user explicitly requests a coherent cross-cutting refactor, implement the coherent task rather than arbitrarily stopping after the first piece.

Small wiring edits across public seams are allowed. Neighbor rewrites are not.

## 7. Modularity without fragmentation

The goal is replaceability, **not file count**.

A separate owner/file is justified by independent state/lifecycle, a stable reusable public contract, a materially independent reason to change, or enough cohesive complexity to improve clarity/testing.

Do not create wrappers/files merely to satisfy ceremony. Do not merge genuinely independent domains merely to reduce file count.

## 8. Core ownership rules

- Main/root is composition and wiring only.
- WHERE owns spatial language/geometry.
- WHAT owns one authoritative current persistent world.
- WHEN owns deterministic simulation time/action scheduling.
- System 00D owns global planning/coherence.
- System 20 owns local physical generation.
- System 19 owns building interiors/grammar.
- System 00F owns logical materialization orchestration and technical activation, not morphology.
- Rendering owns presentation, never physics.
- Input emits intent; simulation owns consequences.

Technical streaming/chunk boundaries never become logical geography or persistent identity.

Generation creates virgin truth once. After materialization, WHAT and typed mechanic stores own current reality.

## 9. Stable contract rule

Prefer composition, narrow public methods, validated records where identity matters, and dependency injection over reach-through into another subsystem's internal state.

When a public contract changes, state the change before editing dependents and migrate/prove consumers in the same approved change.

## 10. No fake completion

Do not add placeholders and present them as finished systems.

Do not add fake AI, fake persistence, fake outbreak results, fake utility hardware, fake terrain, fake physics, fake power, fake sound sources, or presentation tricks that conceal missing world truth.

Clearly labeled DEV fixtures/tools are allowed only when they are not silent substitutes for canonical gameplay.

## 11. Pre-implementation declaration

Before implementing an approved code change, state:

- expected files/modules changed;
- protected neighboring modules;
- public contract impact;
- future seam being preserved.

For a continuation, use the already-recorded declaration/checkpoint in `README_CONTEXT.md` unless the scope materially changed. Do not repeat source archaeology solely to restate it.

## 12. Testing / verification

**User-directed seed-test scope (2026-09-05):** do not run the twelve-seed planner or boot matrices on every change. Normal streaming CI uses reference seed 20001; the full matrix is explicit opt-in via workflow_dispatch `full_seed_matrix`. Use focused owner/protected regressions and a contrasting seed when generation changes justify it. Unrelated UI/inventory changes do not justify broad seed stress testing.

Simulation/generation systems should be testable without presentation whenever practical.

For executable changes:

- run the owning subsystem contract;
- run required protected integration regressions;
- do not claim success until the exact final executable SHA is validated;
- if required checks are pending, continue monitoring them rather than ending the prompt;
- if required checks fail, repair and re-run until required checks are green or a concrete blocker is observed.

For later documentation-only corrections:

- verify the diff is documentation-only;
- cite the already-green executable SHA;
- use lightweight consistency/status checks rather than rerunning every expensive Godot contract.

Generated-world layout/behavior still requires human play acceptance even when CI is green.

## 13. Repository workflow

Direct `main` is normal unless the user requests a PR/branch workflow or destructive recovery warrants isolation.

**Standing user authorization (2026-09-05):** DMC explicitly approved direct-to-`main` publication and requested that this approval never be asked again. For authorized Tick Lab coding work, commit/push to `main`, deploy Pages and verify closure without requesting another publication confirmation. This covers follow-up fixes and documentation closure for that work. Respect any newer explicit user restriction and actual platform access controls.

Do not accumulate temporary compatibility adapters, diagnostic scaffolds, work branches, or duplicate process documents merely for tooling convenience.

Git is canonical history. Historical source may be removed from the active tree when its recovery commit/blob remains documented.

## 14. Documentation discipline

Active canonical docs answer different questions:

- `PROJECT_NORTH_STAR.md` — what game/experience are we building?
- `PERFORMANCE_NORTH_STAR.md` — what computational bargain must every system preserve?
- `DESIGN_DECISIONS.md` — settled cross-system choices;
- `ROADMAP.md` — major gameplay phase order;
- `README_CONTEXT.md` — **current exact handoff, active work, unfinished work, next operation**;
- `SYSTEM_DESIGNS/README.md` — status/routing ledger;
- `SYSTEM_DESIGNS/<system>.md` — canonical current system contract;
- `README_SOPS.md` — how repository work is performed;
- `CHANGELOG.md` + archives — implementation history.

Do not keep two active documents that both claim authority over the same process. Continuation-process rules belong here in `README_SOPS.md`; current continuation state belongs in `README_CONTEXT.md`.

## 15. Recovery / historical code

Golden mature visual/system archaeology commit:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

Golden `TacticalTiles.gd` blob:

`3d8a0a70ac983408bb48f58fc659dfb07e216ed3`

Recover historical behavior only when the task actually requires archaeology. A normal continuation must not reopen historical code simply to regain confidence.

## 16. Main/root rule

Composition roots may construct services, inject dependencies, connect high-level signals, select initial controllers/modes, and perform minimal lifecycle bookkeeping.

They must not own rendering rules, gameplay input interpretation, world generation, collision, movement, doors, inventory, simulation timing, persistence, camera math, UI geometry, art mapping, weather/perception/sound, utilities, AI, or subsystem validation.

## 17. Clarification rule

Inspect first only when inspection is genuinely needed. Ask a targeted question only when unresolved ambiguity could materially change architecture, destructive scope, stable contracts, persistence, timing, historical target, mobile interaction, or player-visible semantics.

Do not ask about ordinary typos when intent is clear.

## 18. Mobile/browser requirement

Phone/Safari is first-class. Input/lifecycle systems must consider touch/mouse de-duplication, keyboard availability, focus loss, and the hard real-life pause requirement where relevant.

## 19. Performance-first architecture gate

For every new system or meaningful rewrite, explicitly consider recurring/asymptotic cost:

- per render frame;
- per simulation tick/action;
- per active entity;
- per streamed-region materialization/activation;
- whole-world scans;
- revision caching/batching/coalescing opportunities;
- analytic/coarse derivation opportunities;
- GPU presentation opportunities;
- accidental per-entity Node/timer/process/scheduled-event creation.

Prefer bounded work whose cost follows the smallest relevant active set. A turn-based system must not wake merely because a render frame occurred.

Performance work must remain honest: representation/scheduling may change, but causal world truth and meaningful consequences may not be silently removed.

## 20. Anti-thrashing execution guardrail

Once the necessary context for a coherent prompt is known, **execute the task**. Preparation is not progress and must not become a loop.

Default repair/continuation sequence:

1. read `README_CONTEXT.md` once;
2. fetch current `main` once;
3. if the head/checkpoint is consistent, continue directly from the recorded next operation;
4. inspect only concrete failing evidence or one truly unknown exact API needed for the edit;
5. make the principled edit;
6. commit/push;
7. verify the exact executable head and required checks, continuing to monitor pending required checks until terminal status;
8. if a required check fails, make the smallest evidence-driven repair and repeat steps 6–7;
9. update canonical docs as needed;
10. **update `README_CONTEXT.md` as the final repository write for the prompt whenever practical**;
11. report results and required links.

Operational rules:

- Do **not** reread the same SOPs, designs, source files, workflows, logs, or tool schemas repeatedly within one coherent task.
- Do **not** perform broad searches for facts already recorded in `README_CONTEXT.md` or the current conversation handoff.
- Do **not** rediscover tool schemas once the required function is already available and understood.
- Do **not** substitute status updates, plans, summaries, or diagnostic restatements for an available write/fix operation.
- A failing test/compile error permits a targeted implicated read; it does not reopen general archaeology.
- Protect the user's usage/time budget: no speculative branches, duplicate reads, redundant searches, or unnecessary polling. Polling required CI to terminal state is necessary verification, not unnecessary polling.
- Never invent or speculate about context windows, token limits, tool allowances, session endings, model budgets, platform cutoffs, or OpenAI-imposed early termination. Only report a blocker when concrete current evidence demonstrates it.
- Pending CI/Pages is not permission to close. Continue until required checks are terminal; repair failures and reverify.
- New explicit user direction supersedes the current execution plan immediately where repository integrity/safety permits.
- Before final response on every coding prompt, confirm that `README_CONTEXT.md` was updated. If it was not, update it before replying.
