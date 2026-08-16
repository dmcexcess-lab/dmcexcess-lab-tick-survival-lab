# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, and the active system design(s). Read `MODULAR_REBUILD_MASTER_DESIGN.md` for architecture work, but newer North Star/decision entries win where older assumptions conflict.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle:

> **Mini means reduced complexity, not reduced consequence or mood.**

Current game direction:

- one persistent logically continuous open world;
- no raid/extraction/staging loop;
- player-built/secured bases anywhere ordinary world rules permit;
- causal outbreak/population simulation goal;
- customizable player story embedded in the pre-collapse world;
- authoritative invisible tactical grid;
- variable-duration turn-based tick/actions with mandatory real-life hard pause;
- mood driven by future vision, lighting, weather, sound and persistent consequences.

Canonical identity: `PROJECT_NORTH_STAR.md`.

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

## 2. Current architectural phase

The project is in **Phase 1: modular foundation implementation**.

The currently deployed runtime under `game/scripts/reboot/` remains **frozen/deprecated reference code**. Do not extend it as the target architecture.

Golden recovery commit for mature pre-clean-rewrite behavior/art:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

Canonical modular foundation progress:

- **00A WHERE / Spatial Model — IMPLEMENTED and CI-gated** under `game/scripts/foundation/spatial/`.
- **00B WHAT / Persistent World State — IMPLEMENTED and CI-gated** under `game/scripts/foundation/world/`.
- **00C WHEN / Tick Action Pause — next bounded design/implementation target; not yet implemented.**

The live playable scene does not import the new foundation yet. This is intentional: no temporary adapter layer will connect canonical foundation modules to the deprecated runtime merely to make new code visibly run.

## 3. Foundation architecture

Canonical umbrella:

`SYSTEM_DESIGNS/00_FOUNDATION_WHERE_WHAT_WHEN.md`

The three peer truths are:

- **WHERE — Spatial Model:** where things can exist and how cells, facing, footprints and structure geometry are expressed.
- **WHAT — Persistent World / Entity State:** what terrain, structures, objects, actors, items and durable mutations exist.
- **WHEN — Tick / Action / Pause Kernel:** when actions/events occur and how simulation time advances.

Generation is downstream: it creates initial WHAT using WHERE. Construction/destruction/gameplay later mutate WHAT. Gameplay systems bridge WHERE/WHAT with WHEN. Rendering only presents state.

### 00A WHERE — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/00A_SPATIAL_MODEL.md`.

Implemented owners:

- `game/scripts/foundation/spatial/SpatialFacing.gd`
- `game/scripts/foundation/spatial/SpatialFootprint.gd`
- `game/scripts/foundation/spatial/SpatialStructureGeometry.gd`
- `game/scripts/foundation/spatial/SpatialLayer.gd`
- `game/scripts/foundation/spatial/SpatialModel.gd`
- test: `game/scripts/ci/SpatialModelSmoke.gd`

Locked spatial rules:

- global integer `Vector2i` cells;
- N/E/S/W semantic facing;
- whole-cell arbitrary-mask footprints with deterministic 90-degree rotation;
- centralized planning scale `SpatialModel.CELL_METERS = 1.0`;
- structure cells rather than edge walls;
- explicit HORIZONTAL/VERTICAL structure axis;
- no sub-cell/free movement baseline;
- WHERE owns geometry only, no occupants/world state/collision policy/rendering/timing/generation.

### 00B WHAT — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/00B_PERSISTENT_WORLD_STATE.md`.

Implemented owners:

- `game/scripts/foundation/world/WorldEntityId.gd`
- `game/scripts/foundation/world/WorldEntityRecord.gd`
- `game/scripts/foundation/world/WorldPlacement.gd`
- `game/scripts/foundation/world/TerrainStore.gd`
- `game/scripts/foundation/world/EntityStore.gd`
- `game/scripts/foundation/world/PlacementStore.gd`
- `game/scripts/foundation/world/OccupancyIndex.gd`
- `game/scripts/foundation/world/WorldChange.gd`
- `game/scripts/foundation/world/WorldState.gd`
- `game/scripts/foundation/world/WorldMutationService.gd`
- test: `game/scripts/ci/WorldStateSmoke.gd`

Locked WHAT rules:

- one authoritative current persistent world, not parallel generated/current gameplay realities;
- stable opaque string entity IDs independent of Godot Nodes and store ordering;
- semantic entity types; no art indices and no generic metadata junk drawer;
- entities may persist without a tactical placement;
- terrain is a primary semantic cell fact;
- placed entities use WHERE channel + anchor + facing + footprint + optional structure axis;
- occupancy is a derived acceleration index, never source of truth;
- WHAT does not invent overlap/collision legality;
- normal writes go through `WorldMutationService`; public reads return mutation-safe copies;
- every successful foundation mutation advances revision and emits typed mechanic-agnostic change data;
- snapshot/restore is deterministic and atomic, rebuilds derived occupancy, and is an in-memory state boundary rather than the final save-file implementation;
- WHAT has no generator, renderer, streaming, tick/action, health, inventory, AI, construction or reboot dependency.

