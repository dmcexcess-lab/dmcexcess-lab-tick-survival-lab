# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, and the active system design(s). Read `MODULAR_REBUILD_MASTER_DESIGN.md` where architecture/global direction matters; newer North Star/decision entries win over stale assumptions.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle:

> **Mini means reduced complexity, not reduced consequence or mood.**

Current direction: one persistent logically continuous open world, invisible tactical grid, variable-duration turn-based actions, hard real-life pause, emergent physical bases, causal outbreak/population simulation, embedded player story, and recovered readable top-down graphics.

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

## 2. Current architectural phase

The project is in staged modular replacement of the deprecated playable runtime.

`game/scripts/reboot/` is **frozen/deprecated reference code**. Do not extend it or add temporary adapters just to make canonical systems appear in the old playable build.

Golden recovery commit:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

Golden mature `TacticalTiles.gd` blob:

`3d8a0a70ac983408bb48f58fc659dfb07e216ed3`

Canonical progress:

- **00A WHERE / Spatial Model — IMPLEMENTED + CI**
- **00B WHAT / Persistent World State — IMPLEMENTED + CI**
- **00C WHEN / Tick Action Pause — IMPLEMENTED + CI**
- **01 Collision / Spatial Query — IMPLEMENTED + CI**
- **02 Movement Actions — IMPLEMENTED + CI**
- **03 Actor Locomotion State & Movement Capability — IMPLEMENTED + CI**
- **04 Recovered Multi-Atlas Art Catalog — IMPLEMENTED + CI**
- **05 Ground Layer Renderer — IMPLEMENTED + CI**
- **06A Door State — DRAFT; prerequisite concept approved, detailed contract awaiting approval**
- **06 Structure Layer Renderer — DRAFT / BLOCKED until 06A is implemented**

## 3. Foundation and movement truth

### WHERE

Global integer `Vector2i` cells, 1m planning scale, N/E/S/W facing, arbitrary whole-cell footprints, structure cells with explicit H/V axis. Geometry only.

### WHAT

One authoritative current persistent world with semantic terrain/entities, stable IDs, WHERE placements, derived occupancy, typed mechanic-agnostic change notifications, and deterministic snapshot/restore. Rendering reads WHAT; it does not own it. Mechanic state such as door openness remains in typed stable-ID domains outside `WorldEntityRecord`.

### WHEN

One deterministic non-negative integer world tick; variable-duration actions/events; same-tick batch drain; committed/resumable/cancelable interruption; tactical decision pause plus separate hard application pause.

### Collision / Movement / Locomotion

Collision owns hard occupancy, not door state. Movement owns forward/back/turn target/commit semantics with no destination reservation and typed policy decisions. Actor Locomotion owns standing/crouched state, timed stance changes, and future mobility-provider composition. Running remains deferred until it has real consequences.

## 4. Canonical presentation

### 04 Recovered Multi-Atlas Art Catalog — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/04_RECOVERED_MULTI_ATLAS_ART_CATALOG.md`.

Recovered exact semantic selection from golden `TacticalTiles.gd`: six preserved atlas families + four player sprites; protected baseline assets; atlas math; rich ground/wall/prop precedence; themed doors/windows; road topology; directional player mapping; explicit UNKNOWN behavior.

Art Catalog selects descriptors only and reads no world/generator/physics state.

### 05 Ground Layer Renderer — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/05_GROUND_LAYER_RENDERER.md`.

Locked rules include: standalone ground-only `Node2D`; read-only WHAT terrain + Art Catalog; supplied visible global-cell window; local draw coordinates; deterministic visible-only planning; event-driven redraw; recovered road/dirt-road/sidewalk topology; explicit diagnostics; lazy texture cache; no camera/generation/physics/input ownership.

### 06 Structure Layer Renderer — DRAFT / BLOCKED

Canonical draft: `SYSTEM_DESIGNS/06_STRUCTURE_LAYER_RENDERER.md`.

