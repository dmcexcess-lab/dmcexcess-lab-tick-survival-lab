# GPT CODING / GITHUB SOP — TICK SURVIVAL LAB

> **MANDATORY ENTRY CONDITION:** At the start of every new prompt requesting repository/code changes, fetch current `README_SOPS.md`, `README_CONTEXT.md`, `DESIGN_WORKFLOW.md`, current `main` SHA, and the active system design(s). Read `MODULAR_REBUILD_MASTER_DESIGN.md` for architecture/global-direction work. Inspect current relevant source. Refresh once per prompt, not before every edit inside the same coherent task.

## 1. Current status

Tick Survival Lab is in a **full modular redesign/rebuild**.

The deployed `game/scripts/reboot/` runtime is **frozen/deprecated reference code**. Do not extend it as the target architecture.

Canonical global architecture: `MODULAR_REBUILD_MASTER_DESIGN.md`.

Canonical development process: `DESIGN_WORKFLOW.md`.

System approval ledger: `SYSTEM_DESIGNS/README.md`.

Golden recovery commit for mature pre-clean-rewrite behavior/art archaeology:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

## 2. Core operating rules

1. **Newest explicit user instruction beats older design.**
2. **Current repo beats memory.** Fetch first.
3. **Design before implementation.** Major systems require user-approved system designs.
4. **One major system per implementation slice by default.**
5. **Push back when scope is too broad.** Do not attempt "the whole game" or several major systems in one prompt just because the user asked quickly.
6. **Main/root is composition only.**
7. **One named system = one standalone owner at minimum.**
8. Prefer composition, small public contracts, and dependency injection over deep inheritance/shared internals.
9. **A subsystem rewrite must not opportunistically rewrite neighboring systems.**
10. **No placeholders/fake completion.** DEV-only shortcuts must be explicit DEV tools and separately owned.
11. **Do not approximate historical behavior and call it recovered.** Inspect the actual golden implementation/assets.
12. **Ask targeted clarification when a material ambiguity remains after inspection.**
13. Do not ask about ordinary spelling/typos when intent is clear.
14. Keep simulation testable without presentation.
15. Do not claim success without exact-final-SHA validation for code changes.
16. Direct `main` remains normal unless the user explicitly requests branch/PR workflow.

## 3. Scope gate / mandatory pushback

Before implementing, classify the request.

### Single-system request
Proceed through the approved system design and impact declaration.

### Multi-system request
If the request requires meaningful work across multiple major domains (for example generator + renderer + player + strategic map), **do not begin coding all of them**.

Instead:

1. identify the systems involved;
2. explain dependency/order;
3. recommend the first bounded system;
4. describe that system;
5. obtain user approval;
6. implement only that approved slice later.

Small wiring changes needed to connect an approved module are allowed, but list them in advance and do not redesign the neighboring subsystem.

If implementation unexpectedly expands across a forbidden boundary, stop. Do not keep patching.

## 4. Clarification triggers

Ask a concise targeted question before implementation when unresolved ambiguity could materially change:

- architecture/module ownership;
- destructive scope;
- stable public contracts;
- visual target/history;
- simulation semantics;
- mobile/Safari interaction;
- persistence/save shape;
- timing semantics;
- player-visible behavior.

Examples:

- "restore the old graphics" when several historical renderers exist and archaeology cannot identify which one;
- "make vehicles work" when this could mean strategic gateways or tactical driving;
- "rewrite the generator" when it is unclear whether existing semantic data contracts must remain compatible.

Inspect repo/history first. Ask only what remains unresolved.

## 5. Required pre-implementation checklist

For an approved code change:

1. Read current SOP/context/workflow.
2. Read the APPROVED system design.
3. Read master design if architecture/boundaries are involved.
4. Fetch current main SHA.
5. Inspect current owner module(s).
6. Inspect recovery/golden files when relevant.
7. State the system's public contract.
8. Declare files/modules expected to change.
9. Declare neighboring modules that must remain untouched.
10. Identify whether the public contract itself changes.
11. Fetch current blob SHAs for files being replaced.
12. Identify required subsystem and integration tests.

If no APPROVED system design exists for a major new system, do not code it. Draft/design it first.

## 6. Main/root rule

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
- tactical/strategic rendering;
- HUD/control rendering;
- camera/zoom math;
- generation;
- prefab logic;
- player movement/facing;
- collision/door rules;
- travel/extraction rules;
- art/atlas selection;
- persistence;
- ticks/calendar;
- lighting/perception/weather/sound;
- validation/quality rules;
- subsystem-specific DEV tools.

Never justify implementation in Main because it is temporary, easy, small, or only for development.

## 7. Replaceability test

Architecture is acceptable only if these remain plausible:

- delete/rewrite `generation/` without touching art/render/player/input/camera/strategic;
- delete/rewrite `render/` without touching generation/player physics/strategic state;
- replace `input/` without changing movement/simulation rules;
- replace `strategic/` without changing tactical generation;
- replace art mapping without changing physics;
- replace prefab DEV tooling without changing normal tactical renderer/generator contracts;
- add later lighting/perception/weather/sound without generator-specific presentation hacks.