### 00C WHEN — NOT YET APPROVED FOR CODE

Umbrella draft covers integer world ticks, variable-duration actions, scheduled events, phases/interruption, deterministic ordering, tactical auto-pause, hard real-life pause and coarse distant simulation seams.

Before implementation, create/refine a standalone `00C_TICK_ACTION_PAUSE.md`, recover useful golden `TickScheduler.gd` behavior deliberately, review it against implemented WHERE/WHAT, and get explicit bounded approval.

## 4. Open-world / generation direction

Generation is not the engine and must not define reality by chunk boundaries.

Long-term top-down planning:

**world seed -> geography -> towns/rural districts -> roads -> utilities -> parcels/addresses -> building footprints/types -> households/businesses/population -> local detail/materialization**.

Roads, utilities, rivers, parcels and other cross-region structures are planned in global coordinates before streaming/materialization. A local region may load part of a road; it does not invent how that road connects.

Generation will create ordinary semantic terrain/entities through WHAT using WHERE. Once they exist, the same current persistent world owns later changes. Replacing generation must not reset looted containers, destroyed structures, construction, vehicles, corpses or other durable state.

## 5. Outbreak / player-story direction

The long-term world should support a populated pre-collapse state with persistent people, households, homes, jobs/workplaces, schedules, vehicles and relationships, then simulate outbreak/collapse causally.

WHAT's stable identity model intentionally allows a person to remain the same persistent actor whether tactically placed nearby, temporarily unplaced, or later represented by a coarse distant simulation system.

Distant simulation may use coarser deterministic resolution for performance while preserving causal persistent state.

The player should eventually customize/inhabit a real person already embedded in that world: identity, occupation/workplace, home/property, family/household, relationships, pets, vehicle/resources, traits/skills and outbreak start circumstances.

## 6. Base direction

A base is not a special map or required mode.

The player may build/secure one or many locations anywhere normal construction/occupancy rules permit, abandon them, relocate, or live nomadically. Any later base/community UI must summarize underlying physical world facts rather than create a separate base reality.

WHAT contains no privileged `BaseMap`/base-region truth. Future construction/storage/power/water/community systems attach ordinary typed state to persistent entities and locations.

## 7. Graphics recovery truth

The richer pre-rewrite artwork remains intact. The mature look came from golden `TacticalTiles.gd` combining six atlases plus four directional player sprites.

Golden semantic renderer blob:

`3d8a0a70ac983408bb48f58fc659dfb07e216ed3`

Rendering is not being rebuilt in these foundation slices. When designed, it must consume WHERE/WHAT and recover exact semantic art behavior rather than approximate it.

## 8. Development process / anti-drift rules

Canonical process:

> **DESCRIBE -> USER APPROVES -> IMPLEMENT -> VERIFY.**

Global invariants:

1. Main/root is composition/wiring only.
2. Every independently replaceable system has a focused owner/public contract.
3. One major system per implementation slice by default.
4. Push back when scope spans too many systems.
5. No placeholder/fake systems presented as complete.
6. Ask targeted clarification when material ambiguity remains after inspection.
7. Generator is an input to world state, not owner of persistent reality.
8. Rendering never owns simulation truth.
9. Input requests actions; it does not implement world rules.
10. Art is not physics.
11. Phone/Safari remains first-class.
12. Important decisions/lessons do not live only in chat.
13. Do not wire new modules into deprecated runtime through temporary compatibility code merely to make progress visible.
14. Persistent-world mechanics should attach typed state through stable entity IDs rather than expanding `WorldEntityRecord` into a generic metadata bag.

## 9. Documentation ownership

- `PROJECT_NORTH_STAR.md` — game identity/philosophy.
- `DESIGN_DECISIONS.md` — cross-system settled decisions and rationale.
- `README_CONTEXT.md` — current phase/status/routing only.
- `README_SOPS.md` — coding/GitHub/Godot/Safari process lessons.
- `DESIGN_WORKFLOW.md` — approval/scope workflow.
- `SYSTEM_DESIGNS/*.md` — detailed subsystem contracts.
- `SYSTEM_DESIGNS/README.md` — approval/status ledger.
- `MODULAR_REBUILD_MASTER_DESIGN.md` — broad historical architecture inventory; newer docs supersede stale raid/extraction assumptions.
- `CHANGELOG.md` — repository change history.

## 10. Source-of-truth order

1. Newest explicit user instruction
2. `PROJECT_NORTH_STAR.md`
3. `DESIGN_DECISIONS.md`
4. Current repository state
5. `README_SOPS.md`
6. `DESIGN_WORKFLOW.md`
7. This context index
8. IMPLEMENTED/APPROVED active `SYSTEM_DESIGNS/*.md`
9. DRAFT system designs for current discussion only
10. `MODULAR_REBUILD_MASTER_DESIGN.md` where compatible
11. Golden recovery commit for historical behavior

## 11. Current next action

**Do not jump to generation or rendering.**

Next recommended bounded target: **00C WHEN — Tick / Action / Pause Kernel**. First refine the umbrella timing design into a standalone child design against the now-implemented WHERE and WHAT contracts, then obtain explicit approval before coding it.