Structure will render visible WHAT `STRUCTURE` occupants (`wall.<theme>`, `door.<theme>`, `window.<theme>`) through Art Catalog while preserving canonical H/V structure axis. Correct door rendering requires authoritative OPEN/CLOSED state and must never infer openness from Collision or assume CLOSED when missing.

### 06A Door State — current active design

Canonical draft: `SYSTEM_DESIGNS/06A_DOOR_STATE.md`.

Prerequisite concept approved by the user. Detailed design currently proposes:

- stable WHAT door ID -> explicit OPEN / CLOSED state;
- missing record -> UNKNOWN, never implicit CLOSED;
- explicit initial enrollment with no default state;
- mutation-safe records with per-door versions;
- deterministic snapshot/restore and store revision;
- change/reset signals for event-driven consumers;
- normal validated writes through a Door State mutation service;
- no Collision, WHEN, renderer, generation, input, AI, sound, perception, lock, or interaction ownership.

The detailed 06A contract still needs explicit approval before runtime implementation.

## 5. Graphics recovery status

The **art selection + canonical ground drawing layer are implemented**. The preserved art files themselves were never lost; the old visual regression came from losing the mature semantic selection/render path.

Full visible-scene recovery is not complete because Structure, Prop, Actor, composition/test-area, and camera systems are not all implemented. Structure is intentionally waiting for real Door State rather than using a visual shortcut.

The deployed Web page still intentionally runs the frozen reboot reference. Do not claim it demonstrates canonical 05/06 until the canonical presentation layers have an approved composition path.

## 6. Open-world/generation direction

Generation is not the engine and streaming partitions never define logical reality.

Long-term planning order:

**world seed -> geography -> towns/rural districts -> roads -> utilities -> parcels/addresses -> building footprints/types -> households/businesses/population -> local detail/materialization**.

Cross-region facts are planned globally. Once world facts exist, persistent WHAT owns later mutations.

## 7. Development invariants

Canonical process:

> **DESCRIBE -> USER APPROVES -> IMPLEMENT -> VERIFY.**

Key rules:

1. Main/root is composition only.
2. One independently replaceable system = focused owner/public contract.
3. One major system per implementation slice by default.
4. No placeholder/fake completion.
5. Generator creates initial WHAT; it does not own persistent reality.
6. Rendering presents world truth; it does not become simulation truth.
7. Input emits semantic intent; it does not implement mechanics.
8. Art is not physics.
9. Phone/Safari is first-class.
10. Do not wire canonical modules into deprecated reboot through temporary adapters.
11. Persistent mechanic state uses typed stable-ID domain stores rather than a universal metadata bag.
12. Gameplay durations/order use WHEN while mechanic meanings remain external.
13. World/generator data never stores atlas indices or texture paths.
14. Render layers consume semantic world facts through 04 Art Catalog.
15. Camera/viewport owns visible-window calculation; focused renderers only consume it.
16. Door State owns door OPEN/CLOSED truth; Collision owns blocking truth; neither infers the other.

## 8. Documentation source order

1. newest explicit user instruction;
2. `PROJECT_NORTH_STAR.md`;
3. `DESIGN_DECISIONS.md`;
4. current repository state;
5. `README_SOPS.md`;
6. `DESIGN_WORKFLOW.md`;
7. this context index;
8. IMPLEMENTED/APPROVED `SYSTEM_DESIGNS/*.md`;
9. current DRAFT designs;
10. compatible master-design material;
11. golden history for recovered behavior.

## 9. Recommended next bounded step

**Review/approve the detailed 06A Door State contract.**

If approved, implement and independently verify 06A first. Then return immediately to `06_STRUCTURE_LAYER_RENDERER.md`, update its prerequisite from blocked to satisfied, obtain/confirm Structure implementation approval, and code the renderer.

Do not skip directly to Structure by assuming all doors are closed or by reading collision overrides as door state.