When a feature requires edits on both sides of a contract, determine whether the contract needs an explicit approved revision. Do not silently make modules depend on each other's internals.

## 8. Semantic world-data boundary

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

## 9. Golden visual recovery

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

## 10. Design-document discipline

Detailed system rules belong under `SYSTEM_DESIGNS/`.

`README_CONTEXT.md` is a current-state routing index only.

`MODULAR_REBUILD_MASTER_DESIGN.md` owns global architecture/game direction.

`DESIGN_WORKFLOW.md` owns approval/scope/process.

### Approval status

- DRAFT = discussion only; no implementation.
- APPROVED = implementation allowed.
- IMPLEMENTED = approved design exists in canonical runtime and is tested.
- SUPERSEDED = historical only.

If implementation reveals the APPROVED design cannot work without crossing a forbidden boundary, return the design to DRAFT, explain the conflict, and get approval for the contract change.

## 11. No-placeholder / no-fake rule

Do not implement a substitute merely to satisfy the prompt.

Examples of unacceptable behavior:

- random placeholder values that silently become architecture;
- fake AI/event rolls presented as simulated actors;
- fake travel costs before travel/tick ownership exists;
- fake loot/search before inventory ownership exists;
- presentation erasure that hides invalid geometry;
- a temporary monolithic function intended to be "split later";
- calling an approximation the recovered original.

If the actual owning system is not designed yet, stop at a clean interface or defer the behavior explicitly.

## 12. Generator standards

Generator work begins only after the visual/data/player/input/map foundation is approved and verified.

Generator coordinator orchestrates modules; it is not a god script.

Expected separated owners include:

- biome/site rule catalog;
- road layout/topology;
- side roads/driveways;
- property planning;
- building/prefab selection;
- placement/transforms;
- room graph/layout;
- door planning/validation;
- fixtures;
- furniture;
- clutter;
- vegetation;
- utility networks;
- civic props;
- extraction placement;
- independent validation.

Avoid corrective pass chains that repeatedly delete/rebuild earlier generation output. Compose semantics intentionally, then validate.

## 13. Door/room quality rules

Current broad design direction:

- functional rooms normally at least 3x3 usable cells;
- public/storefront spaces often ~5x5–7x7;
- support rooms often ~3x3;
- fixtures/furniture must respect room use and circulation;
- clutter cannot block doors/critical paths;
- doors have authoritative wall axes;
- perpendicular approaches remain clear;
- same-axis wall neighbors remain structural;
- no doors at wall crosses/T-junctions.

If geometry fails, fix layout/ownership. Do not hide it visually or weaken tests just to turn CI green.

## 14. Performance/mobile rules

Phone/Safari is first-class.

- one physical touch = one semantic action;
- no hover-only interaction;
- synthetic mouse duplication must be handled by dedicated Safari/input owners;
- native text inputs should be used where Safari keyboard behavior matters;
- renderer should draw only visible cells;
- no idle full tactical redraw if nothing animated requires it;
- future animated overlays should use bounded redraw cadence and not force unrelated simulation recomputation;
- one zoom owner supplies canonical zoom values.

## 15. Reusable coding/GitHub lessons — living SOP

This section grows when repeated lessons are discovered.

### Godot/GDScript

- Be conservative with `:=` around `Dictionary`/`Variant`; explicit types/conversions avoid strict inference surprises.
- Keep data schemas/API names stable and test them as contracts.
- Avoid mutation inside draw functions.
- Prefer deterministic headless tests for generation/simulation.
- DEV UI is still a subsystem; do not hide it in Main.

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

### Living-SOP update rule

If a reusable lesson is discovered during a prompt, add it here in that same coherent prompt when it applies across systems.

If it belongs only to one subsystem, record it in that subsystem design instead.

Do not leave important lessons only in chat.

## 16. Validation rule

For documentation-only changes, preserve the currently deployed reference build and run the existing Pages gate if repository workflow triggers it.

For future modular code changes, exact final SHA must pass:

1. source/architecture checks;
2. Godot import/parse;
3. owning subsystem contract test(s);
4. relevant integration test(s);
5. real startup smoke;
6. Web export;
7. Pages deployment when live behavior changed.

Add one focused CI test per subsystem instead of one giant smoke script that knows every internal detail.

## 17. Communication rule

- Surface architectural concerns before coding.
- Explain when a user request is too broad and propose a smaller sequence.
- Do not be afraid to recommend a better architecture/process, but respect the user's final choice after explaining tradeoffs.
- Distinguish design, implementation, verified behavior, and future intent.
- Do not claim something was preserved/recovered unless inspection proves it.
- If clarification is needed, ask the smallest question that changes the decision.

## 18. Required final footer after repository changes

End repo-change responses with:

- Changelog: `https://github.com/dmcexcess-lab/dmcexcess-lab-tick-survival-lab/blob/main/CHANGELOG.md`
- Play: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

For design-only repository changes, make clear that the live play build is still the frozen/deprecated reference runtime.
