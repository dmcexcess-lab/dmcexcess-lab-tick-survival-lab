# Tick Survival Lab — Design / Approval / Implementation Workflow

Status: **mandatory project process**.

This project is intentionally developed one subsystem at a time. The goal is not merely to keep files small. The goal is to make each system understandable, independently testable, replaceable, and consistent with the same whole-game direction even after months of deeper work.

## 1. Core development rule

> **DESCRIBE -> APPROVE -> IMPLEMENT -> VERIFY.**

For any new major system or meaningful rewrite:

1. GPT first refreshes the project North Star/current decisions/current context.
2. GPT describes the system in a focused design proposal.
3. The user approves, rejects, or changes that design.
4. Only after approval does implementation begin.
5. The implementation is verified against that approved system design and protected neighboring contracts.

Do not skip the design/approval step merely because the code looks straightforward.

## 2. The anti-drift document stack

Different documents answer different questions. Do not make one giant context file do all of them.

### `PROJECT_NORTH_STAR.md` — WHY / WHAT GAME
Short, frequently reread identity and experience target.

It answers:

- What game are we making?
- What should it feel like?
- What simplification philosophy are we using?
- What broad world/time/player assumptions should survive local redesigns?

A local system design must not casually contradict the North Star.

### `DESIGN_DECISIONS.md` — WHAT WE SETTLED / WHY
Cross-system choices and rationale, including explicit supersession history.

This prevents later work from seeing only the current code and forgetting why a foundational decision was made.

### `README_CONTEXT.md` — WHERE WE ARE NOW
Short routing/current-state index.

It answers:

- current phase;
- current active design/system;
- implemented vs frozen/reference status;
- next design step;
- which docs/history are authoritative.

It should not become an encyclopedia.

### `SYSTEM_DESIGNS/*.md` — HOW THIS ONE SYSTEM WORKS
Detailed canonical contract/rules for one subsystem.

### `README_SOPS.md` — HOW GPT SHOULD WORK
Coding/GitHub/Godot/Safari/process lessons and mandatory repository workflow.

### `MODULAR_REBUILD_MASTER_DESIGN.md` — BROAD ARCHITECTURE INVENTORY
Useful global module/boundary inventory, but newer North Star/decision entries supersede older macro assumptions when the game direction evolves.

## 3. Scope gate — push back when the request is too large

A single implementation prompt should normally target **one major subsystem** or one tightly coupled slice of a subsystem.

If a request would require designing or rewriting several major systems at once, GPT must **push back before implementation**.

Do this:

1. identify the systems involved;
2. explain dependency/order;
3. recommend the first bounded piece;
4. describe that piece;
5. get approval;
6. implement only that approved piece in a later implementation step.

Small integration edits needed to connect an already-approved subsystem are allowed, but they must be identified before implementation and must not become an excuse to redesign neighboring systems.

## 4. Whole-game check before local design

Before proposing a subsystem, reread the North Star and ask:

- What future gameplay features are already known to depend on this area?
- Can this system expose a stable seam for those features without implementing them now?
- Is the design becoming too specific to today's temporary implementation?
- Is complexity being added because it creates consequence/mood, or merely because a deeper simulator could model it?
- Does this local choice accidentally reintroduce an architecture that was superseded?

Future-proofing means **extension seams**, not premature implementation.

Example: a health system should leave room for combat, movement penalties and first aid without simulating detailed physiology merely to prove extensibility.

## 5. No placeholder / fake-completion rule

The project does not use fake systems merely to make a prompt look complete.

Do not add:

- placeholder mechanics presented as finished behavior;
- arbitrary hardcoded values intended to be silently replaced later;
- fake loot, fake AI, fake outbreak history, fake travel costs, fake persistence, or fake simulation results;
- presentation tricks that hide invalid world geometry;
- compatibility shims that quietly become permanent architecture;
- "good enough for now" substitute systems when the real owning system has not been designed.

A temporary DEV tool is allowed only when it is explicitly a DEV tool, has its own owner, and does not pretend to be final gameplay.

Small scope is encouraged. **Fake scope is not.** A tiny authored test world can exercise a real renderer; a disposable fake renderer is not acceptable.

## 6. Clarification rule

GPT should ask a targeted question when a material ambiguity could change architecture, data, visuals, destructive scope, simulation semantics, persistence, timing or player-visible behavior.

Clarification is especially required when:

- historical references could point to multiple implementations and archaeology cannot resolve the target;
- a phrase could reasonably describe two different gameplay models;
- a change could delete/replace significant work;
- ownership between systems is unclear;
- a request conflicts with an approved/cross-system decision;
- implementation would require changing a stable public contract;
- a new idea may change the North Star itself rather than only one subsystem.

Do not ask about ordinary typos/spelling when intent is clear. Inspect repository/history/current conversation first; ask only what remains unresolved.

## 7. System design document requirement

Every major subsystem gets a standalone design file under `SYSTEM_DESIGNS/` before implementation.

Each design should contain:

