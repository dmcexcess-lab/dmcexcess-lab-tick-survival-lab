# GPT CODING / GITHUB SOP — TICK SURVIVAL LAB

> **MANDATORY ENTRY CONDITION:** At the start of every new prompt requesting repository/code changes, fetch current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, `README_CONTEXT.md`, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, and the active system design(s). Read `MODULAR_REBUILD_MASTER_DESIGN.md` for architecture/global-direction work, subject to newer North Star/decision entries. Inspect current relevant source/history. Refresh once per prompt, not before every edit inside the same coherent task.

## 1. Current status

Tick Survival Lab is in **modular foundation implementation**.

Primary game shorthand:

> **Ultima-style turn-based mini Zomboid.**

Canonical game identity/anti-drift reference: `PROJECT_NORTH_STAR.md`.

Cross-system decisions/rationale: `DESIGN_DECISIONS.md`.

The deployed `game/scripts/reboot/` runtime is **frozen/deprecated reference code**. Do not extend it as the target architecture.

Canonical modular foundation status:

- **00A WHERE / Spatial Model — IMPLEMENTED** under `game/scripts/foundation/spatial/`, dedicated CI contract smoke.
- **00B WHAT / Persistent World State — IMPLEMENTED** under `game/scripts/foundation/world/`, dedicated CI contract smoke.
- **00C WHEN / Tick Action Pause — next bounded system; not implemented.**

Canonical broad modular architecture inventory: `MODULAR_REBUILD_MASTER_DESIGN.md`, but older static-raid/strategic-map assumptions in that file yield to newer North Star/decision entries.

Canonical development process: `DESIGN_WORKFLOW.md`.

System approval ledger: `SYSTEM_DESIGNS/README.md`.

Golden recovery commit for mature pre-clean-rewrite behavior/art archaeology:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

## 2. Core operating rules

1. **Newest explicit user instruction beats older design.**
2. **Read the North Star before solving the local problem.** A locally convenient fix must still make sense for the whole game.
3. **Current repo beats memory.** Fetch first.
4. **Design before implementation.** Major systems require user-approved system designs.
5. **One major system per implementation slice by default.**
6. **Push back when scope is too broad.** Do not attempt "the whole game" or several major systems in one prompt just because the user asked quickly.
7. **Main/root is composition only.**
8. **One named independently changeable system = one standalone owner at minimum.** Do not split every helper function into a file merely for file-count modularity.
9. Prefer composition, small public contracts, and dependency injection over deep inheritance/shared internals.
10. **A subsystem rewrite must not opportunistically rewrite neighboring systems.**
11. **No placeholders/fake completion.** DEV-only shortcuts must be explicit DEV tools and separately owned.
12. **Do not approximate historical behavior and call it recovered.** Inspect the actual golden implementation/assets.
13. **Ask targeted clarification when a material ambiguity remains after inspection.**
14. Do not ask about ordinary spelling/typos when intent is clear.
15. Keep simulation testable without presentation.
16. Do not claim success without exact-final-SHA validation for code changes.
17. Direct `main` remains normal unless the user explicitly requests branch/PR workflow.
18. **When a new discussion materially changes the game's cross-system direction, update North Star/decision/context docs in the same coherent prompt rather than letting chat outrun the repo.**
19. **During a staged modular replacement, canonical new modules may remain independently tested beside the frozen runtime. Do not create temporary adapters merely to make new work visibly affect the deprecated build.** Wire systems only when the adjacent canonical contracts needed for a real integration exist.

## 3. North-star drift check

Before proposing or implementing a system/fix, ask internally:

- Does this still serve **Ultima-style turn-based mini Zomboid**?
- Are we preserving **reduced complexity, not reduced consequence or mood**?
- Does this assume an older architecture that the persistent-open-world direction superseded?
- Is this local fix making the owning system cleaner, or merely hiding the visible symptom?
- Does the proposed API leave known future systems room to connect without making the current system own them?
- Would this decision force a later generator/render/input/etc. rewrite to touch unrelated systems?

If the local solution conflicts with the North Star or a newer cross-system decision, stop and surface the conflict instead of optimizing the local symptom.

## 4. Scope gate / mandatory pushback

Before implementing, classify the request.

### Single-system request
Proceed through the approved system design and impact declaration.

### Multi-system request
If the request requires meaningful work across multiple major domains (for example generator + renderer + player + world state), **do not begin coding all of them**.

Instead:

1. identify the systems involved;
2. explain dependency/order;
3. recommend the first bounded system;
4. describe that system;
5. obtain user approval;
6. implement only that approved slice later.

Small wiring changes needed to connect an approved module are allowed, but list them in advance and do not redesign the neighboring subsystem.

