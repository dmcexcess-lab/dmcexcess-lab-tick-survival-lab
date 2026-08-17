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
- **07 Prop / Fixture / Vegetation Renderer — IMPLEMENTED + CI**
- **08 Player / Living Actor Renderer — IMPLEMENTED + CI**

## 3. Foundation and simulation truth

### WHERE

Global integer `Vector2i` cells, 1m planning scale, N/E/S/W facing, arbitrary whole-cell footprints, structure cells with explicit H/V axis. Geometry only.

### WHAT

One authoritative current persistent world with semantic terrain/entities, stable IDs, WHERE placements, derived occupancy, typed mechanic-agnostic change notifications, and deterministic snapshot/restore. Rendering reads WHAT; it does not own it. Mechanic state such as door openness remains in typed stable-ID domains outside `WorldEntityRecord`.

### WHEN

One deterministic non-negative integer world tick; variable-duration actions/events; same-tick batch drain; committed/resumable/cancelable interruption; tactical decision pause plus separate hard application pause.

### Collision / Movement / Locomotion

Collision owns hard occupancy, not door state. Movement owns forward/back/turn target/commit semantics with no destination reservation and typed policy decisions. Actor Locomotion owns standing/crouched state, timed stance changes, and future mobility-provider composition. Running remains deferred until it has real consequences.

### Door State

06A owns persistent OPEN/CLOSED truth keyed by stable WHAT door ID. Missing state is UNKNOWN. Door State does not infer from or mutate Collision/WHEN.

### Death / corpse direction

Approved cross-system direction: death leaves a persistent physical corpse/world consequence rather than an ordinary living ACTOR or disappearance. Future corpse state should preserve relation to deceased identity and support age/decay; accumulated bodies/decay may create local contamination/filth pressure that Health later interprets as sickness risk. Exact corpse representation, decay stages/formula, disposal actions and rendering are **NOT DESIGNED** yet.

## 4. Canonical presentation

### 04 Art Catalog — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/04_RECOVERED_MULTI_ATLAS_ART_CATALOG.md`.

Recovered environmental multi-atlas selection plus four protected player textures remain intact. 08 additively recovered a separate same-owner living-actor atlas (`game/assets/actor_atlas.svg`) with 8 survivor variants × four facings and 8 infected variants × four facings. Original ten Tick baseline art assets remain byte-identical; the actor source is separately pinned/provenanced. Art Catalog selects descriptors only.

### 05 Ground Layer Renderer — IMPLEMENTED

Standalone ground-only `Node2D`; visible WHAT terrain -> Art Catalog; local visible-window coordinates; event-driven redraw; recovered road/dirt-road/sidewalk topology; explicit diagnostics; no camera/generation/physics/input ownership.

### 06 Structure Layer Renderer — IMPLEMENTED

Visible WHAT `STRUCTURE` occupancy -> Art Catalog + Door State. Supports `wall.<theme>`, `door.<theme>`, `window.<theme>`, preserves H/V axis, uses distinct OPEN/CLOSED door art, and fails visibly for unknown state/content.

### 07 Prop / Fixture / Vegetation Renderer — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/07_PROP_FIXTURE_VEGETATION_RENDERER.md`.

Locked rules:

- reads WHAT `OBJECT` occupancy only + 04 Art Catalog;
- recognized families `prop.*`, `fixture.*`, `vegetation.*`;
- all recovered art delegates to `ArtCatalog.resolve_prop()`;
- multi-cell occupancy deduplicates to one draw command per stable entity;
- command retains anchor/facing/footprint/world cells;
- current recovered one-cell prop art draws once at physical anchor and is not auto-rotated;
- overlap is deterministic, not renderer-owned collision;
- visible-window only, lazy texture cache, event-driven redraw, no `_process()`.

### 08 Player / Living Actor Renderer — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/08_PLAYER_LIVING_ACTOR_RENDERER.md`.

Owners:

- `game/assets/actor_atlas.svg`
- `game/scripts/render/ActorDrawCommand.gd`
- `game/scripts/render/ActorLayerRenderer.gd`
- `game/scripts/ci/ActorLayerRendererSmoke.gd`
- `.github/workflows/actor-renderer.yml`

Locked rules:

- reads visible WHAT `ACTOR` occupancy only + 04 Art Catalog;
- exact living semantic types are `actor.survivor` and `actor.infected`;
- currently controlled actor is a stable-ID presentation/session role, not a permanent WHAT player type;
- controlled survivor uses exact protected N/E/S/W `player_*.svg` textures;
- NPC survivors/infected use separately recovered same-owner actor atlas;
- NPC default variant uses explicit deterministic 32-bit FNV-1a of stable actor ID modulo 8; this is presentation default only until persistent Actor Appearance exists;
- recovered NPC art is centered at 29/32 of a visible cell, matching solved First Fire presentation;
- no fake crouch visual; 03 stance remains simulation truth and 08 does not require locomotion state;
- arbitrary ACTOR footprints deduplicate to one base actor draw while preserving physical footprint/world cells;
- overlap order is deterministic, not collision legality;
- actual ACTOR-channel placement drives redraw relevance; semantic text alone on OBJECT/other channels does not;
- no `_process()` polling;
- no AI/Health/Inventory/Corpse/Collision/Movement/WHEN/generation/reboot/camera/input/UI ownership.

Implementation began at `77f2a86e964bef9128fd2b52a0799d46c146601e`; a CI-only protected-hash literal correction produced code head `c37be260e273e70a2bb2f5a91261d99a8a5cb898`. Dedicated actor run `31985099706` and Art Catalog run `31985099764` passed there.

## 5. Graphics recovery status

Canonical graphics now include:

1. recovered multi-atlas semantic art selection;
2. actual Ground drawing;
3. actual wall/door/window Structure drawing with persistent Door State;
4. actual Prop/Fixture/Vegetation drawing from persistent OBJECT entities;
5. actual controlled survivor + NPC survivor + infected drawing from persistent living ACTOR entities.

The focused visual layer owners now exist. Visible full-scene canonical recovery is still incomplete because an approved composition/test-area path and camera do not yet exist.

The deployed Web page still intentionally runs the frozen reboot reference. Do not claim it demonstrates canonical 05/06/07/08 until the new presentation stack has an approved composition path.

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
17. Physical WHAT footprints/facing remain world truth; presentation-specific large-object geometry/orientation must be explicit rather than inferred from physics.
18. Controlled-player role is not persistent actor identity; living actor rendering reads ordinary stable WHAT actor entities.
19. Corpses are persistent future world/mechanic consequences, not living ACTOR presentation state.

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
11. golden/same-owner history for recovered behavior.

## 9. Recommended next bounded design

**Authored Visual Test Area** is the recommended next presentation discussion.

Why next: Ground, Structure, Prop and Living Actor focused renderers now all exist independently. A small authored canonical WHAT scene can prove them together without dragging procedural generation into presentation recovery. The test-area/composition boundary must remain explicit: no fake generator, no reboot adapter, no camera/input ownership hidden in the fixture.

Keep Tactical renderer/orchestration, camera/zoom, touch/keyboard/Safari input, tactical controls UI, loose items, vehicles, corpse/decay, Actor Appearance/equipment presentation, and Door Interaction as separate approved systems.
