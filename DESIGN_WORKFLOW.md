# Tick Survival Lab — Design / Approval / Implementation Workflow

Status: **mandatory project process**.

This project is intentionally being developed one subsystem at a time. The goal is not merely to keep files small. The goal is to make each system understandable, independently testable, and replaceable without forcing unrelated systems to change.

## 1. Core development rule

> **DESCRIBE -> APPROVE -> IMPLEMENT -> VERIFY.**

For any new major system or meaningful rewrite:

1. GPT describes the system in a focused design proposal.
2. The user approves, rejects, or changes that design.
3. Only after approval does implementation begin.
4. The implementation is verified against that approved system design.

Do not skip the design/approval step merely because the code looks straightforward.

## 2. Scope gate — push back when the request is too large

A single implementation prompt should normally target **one major subsystem** or one tightly coupled slice of a subsystem.

Examples of major subsystems:

- semantic tactical map data;
- art catalog;
- ground renderer;
- structure renderer;
- player renderer;
- player movement;
- collision;
- camera/zoom;
- touch input;
- controls UI;
- strategic map;
- road generator;
- property planner;
- prefab system;
- lighting;
- perception;
- weather;
- tick scheduler;
- inventory;
- infected AI.

If a request would require designing or rewriting several of these at once, GPT must **push back before implementation**. Explain the natural split, identify dependencies, recommend the first piece, and wait for approval of that piece.

Small integration edits needed to connect an already-approved subsystem are allowed, but they must be identified before implementation and must not become an excuse to redesign neighboring systems.

## 3. No placeholder / fake-completion rule

The project does not use fake systems merely to make a prompt look complete.

Do not add:

- placeholder mechanics presented as finished behavior;
- arbitrary hardcoded values intended to be silently replaced later;
- fake loot, fake AI, fake travel costs, fake persistence, or fake simulation results;
- presentation tricks that hide invalid world geometry;
- compatibility shims that quietly become permanent architecture;
- "good enough for now" substitute systems when the real owning system has not been designed.

A temporary DEV tool is allowed only when it is explicitly a DEV tool, has its own owner, and does not pretend to be final gameplay.

When a prerequisite system is missing, either design that prerequisite first or clearly defer the dependent behavior.

## 4. Clarification rule

GPT should ask a targeted question when a material ambiguity could change architecture, data, visuals, or destructive scope.

Clarification is especially required when:

- "old", "new", "previous", "better", or similar historical references could point to multiple implementations and repository archaeology cannot resolve the target;
- a word/phrase could reasonably describe two different gameplay behaviors;
- a change could delete or replace significant existing work;
- the requested feature could belong to more than one subsystem and ownership matters;
- mobile/Safari behavior is unclear and would materially change the interaction design;
- a request conflicts with an already approved design decision;
- implementation would require changing a stable public contract between modules.

Do **not** ask the user to clarify ordinary typos or spelling when intent is clear. Do **not** ask for information that can be resolved from the repository, current conversation, or golden recovery history.

When uncertain: inspect first, then ask only the unresolved question.

## 5. System design document requirement

Every major subsystem gets a standalone design file under `SYSTEM_DESIGNS/` before implementation.

Each design should contain:

1. **Status** — DRAFT / APPROVED / IMPLEMENTED / SUPERSEDED.
2. **Goal** — the one problem this subsystem solves.
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
15. **Future extension points** — what later systems may add without changing this contract.
16. **Approved decisions** — concise record of user-approved choices.

The system design is the canonical detailed memory for that subsystem. `README_CONTEXT.md` should link to it instead of trying to summarize every implementation detail forever.

## 6. Context-file role

`README_CONTEXT.md` is a **routing/index/current-state document**, not the encyclopedia of the game.

It should stay relatively short and answer:

- What game are we making?
- What architectural phase are we in?
- What is currently implemented vs frozen/reference?
- Which system is currently being designed or implemented?
- Which system designs are APPROVED?
- What is the next approved step?
- What documents are authoritative?
- What major global invariants must never be forgotten?