If implementation unexpectedly expands across a forbidden boundary, stop. Do not keep patching.

## 5. Clarification triggers

Ask a concise targeted question before implementation when unresolved ambiguity could materially change:

- architecture/module ownership;
- destructive scope;
- stable public contracts;
- visual target/history;
- simulation semantics;
- mobile/Safari interaction;
- persistence/save shape;
- timing semantics;
- player-visible behavior;
- whether a new idea changes the North Star rather than only one subsystem.

Examples:

- "restore the old graphics" when several historical renderers exist and archaeology cannot identify which one;
- "make vehicles work" when this could mean physical driving, abstract long-distance travel, or both;
- "rewrite the generator" when it is unclear whether existing semantic/persistent-world contracts must remain compatible;
- "make the world open" when it is unclear whether partitions are separate realities or only streaming/storage divisions.

Inspect repo/history first. Ask only what remains unresolved.

## 6. Required pre-implementation checklist

For an approved code change:

1. Read current North Star/SOP/context/workflow/decision log.
2. Read the APPROVED system design.
3. Read master design if architecture/boundaries are involved.
4. Fetch current main SHA.
5. Inspect current owner module(s).
6. Inspect recovery/golden files when relevant.
7. State the system's public contract.
8. Declare files/modules expected to change.
9. Declare neighboring modules that must remain untouched.
10. Identify whether the public contract itself changes.
11. Check known future seams listed in the North Star/system design so the local implementation does not become needlessly restrictive.
12. Fetch current blob SHAs for files being replaced.
13. Identify required subsystem and integration tests.

If no APPROVED system design exists for a major new system, do not code it. Draft/design it first.

## 7. Main/root rule

Future `Main.gd` is bootstrap/wiring only.

Allowed:

- obtain module references;
- construct/inject dependencies;
- connect high-level signals;
- choose initial top-level controller/mode;
- minimal lifecycle bookkeeping.

Forbidden:

- drawing;
- gameplay input handling;
- touch hit testing/button geometry;
- keyboard mappings;
- world rendering;
- HUD/control rendering;
- camera/zoom math;
- generation;
- prefab logic;
- player movement/facing;
- collision/door rules;
- world-flow/base rules;
- art/atlas selection;
- persistence;
- ticks/calendar;
- lighting/perception/weather/sound;
- validation/quality rules;
- subsystem-specific DEV tools.

Never justify implementation in Main because it is temporary, easy, small, or only for development.

## 8. Replaceability test

Architecture is acceptable only if these remain plausible:

- delete/rewrite `generation/` without touching art/render/player/input/camera/persistent-world rules;
- delete/rewrite `render/` without touching generation/player physics/persistent state;
- replace `input/` without changing movement/simulation rules;
- replace art mapping without changing physics;
- replace prefab DEV tooling without changing normal world/render/generator contracts;
- add/recover lighting/perception/weather/sound without generator-specific presentation hacks;
- replace streaming/storage partition strategy without changing the logical global world coordinate model;
- change base/community UI without turning persistent physical world facts into menu-only truth.

When a feature requires edits on both sides of a contract, determine whether the contract needs an explicit approved revision. Do not silently make modules depend on each other's internals.

## 9. Semantic world-data boundary

Generation/simulation use semantic IDs and explicit physics/state facts.

Examples:

- `ground.grass_lush`
- `ground.gravel_driveway`
- `wall.house_siding`
- `door.house`
- `fixture.kitchen_sink`
- `prop.utility_pole`

Generator code must not know:

- texture paths;
- atlas coordinates;
- renderer calls;
- UI geometry;
- player sprites;
- presentation colors.

Rendering maps semantic IDs through the canonical art catalog.

**Art is not physics.** Sprites do not implicitly decide collision, opacity, door state, interaction, searchability, destructibility, or persistence.

Directional world objects should store semantic orientation/facing. Renderer owns whether that means 90-degree rotation or an explicit alternate-facing image.

## 10. Golden visual recovery

