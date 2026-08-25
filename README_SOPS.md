# GPT / Repository SOP — Tick Survival Lab

Status: **canonical development process**.

## 1. Mandatory refresh

At the start of every new prompt that requests repository/code changes, read current:

1. `PROJECT_NORTH_STAR.md`;
2. `PERFORMANCE_NORTH_STAR.md`;
3. `DESIGN_DECISIONS.md` when the change touches cross-system direction;
4. `README_CONTEXT.md`;
5. `ROADMAP.md` when priority/order/scope may matter;
6. this SOP;
7. `SYSTEM_DESIGNS/README.md`;
8. the active APPROVED/IMPLEMENTED system design(s);
9. current `main` SHA and relevant source/history.

Refresh once per coherent prompt, not before every edit.

Current repository beats memory. Newest explicit user direction beats older repository design, but material direction changes must be written back into the canonical docs in the same coherent task.

## 2. Game identity / anti-drift check

Primary shorthand:

> **Ultima-style turn-based mini Zomboid.**

Core rule:

> **Mini means reduced complexity, not reduced consequence or mood.**

Performance rule:

> **The low-resolution 2D presentation and turn-based simulation are deliberate performance advantages. Spend that budget on simulation depth, persistence, world scale and responsiveness — not avoidable work.**

Before solving a local problem, ask whether the proposed change still serves the persistent open-world, discrete-time survival game described by `PROJECT_NORTH_STAR.md` and the performance doctrine in `PERFORMANCE_NORTH_STAR.md`.

Do not optimize a local implementation around superseded raid/extraction assumptions.

`ROADMAP.md` controls current major-phase order, but does not override the North Star, performance doctrine or subsystem ownership rules.

## 3. Design lifecycle

Major new systems and meaningful rewrites use:

> **DESCRIBE -> APPROVE -> IMPLEMENT -> VERIFY**

Statuses:

- `DRAFT` — discussion only;
- `APPROVED` — implementation authorized;
- `IMPLEMENTED` — approved behavior exists in canonical source and its required tests pass;
- `SUPERSEDED` — historical only;
- `RECOVERY SOURCE` — historical behavior/art worth mining, not current architecture.

A new major system requires an approved design before code. A profile/content addition inside an already-established system does **not** automatically require a new peer system document; use the owning system design unless the addition changes a stable system contract or genuinely introduces an independently changeable domain.

A roadmap phase is not blanket authorization to implement everything named in that phase at once.

## 4. Scope gate

One implementation prompt should normally target one major subsystem or one tightly coupled refactor of an existing subsystem.

If a request requires several unrelated domains, identify the dependency order and implement only the first bounded piece unless the user explicitly approves a coherent cross-cutting refactor.

Small wiring edits across public seams are allowed. Neighbor rewrites are not.

If implementation unexpectedly crosses a protected boundary, stop and reassess rather than patching outward.

## 5. Modularity without fragmentation

The goal is replaceability, **not file count**.

A separate owner/file is justified when a responsibility has at least one of these properties:

- independent state or lifecycle;
- a stable reusable public contract;
- a materially independent reason to change;
- enough cohesive implementation complexity that keeping it private inside its owner would make that owner harder to understand or test.

A candidate, profile, revision, helper function, implementation slice, or test fixture is **not automatically a system**.

Do not create a file merely because a rule says everything needs a file. Conversely, do not merge real domains merely to make the repository look smaller.

Prefer a cohesive module with private helpers over chains of one-method wrappers. Prefer a small provider/adapter seam over adding another special-case field/branch every time a new source type appears.

## 6. Core ownership rules

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

Technical streaming/chunk boundaries never become logical world geography or persistent object identity.

Generation creates virgin truth once. After successful materialization, WHAT and typed mechanic stores own current reality.

## 7. Stable contract rule

Prefer composition, narrow public methods, immutable/validated records where identity matters, and dependency injection over deep inheritance or reach-through into another subsystem's internal dictionaries.

Do not introduce a typed record/class for every temporary planning dictionary. Strong typing should buy persistent identity, a cross-system boundary, meaningful validation, or reuse—not ceremony.

When a public contract changes, state the change before editing dependent modules and prove existing consumers still behave correctly or intentionally migrate them in the same approved change.

## 8. No fake completion

Do not add placeholders and present them as finished systems.

Do not add fake AI, fake persistence, fake outbreak results, fake utility hardware, fake terrain, fake physics, fake power, fake sound sources, or presentation tricks that conceal missing world truth.

A deliberate DEV fixture/tool is allowed when it is clearly labeled, independently owned where necessary, and not used as a silent substitute for canonical gameplay.

## 9. Pre-implementation declaration

Before implementing an approved code change, state:

- expected files/modules changed;
- protected neighboring modules;
- public contract impact;
- future seam being preserved.

Then inspect current source and current blob SHAs for files being replaced.

## 10. Testing / verification

Simulation/generation systems should be testable without presentation whenever practical.