Detailed subsystem rules belong in `SYSTEM_DESIGNS/<system>.md`.

This prevents the context file from becoming thousands of vague lines that future GPT sessions skim incorrectly.

## 7. SOP-file role

`README_SOPS.md` owns **how GPT works on the repository**, not gameplay design.

It should contain:

- pre-prompt repository refresh ritual;
- modularity rules;
- scope/pushback rules;
- clarification rules;
- Git/GitHub workflow lessons;
- testing/CI rules;
- artifact/deployment verification rules;
- recurring coding pitfalls discovered during development.

### Living-SOP rule

When a reusable coding, Godot, Safari, testing, or GitHub lesson is discovered, update `README_SOPS.md` in the same coherent prompt if it will help future work avoid repeating the problem.

When the lesson belongs only to one subsystem, update that subsystem's design instead.

Do not let useful lessons exist only in chat history.

## 8. Master-design role

`MODULAR_REBUILD_MASTER_DESIGN.md` owns the long-term architecture, project identity, system boundaries, and global gameplay direction.

It should not become a dumping ground for every implementation detail. Detailed mechanics belong in system designs.

## 9. Change-impact declaration

Before implementing an approved system, GPT should explicitly identify:

### Files/modules expected to change
The owning module(s), its tests, and narrowly necessary wiring/docs.

### Files/modules that must remain untouched
Neighboring systems protected by the current contract.

### Contract impact
Whether any public data/API contract changes. If yes, explain why before editing dependent modules.

If implementation unexpectedly requires unrelated module changes, stop and reassess the design instead of continuing a cascading patch.

## 10. Implementation workflow

For each approved system:

### A. Refresh
- Read current SOP/context.
- Read this workflow.
- Read master design.
- Read the active system design.
- Inspect current relevant code.
- Inspect golden/recovery code when applicable.

### B. Declare impact surface
State which subsystem/files will change and which adjacent systems will not.

### C. Implement only the approved behavior
Do not opportunistically add neighboring features.

### D. Test the subsystem independently
Prefer deterministic contract/unit/smoke tests that can run without presentation when possible.

### E. Integration test
Prove the system works through its public contract, not by reaching into internals.

### F. Update durable memory
- system design status and discoveries;
- context current phase/next step;
- SOP reusable lessons;
- changelog for repository changes.

### G. Exact-head validation
For code changes, validate the exact final commit through Godot/CI/Web deployment before claiming success.

## 11. Design review standard

A design should be questioned before approval if:

- ownership is unclear;
- one module has several unrelated reasons to change;
- a system would need to inspect another system's internals;
- renderer and simulation data are mixed;
- generated data contains art indices;
- UI directly mutates world state instead of emitting intent;
- the only way to replace the system is to edit many unrelated files;
- the system has no testable public contract;
- a later known feature would obviously require tearing the design apart.

Future-proofing does not mean implementing future systems early. It means leaving explicit extension seams for them.

## 12. Game-level development philosophy

Tick Survival Lab is a **mini-Zomboid-style systemic survival simulation with extraction-shooter structure**, built in small approved pieces.

Core direction:

- physical, spatial survival gameplay;
- persistent/consequential systems where implemented;
- no drama director faking threats;
- tactical local maps generated from believable real-world grammar;
- static strategic map controlling progression from rural edge toward city center;
- extraction as the boundary between tactical risk and strategic progression;
- phone/Safari as a first-class platform;
- silent sound simulation unless explicitly reversed;
- no placeholder systems presented as final mechanics.

The project should prefer a small number of well-designed, finished systems over many half-designed systems.

## 13. Approval ledger

The authoritative approval/status index lives in `SYSTEM_DESIGNS/README.md`.

A DRAFT design is not permission to implement it. An APPROVED design is implementation-ready. If later user instructions change an approved design, update the system design/status before changing code.
