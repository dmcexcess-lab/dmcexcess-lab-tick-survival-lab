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

## 3. Foundation and movement truth

### WHERE

Global integer `Vector2i` cells, 1m planning scale, N/E/S/W facing, arbitrary whole-cell footprints, structure cells with explicit H/V axis. Geometry only.

### WHAT

One authoritative current persistent world with semantic terrain/entities, stable IDs, WHERE placements, derived occupancy, typed mechanic-agnostic change notifications, and deterministic snapshot/restore. Rendering reads WHAT; it does not own it.

### WHEN

One deterministic non-negative integer world tick; variable-duration actions/events; same-tick batch drain; committed/resumable/cancelable interruption; tactical decision pause plus separate hard application pause.

### Collision / Movement / Locomotion

Collision owns hard occupancy. Movement owns forward/back/turn target/commit semantics with no destination reservation and typed policy decisions. Actor Locomotion owns standing/crouched state, timed stance changes, and future mobility-provider composition. Running remains deferred until it has real consequences.

## 4. Canonical presentation

### 04 Recovered Multi-Atlas Art Catalog — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/04_RECOVERED_MULTI_ATLAS_ART_CATALOG.md`.

Recovered exact semantic selection from golden `TacticalTiles.gd`:

- six preserved atlas families + four player sprites;
- protected byte-identical baseline assets;
- 32x32 / 16-column atlas math;
- final/world/tactical ground and wall precedence;
- complete final/building/clutter/tactical prop vocabulary;
- themed doors/windows;
- road/dirt-road/sidewalk topology;
- N/E/S/W player sprite mapping;
- typed UNKNOWN for missing semantic art rather than silent plausible fallback.

Art Catalog selects descriptors only and reads no world/generator/physics state.

### 05 Ground Layer Renderer — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/05_GROUND_LAYER_RENDERER.md`.

Owners:

- `game/scripts/render/GroundDrawCommand.gd`
- `game/scripts/render/GroundLayerRenderer.gd`
- `game/scripts/ci/GroundLayerRendererSmoke.gd`
- `.github/workflows/ground-renderer.yml`

Locked rules:

- standalone `Node2D` ground-only presentation owner;
- dependencies are read-only WHAT terrain + 04 Art Catalog;
- caller supplies global visible origin, whole-cell visible size, and display cell pixels;
- destination coordinates are local to visible origin, supporting large/negative global positions;
- deterministic row-major command planning;
- no `_process()` redraw loop or full-world scan;
- ordinary semantic terrain delegates directly to Art Catalog;
- generic `road`, `dirt_road`, `sidewalk` derive cardinal display topology from neighboring semantic terrain;
- paved and dirt roads share connectivity; explicit road variants remain literal;
- generic road class stays local/default until a real Road system owns richer classification;
- missing/unknown/unloadable ground is visibly diagnostic, never silently replaced;
- textures lazy-load/cache solely from ArtSelection descriptors;
- redraw only on configuration/view/world reset or terrain changes in the visible window/cardinal one-cell topology halo;
- non-terrain, distant, and diagonal-only offscreen changes do not redraw Ground.

The dedicated Godot 4.7.1 contract passed the implementation head without production repair and includes an Art Catalog regression smoke.

## 5. Graphics recovery status

The **art selection + first actual ground drawing layer are now canonical**. The preserved art files themselves were never lost; the old visual regression came from losing the mature semantic selection/render path.

Visible full-scene recovery is **not yet complete** because canonical Structure, Prop, Actor and composition/test-area systems do not exist yet. The deployed Web page still intentionally runs the frozen reboot reference.

Do not claim the current Web preview demonstrates 05 until the canonical presentation layers have a real approved composition path.

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
15. Camera/viewport owns visible-window calculation; Ground renderer only consumes it.

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

## 9. Recommended next bounded design

**Structure Layer Renderer** is the recommended next discussion target, not automatic authorization to code it.

Why next: Ground now proves the canonical WHAT -> Art Catalog -> CanvasItem path. Structure can add walls/doors/windows using the already locked structure-cell/axis geometry and recovered opening art without mixing in props, actors, camera, input, lighting, or generation.

Keep Structure, Prop/Fixture/Vegetation, Player/Actor, Tactical composition, and Authored Visual Test Area as separately approved systems.