Golden mature visual source: commit `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

Golden `TacticalTiles.gd` blob:

`3d8a0a70ac983408bb48f58fc659dfb07e216ed3`

It combined:

- `tactical_atlas.svg`;
- `clutter_atlas.svg`;
- `world_art_atlas.svg`;
- `building_props_atlas.svg`;
- `final_environment_surfaces_atlas.svg`;
- `final_environment_props_atlas.svg`;
- four directional player SVGs.

The current art files are preserved. Visual recovery means recovering semantic selection/draw behavior into standalone art/render modules, not choosing one atlas and claiming success.

Do not modify preserved baseline art during non-art prompts.

## 11. Design-document discipline

Detailed system rules belong under `SYSTEM_DESIGNS/`.

`PROJECT_NORTH_STAR.md` owns the short game identity, experience target and anti-drift principles.

`DESIGN_DECISIONS.md` owns cross-system settled decisions and rationale. New decisions supersede old entries explicitly; do not erase history.

`README_CONTEXT.md` is a current-state routing index only.

`MODULAR_REBUILD_MASTER_DESIGN.md` owns broad architecture inventory but may contain older assumptions; newer North Star/decision entries take precedence.

`DESIGN_WORKFLOW.md` owns approval/scope/process.

### Approval status

- DRAFT = discussion only; no implementation.
- APPROVED = implementation allowed.
- IMPLEMENTED = approved design exists in canonical source and is tested.
- SUPERSEDED = historical only.

If implementation reveals the APPROVED design cannot work without crossing a forbidden module boundary, return the design to DRAFT, explain the conflict, and get approval for the contract change.

## 12. No-placeholder / no-fake rule

Do not implement a substitute merely to satisfy the prompt.

Examples of unacceptable behavior:

- random placeholder values that silently become architecture;
- fake AI/event rolls presented as simulated actors;
- fake outbreak history presented as causal simulation;
- fake travel costs before travel/tick ownership exists;
- fake loot/search before inventory ownership exists;
- presentation erasure that hides invalid geometry;
- a temporary monolithic function intended to be "split later";
- a temporary adapter from new canonical code into a deprecated runtime that has no long-term contract;
- calling an approximation the recovered original.

If the actual owning system is not designed yet, stop at a clean interface or defer the behavior explicitly.

## 13. Persistent-world / generation standards

The logical world is not defined by streaming chunks. Global coordinates/world planning define reality; streaming/storage partitions are implementation details.

Large-scale generation should establish globally coherent facts before local detail materialization, particularly for roads/utilities/parcels and other cross-boundary structures.

Generation is an input to initial world state. Once a place exists and gameplay changes it, persistent world state owns those changes.

A generator coordinator orchestrates focused modules; it is not a god script.

Expected separated generation/world-planning responsibilities may include:

- global geography/district planning;
- road network/topology;
- utility/infrastructure network;
- parcels/addresses/access;
- building/property selection and footprints;
- household/business/population assignment;
- local room/layout materialization;
- fixtures/furniture/clutter;
- vegetation/civic dressing;
- independent validation.

Avoid corrective pass chains that repeatedly delete/rebuild earlier output. Compose semantics intentionally, then validate.

## 14. Canonical spatial foundation

`SYSTEM_DESIGNS/00A_SPATIAL_MODEL.md` is IMPLEMENTED.

Canonical WHERE rules:

- invisible authoritative global tactical grid;
- integer `Vector2i` cells;
- centralized planning scale `SpatialModel.CELL_METERS = 1.0`;
- cell-to-cell actor baseline;
- arbitrary whole-cell prop/fixture/vehicle footprints;
- N/E/S/W semantic facing/orientation;
- deterministic 90-degree footprint rotation;
- structure cells, not edge walls;
- explicit HORIZONTAL/VERTICAL structure axis;
- no sub-cell/free movement without a concrete gameplay need;
- geometry only: WHERE stores no occupants, door state, collision policy, timing, art or generator facts.

Do not reopen these decisions as accidental implementation details. If a later system exposes a real gameplay requirement to change them, treat it as an explicit cross-system contract revision.

## 15. Canonical persistent-world foundation

`SYSTEM_DESIGNS/00B_PERSISTENT_WORLD_STATE.md` is IMPLEMENTED.

Canonical WHAT rules:

- one authoritative current persistent world;
- opaque stable string entity IDs independent of Nodes/array order/placement;
- semantic entity types and semantic terrain; no renderer indices;
- no generic metadata bag in the foundation entity record;
- entities may remain persistent while unplaced;
- placement uses WHERE channel + anchor + facing + footprint + optional structure axis;
- occupancy is derived/indexed and never owns collision legality;
- normal writes pass through `WorldMutationService`;
- public entity/placement reads are mutation-safe copies;
- successful foundation mutations advance a revision and emit typed mechanic-agnostic changes;
- deterministic in-memory snapshot/restore is atomic and rebuilds derived occupancy;
- WHAT has no WHEN/generator/render/streaming/reboot or gameplay-mechanic dependency.

Future health/inventory/door/vehicle/infection/etc. state should normally be explicit typed domain state keyed by the same stable entity IDs rather than appended to a universal foundation dictionary.

## 16. Performance/mobile rules

Phone/Safari is first-class.

- one physical touch = one semantic action;
- no hover-only interaction;
- synthetic mouse duplication must be handled by dedicated Safari/input owners;
- native text inputs should be used where iOS Safari must summon the keyboard;
- renderer should draw only visible cells;
- no idle full tactical redraw if nothing animated requires it;
- future animated overlays should use bounded redraw cadence and not force unrelated simulation recomputation;
- one zoom owner supplies canonical zoom values;
- real-life interruption requires a hard application pause design; browser/app visibility/focus behavior must never let simulation continue unnoticed when the platform gives us a reliable lifecycle signal.

## 17. Reusable coding/GitHub lessons — living SOP

This section grows when repeated lessons are discovered.

### Godot/GDScript

- Be conservative with `:=` around `Dictionary`/`Variant`; explicit types/conversions avoid strict inference surprises.
- **Do not initialize a typed array through a ternary whose alternate branch is a bare `[]`.** Godot can produce an untyped `Array` at runtime and reject assignment to `Array[T]`. Initialize `var values: Array[T] = []` first, then assign inside an explicit branch.
- GDScript static return analysis may still require an explicit fallback return after an apparently infinite `while true` loop in a typed-return function.
- Keep data schemas/API names stable and test them as contracts.
- Avoid mutation inside draw functions.
- Prefer deterministic headless tests for generation/simulation.
- DEV UI is still a subsystem; do not hide it in Main.
- Do not make every persistent world object a Godot Node merely because it exists; detailed node/materialization strategy belongs to the approved streaming/render design.
- Pure foundation/value modules should prefer `RefCounted`/static helpers and deterministic integer/value operations when Nodes/signals/frame callbacks are unnecessary.

### Modular migration

- A new canonical subsystem does **not** need to affect the currently deployed deprecated runtime to count as real progress. Its contract + owning code + dedicated tests can be complete independently.
- Do not add compatibility glue whose only purpose is to make a new module visibly run through old architecture. Wait until the canonical neighboring contracts exist, then integrate once through the real seam.
- When a system status changes (for example APPROVED -> IMPLEMENTED), update CI/document guards that assert that status; otherwise the process check itself becomes stale.

### Web/Safari

- Real touch may synthesize mouse input; de-duplication needs one dedicated owner.
- Keyboard shortcuts are developer conveniences, never the only route to mobile-visible features.
- Native `LineEdit`/editable controls are safer where iOS Safari must summon the keyboard.

### GitHub/CI

- Exact final SHA is the only SHA that counts for completion.
- CI should test system contracts, not merely parse success.
- When a bug exposes a missing invariant, add the invariant/test rather than only patching the one seed/case.
- Historical recovery claims should cite/inspect the historical commit/file, not rely on chat memory.
- Do not weaken a test merely because implementation fails; decide whether the design or implementation is wrong.
- Source/document guards are contracts too. Keep them synchronized with intentional lifecycle/status changes.

### Living-document update rule

If a reusable coding/process lesson is discovered during a prompt, add it here in that same coherent prompt when it applies across systems.

If a cross-system **game/design decision** changes, add it to `DESIGN_DECISIONS.md` and update North Star/context if required.

If it belongs only to one subsystem, record it in that subsystem design instead.

Do not leave important lessons or decisions only in chat.

## 18. Validation rule

For documentation-only changes, preserve the currently deployed reference build and run the existing Pages gate if repository workflow triggers it.

For modular code changes, exact final SHA must pass:

1. source/architecture checks;
2. Godot import/parse;
3. owning subsystem contract test(s);
4. relevant integration test(s) when a real integration exists;
5. frozen-reference smoke(s) during staged replacement, until that runtime is retired;
6. real startup smoke;
7. Web export;
8. Pages deployment under the current workflow.

Add one focused CI test per subsystem instead of one giant smoke script that knows every internal detail.

## 19. Communication rule

- Surface architectural concerns before coding.
- Explain when a user request is too broad and propose a smaller sequence.
- Do not be afraid to recommend a better architecture/process, but respect the user's final choice after explaining tradeoffs.
- Distinguish design, implementation, verified behavior, and future intent.
- Do not claim something was preserved/recovered unless inspection proves it.
- If clarification is needed, ask the smallest question that changes the decision.
- If current repo docs conflict with the current conversation, do not silently pick one: identify whether the conversation changed the design and update durable memory accordingly.
- When canonical code is intentionally not wired into the frozen playable reference, say so plainly rather than implying the live game changed.

## 20. Required final footer after repository changes

End repo-change responses with:

- Changelog: `https://github.com/dmcexcess-lab/dmcexcess-lab-tick-survival-lab/blob/main/CHANGELOG.md`
- Play: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Until the modular runtime replaces it, clarify that the Play URL is the frozen/deprecated reference build and may not visibly reflect independently implemented foundation modules.