1. **Status** — DRAFT / APPROVED / IMPLEMENTED / SUPERSEDED.
2. **Goal** — one problem this subsystem solves.
3. **Non-goals** — nearby responsibilities it explicitly does not own.
4. **Owner** — intended standalone script(s).
5. **Public contract/API** — inputs, outputs, signals, data types.
6. **Data ownership** — what state it may mutate and what it may only read.
7. **Dependencies** — only the modules it is allowed to know about.
8. **Forbidden dependencies** — modules it must never reach into.
9. **Behavior/rules** — detailed design semantics.
10. **Performance requirements**.
11. **Safari/mobile requirements** where relevant.
12. **Failure cases / edge cases**.
13. **Tests / acceptance criteria**.
14. **Recovery sources** — old files/commits if this system has solved historical work.
15. **Future extension points** — known future systems that should attach without rewriting this system.
16. **North-star fit** — brief explanation of how this design serves the whole-game identity without owning unrelated future behavior.
17. **Approved decisions** — concise user-approved choices with date/rationale.

The system design is canonical detailed memory for that subsystem.

## 8. Approval state

- **DRAFT** — discussion only; no implementation.
- **APPROVED** — user approved; implementation may begin.
- **IMPLEMENTED** — approved design is present/tested in canonical runtime.
- **SUPERSEDED** — retained for history but no longer current.
- **RECOVERY SOURCE** — useful historical behavior, not current architecture.

A design becoming detailed is not approval by itself.

If later user direction invalidates a draft, mark/supersede it instead of quietly adapting implementation around stale assumptions.

## 9. Cross-system decision logging

When a discussion settles something that affects several systems—such as open-world persistence, tactical grid semantics, hard-pause requirements, player-story philosophy, or art/physics separation—record it in `DESIGN_DECISIONS.md`.

Do not copy every minor implementation fact into the decision log.

When a decision changes:

1. add a new dated entry;
2. name the older decision it supersedes;
3. explain why;
4. update North Star/context/system specs as needed.

History should remain readable.

## 10. Change-impact declaration

Before implementing an approved system, GPT should explicitly identify:

### Files/modules expected to change
The owning module(s), tests, and narrowly necessary wiring/docs.

### Files/modules that must remain untouched
Neighboring systems protected by the current contract.

### Contract impact
Whether any public data/API contract changes. If yes, explain why before editing dependent modules.

### Future seam check
Which already-known future systems are expected to consume/extend this contract, and why the implementation does not need to own them now.

If implementation unexpectedly requires unrelated module changes, stop and reassess the design instead of continuing a cascading patch.

## 11. Implementation workflow

For each approved system:

### A. Refresh
- Read North Star.
- Read decision log.
- Read SOP/context/workflow.
- Read active approved system design.
- Read master design only where relevant/current.
- Inspect current source/history/golden code as needed.

### B. Declare impact surface
State which subsystem/files will change and which adjacent systems will not.

### C. Implement only approved behavior
Do not opportunistically add neighboring features.

### D. Test subsystem independently
Prefer deterministic contract/unit/smoke tests that can run without presentation when possible.

### E. Integration test
Prove it works through public contracts, not internal reach-through.

### F. Update durable memory
- system status/discoveries;
- cross-system decision log if a foundational decision changed;
- North Star only if game identity/direction genuinely changed;
- context current phase/next step;
- SOP reusable implementation lessons;
- changelog.

### G. Exact-head validation
For code changes, validate exact final SHA through Godot/CI/Web deployment before claiming success.

## 12. Design review standard

Question a design before approval if:

- ownership is unclear;
- one module has several unrelated reasons to change;
- a system would inspect another system's internals;
- renderer/simulation truth are mixed;
- generated data contains art indices;
- UI directly mutates world state instead of emitting intent;
- a local streaming/chunk representation is being mistaken for the logical world model;
- the only way to replace the system is to edit many unrelated files;
- the system has no testable public contract;
- a known future feature would obviously require tearing the design apart;
- extra complexity does not buy meaningful consequence or mood.

## 13. Current game-level development philosophy

The canonical shorthand is:

> **Ultima-style turn-based mini Zomboid.**

And:

> **Mini means reduced complexity, not reduced consequence or mood.**

Current broad direction includes:

- persistent logically continuous open world;
- invisible tactical grid / discrete action timing;
- hard real-life interruption safety;
- globally coherent world planning before local materialization;
- physical base/home in the world;
- extraction-style expedition risk/reward rather than mandatory disconnected raid instances;
- causal outbreak/population simulation using scalable simulation resolution;
- customizable player story embedded in generated households/jobs/homes/relationships;
- strong vision/lighting/weather/spatial-sound mood systems later;
- simplified health/needs where deep physiology does not add enough meaningful decision;
- no placeholder systems presented as final mechanics.

See `PROJECT_NORTH_STAR.md` for canonical details.

## 14. Approval ledger

The authoritative approval/status index lives in `SYSTEM_DESIGNS/README.md`.

The current foundational design sequence begins below the old RaidMapSpec level: Spatial Model, Tick/Action/Pause, Persistent World Identity/State, then Population/Outbreak/Player-Story foundations before generalized local world data/render/materialization.
