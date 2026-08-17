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
- **06A Door State — IMPLEMENTED + CI**
- **06 Structure Layer Renderer — IMPLEMENTED + CI**
- **07 Prop / Fixture / Vegetation Renderer — DRAFT; active design review**

## 3. Foundation and simulation truth

### WHERE

Global integer `Vector2i` cells, 1m planning scale, N/E/S/W facing, arbitrary whole-cell footprints, structure cells with explicit H/V axis. Geometry only.

### WHAT

One authoritative current persistent world with semantic terrain/entities, stable IDs, WHERE placements, derived occupancy, typed mechanic-agnostic change notifications, and deterministic snapshot/restore. Rendering reads WHAT; it does not own it. Mechanic state such as door openness remains in typed stable-ID domains outside `WorldEntityRecord`.

### WHEN

One deterministic non-negative integer world tick; variable-duration actions/events; same-tick batch drain; committed/resumable/cancelable interruption; tactical decision pause plus separate hard application pause.

### Collision / Movement / Locomotion

Collision owns hard occupancy, not door state. Movement owns forward/back/turn target/commit semantics with no destination reservation and typed policy decisions. Actor Locomotion owns standing/crouched state, timed stance changes, and future mobility-provider composition. Running remains deferred until it has real consequences.

### 06A Door State — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/06A_DOOR_STATE.md`.

Owners:

- `game/scripts/simulation/doors/DoorStateValue.gd`
- `DoorStateRecord.gd`
- `DoorStateStore.gd`
- `DoorStateMutationService.gd`
- `game/scripts/ci/DoorStateSmoke.gd`
- `.github/workflows/door-state.yml`

Locked rules:

- stable WHAT door ID -> explicit OPEN / CLOSED persistent state;
- missing record -> UNKNOWN, never implicit CLOSED;
- no default initial enrollment state;
- mutation-safe records with per-door stale-action versions;
- deterministic atomic snapshot/restore + store revision;
- explicit lifecycle cleanup; unplaced doors may retain state;
- normal writes validate WHAT door identity where applicable;
- no Collision, WHEN, renderer, interaction, AI, sound, lock, or generation ownership.

## 4. Canonical presentation

### 04 Recovered Multi-Atlas Art Catalog — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/04_RECOVERED_MULTI_ATLAS_ART_CATALOG.md`.

Six preserved atlas families + four player sprites; protected baseline assets; recovered ground/wall/prop precedence; themed doors/windows; road topology; directional player mapping; explicit UNKNOWN behavior. Art Catalog selects descriptors only.

### 05 Ground Layer Renderer — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/05_GROUND_LAYER_RENDERER.md`.

Standalone ground-only `Node2D`; read-only WHAT terrain + Art Catalog; supplied visible global-cell window; local draw coordinates; deterministic visible-only planning; event-driven redraw; recovered road/dirt-road/sidewalk topology; explicit diagnostics; lazy texture cache; no camera/generation/physics/input ownership.

### 06 Structure Layer Renderer — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/06_STRUCTURE_LAYER_RENDERER.md`.

Owners:

- `game/scripts/render/StructureDrawCommand.gd`
- `StructureLayerRenderer.gd`
- `game/scripts/ci/StructureLayerRendererSmoke.gd`
- `.github/workflows/structure-renderer.yml`

Locked rules:

- visible WHAT `STRUCTURE` occupancy only;
- semantic `wall.<theme>` / `door.<theme>` / `window.<theme>` categories;
- valid canonical H/V structure axis required and retained;
- current golden wall/opening art is not rotated solely by axis;
- walls/windows resolve through 04 Art Catalog;
- doors read 06A Door State: OPEN and CLOSED use distinct recovered art; UNKNOWN is diagnostic;
- no Collision-as-door-truth shortcut;
- fail-visible overlap/axis/category/theme/state/texture problems;
- visible-window local coordinates, cached textures, event-driven redraw;
- terrain and initial non-structure changes do not redraw Structure;
- no generator/reboot/camera/input/WHEN/Collision ownership.

### 07 Prop / Fixture / Vegetation Renderer — ACTIVE DRAFT

Canonical draft: `SYSTEM_DESIGNS/07_PROP_FIXTURE_VEGETATION_RENDERER.md`.

Proposed locked boundary for review:

- consumes WHAT `OBJECT` occupancy only + 04 Art Catalog;
- semantic families `prop.*`, `fixture.*`, `vegetation.*`;
- all art delegates to `ArtCatalog.resolve_prop()` and preserves final -> alias -> building -> clutter -> tactical precedence;
- multi-cell occupancy deduplicates to one draw command per stable entity;
- command preserves anchor, facing, and footprint/world cells;
- current recovered one-cell art draws once at the entity anchor rather than repeating or stretching across the physical footprint;
- current recovered prop art remains unrotated because golden `draw_prop()` defined no native facing/rotation convention; facing is preserved for a future explicit presentation orientation policy;
- overlapping OBJECT occupants draw deterministically rather than becoming renderer-owned collision errors;
- fail-visible semantic/art/placement/texture diagnostics;
- visible-window only, cached textures, event-driven redraw;
- no Collision/WHEN/generation/inventory/state/camera/input/reboot ownership.

Runtime implementation is blocked until explicit approval of the 07 draft.

## 5. Graphics recovery status

Canonical graphics now include:

1. recovered multi-atlas semantic art selection;
2. actual Ground drawing;
3. actual wall/door/window Structure drawing with persistent Door State.

Prop/Fixture/Vegetation is the active next draft. Visible full-scene recovery is still incomplete because 07, Player/Actor, composition/test-area, and camera systems do not yet all exist canonically.

The deployed Web page still intentionally runs the frozen reboot reference. Do not claim it demonstrates canonical 05/06/07 until the new presentation stack has an approved composition path.

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
3. One major system per implementation slice by default; tightly coupled prerequisite + dependent work may be explicitly authorized together by the user.
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

**Review/approve `07_PROP_FIXTURE_VEGETATION_RENDERER.md`.**

If approved, implement the Prop renderer with its own Godot 4.7.1 contract and regress Art Catalog + Ground + Structure on the exact implementation/final SHA.

Keep Player/Actor Renderer, Tactical composition, Authored Visual Test Area, camera/zoom, loose-item rendering, stateful fixture visuals, vehicles, and door interaction/physical transition as separate approved systems.