Keep focused subsystem smoke/contract tests. Adding a new profile to an existing system should normally extend the owning domain workflow/test suite rather than create a new permanent CI workflow solely because the profile had a candidate number.

### Executable changes

For changes to code, assets used at runtime, Godot configuration, or CI/workflow behavior:

- run the owning subsystem contract;
- run required protected integration regressions;
- do not claim success until the exact final code SHA is validated.

### Documentation-only closure

A later documentation-only status/changelog/roadmap correction does **not** require rerunning every expensive Godot contract merely because the commit SHA changed. Instead:

- verify the diff is documentation-only;
- cite the already-green implementation SHA as executable evidence;
- run lightweight link/status/consistency checks as appropriate.

If a documentation commit changes executable/config/workflow files, it is not documentation-only and full exact-head validation applies.

## 11. Repository workflow

Direct `main` is normal unless the user requests PR/branch workflow or a destructive recovery operation genuinely benefits from isolation.

Do not accumulate temporary compatibility adapters, patch workflows, or permanent work branches merely to satisfy tooling convenience.

Current canonical history is Git itself. Historical implementations do not need to remain in the active source tree solely for archaeology when their recovery commit/blob is documented.

## 12. Documentation discipline

Active canonical docs answer different questions:

- `PROJECT_NORTH_STAR.md` — what game/experience are we building?
- `PERFORMANCE_NORTH_STAR.md` — what computational bargain must every system preserve?
- `DESIGN_DECISIONS.md` — what cross-system choices were settled and why?
- `ROADMAP.md` — what major gameplay phase comes next and in what order?
- `README_CONTEXT.md` — where are we now and what is active/next?
- `SYSTEM_DESIGNS/README.md` — status/routing ledger;
- `SYSTEM_DESIGNS/<system>.md` — canonical current contract for that system;
- `README_SOPS.md` — how repository work is performed;
- `CHANGELOG.md` + archives — implementation history.

Completed candidate/slice discussion files should be folded into their owning canonical system document when they no longer represent independently useful active contracts. Git history preserves the detailed drafting path.

Do not keep two active documents that both claim authority over the same process, roadmap, or system state.

## 13. Recovery / historical code

Golden mature visual/system archaeology commit:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

Golden `TacticalTiles.gd` blob:

`3d8a0a70ac983408bb48f58fc659dfb07e216ed3`

Recover historical behavior by inspecting the real commit/assets. Do not approximate it from memory.

Frozen/deprecated source may be removed from the active tree once:

1. canonical runtime no longer imports it;
2. unique still-needed behavior has been recovered or explicitly deferred;
3. the recovery commit/blob remains documented.

## 14. Main/root rule

Composition roots may construct services, inject dependencies, connect high-level signals, select initial controllers/modes, and perform minimal lifecycle bookkeeping.

They must not own rendering rules, gameplay input interpretation, world generation, collision, movement, doors, inventory, simulation timing, persistence, camera math, UI geometry, art mapping, weather/perception/sound, utilities, AI, or subsystem validation.

A composition root can be long because the application has many services. Do not split it into fake bootstrap managers merely to reduce line count.

## 15. Clarification rule

Inspect first. Ask a targeted question only when unresolved ambiguity could materially change architecture, destructive scope, stable contracts, persistence, timing, historical target, mobile interaction, or player-visible semantics.

Do not ask about ordinary typos when intent is clear. When explicit numbering and surrounding content resolve an omitted label cleanly, preserve the user's intended order and record the normalization rather than creating unnecessary friction.

## 16. Mobile/browser requirement

Phone/Safari is first-class. Input/lifecycle systems must consider touch/mouse de-duplication, keyboard availability, focus loss, and the North Star's hard real-life pause requirement where relevant.

## 17. Performance-first architecture gate

Performance is evaluated **before** an implementation becomes expensive, not only after a playtest exposes a stall.

For every new system or meaningful rewrite, inspect its asymptotic and recurring cost explicitly:

- What work happens per render frame?
- What work happens per simulation tick/action?
- What work happens per active entity?
- What work happens when a streamed region materializes or activates?
- Does any local query scan the whole world or a much larger set than necessary?
- Can the same truth be derived analytically, cached behind a revision, batched, coalesced, computed at a coarser distant resolution, or updated only on relevant events?
- Is presentation doing CPU work that belongs naturally on the GPU?
- Is one runtime Node/timer/process/scheduled event being created per persistent entity without a gameplay reason?

Prefer bounded work whose cost follows the smallest relevant active set. A turn-based system must not wake merely because a render frame occurred. A low-resolution presentation must not become expensive through unnecessary draw-call, transform, allocation, polling or signal overhead.

Do not accept an avoidably expensive design on the basis that current desktop hardware handles it. Preserve computational headroom for later population, outbreak, AI, utilities, vehicles, persistence and world-scale simulation.

Performance work must remain honest: optimization may change representation, scheduling, caching, resolution or presentation technique, but it must not silently remove causal world truth or meaningful consequences.
