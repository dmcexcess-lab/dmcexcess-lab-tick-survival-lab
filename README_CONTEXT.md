# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, and the active system design(s). Read `MODULAR_REBUILD_MASTER_DESIGN.md` for architecture work, but newer North Star/decision entries win where older assumptions conflict.

## 1. Game identity

> **Ultima-style turn-based mini Zomboid.**

Core principle:

> **Mini means reduced complexity, not reduced consequence or mood.**

Current direction:

- one persistent logically continuous open world;
- no raid/extraction/staging loop;
- player-built/secured bases anywhere ordinary world rules permit;
- causal outbreak/population simulation goal;
- customizable player story embedded in the pre-collapse world;
- authoritative invisible tactical grid;
- variable-duration turn-based tick/actions with mandatory real-life hard pause;
- mood driven by future vision, lighting, weather, silent spatial sound and persistent consequences.

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Canonical identity: `PROJECT_NORTH_STAR.md`.

## 2. Current architectural phase

The project is in staged modular replacement of the deprecated playable runtime.

The live `game/scripts/reboot/` runtime is **frozen/deprecated reference code**. Do not extend it as the target architecture and do not add temporary adapters merely to make canonical modules visibly affect the old build.

Golden recovery commit for mature pre-clean-rewrite behavior/art:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

Canonical modular progress:

- **00A WHERE / Spatial Model — IMPLEMENTED and CI-gated** under `game/scripts/foundation/spatial/`.
- **00B WHAT / Persistent World State — IMPLEMENTED and CI-gated** under `game/scripts/foundation/world/`.
- **00C WHEN / Tick Action Pause — IMPLEMENTED and CI-gated** under `game/scripts/foundation/time/`.
- **01 Collision / Spatial Query — IMPLEMENTED and CI-gated** under `game/scripts/simulation/collision/`.
- **02 Movement Actions — IMPLEMENTED and CI-gated** under `game/scripts/simulation/movement/`.

The new canonical modules are intentionally tested independently beside the frozen playable reference until enough neighboring canonical systems exist for real composition.

## 3. Foundation architecture

Canonical umbrella: `SYSTEM_DESIGNS/00_FOUNDATION_WHERE_WHAT_WHEN.md`.

The peer truths are:

- **WHERE — Spatial Model:** where things can exist and how cells, facing, footprints and structure geometry are expressed.
- **WHAT — Persistent World / Entity State:** what terrain, structures, objects, actors, items and durable mutations exist.
- **WHEN — Tick / Action / Pause Kernel:** when actions/events occur and how simulation time advances.

Generation creates initial WHAT using WHERE. Gameplay systems bridge WHERE/WHAT with WHEN. Rendering only presents state.

### 00A WHERE — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/00A_SPATIAL_MODEL.md`.

Locked rules include global integer `Vector2i` cells, N/E/S/W facing, arbitrary whole-cell footprints, centralized `SpatialModel.CELL_METERS = 1.0`, structure cells with explicit HORIZONTAL/VERTICAL axis, and no sub-cell/free movement baseline.

### 00B WHAT — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/00B_PERSISTENT_WORLD_STATE.md`.

Locked rules include one authoritative persistent world, stable opaque string entity IDs, semantic terrain/entity types, WHERE-based placements, derived occupancy, validated mutation through `WorldMutationService`, mutation-safe reads, revision/change events, and deterministic atomic snapshot/restore.

### 00C WHEN — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/00C_TICK_ACTION_PAUSE.md`.

Locked rules include one integer world tick, deterministic scheduled work, variable-duration concurrent actor actions, semantic phases, COMMITTED/RESUMABLE/CANCELABLE interruption policy, decision auto-pause, hard application pause, same-tick batch draining, and deterministic snapshot/restore.

### 01 Collision / Spatial Query — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/01_COLLISION_SPATIAL_QUERY.md`.

Locked rules:

- hard movement collision is explicit physics, never inferred from art;
- normal behavior is type-level through `CollisionCatalog`;
- dynamic exceptions use sparse stable-ID overrides;
- STRUCTURE / OBJECT / ACTOR placements require explicit classification;
- missing classification or terrain is UNKNOWN/fail-closed;
- queries support arbitrary rotated multi-cell footprints and self-ignore;
- terrain traversal capability remains outside collision.

### 02 Movement Actions — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/02_MOVEMENT_ACTIONS.md`.

Implemented owners:

- `game/scripts/simulation/movement/MovementActionResult.gd`
- `game/scripts/simulation/movement/MovementTraversalPolicy.gd`
- `game/scripts/simulation/movement/MovementActionService.gd`
- `game/scripts/ci/MovementActionsSmoke.gd`
- `.github/workflows/movement.yml`

Locked movement rules:

- initial vocabulary is forward, backward, turn left and turn right;
- no diagonal movement or strafing in this slice;
- movement validates at request time, spends its WHEN duration, then revalidates at `movement.commit` before WHAT mutation;
- target cells are **not reserved**; if another actor/object occupies the destination before commit, the move fails after spending its time;
- a stale action cannot overwrite a placement changed by another mechanic while the action was pending;
- backward movement preserves facing;
- turns query the fully rotated footprint, including multi-cell actors;
- terrain traversal and base movement duration are supplied through a replaceable movement policy, separate from collision and WHEN;
- basic step/turn actions are COMMITTED; hard application pause still freezes them with zero hidden time advancement;
- pending movement facts live in WHEN's serializable action payload rather than a second hidden movement-state store.

## 4. Open-world / generation direction

Generation is not the engine and must not define reality by streaming boundaries.

Long-term planning order:

**world seed -> geography -> towns/rural districts -> roads -> utilities -> parcels/addresses -> building footprints/types -> households/businesses/population -> local detail/materialization**.

Roads, utilities, rivers, parcels and other cross-region structures are planned in global coordinates before local materialization. Once facts exist, the same persistent WHAT owns subsequent changes.

## 5. Outbreak / player-story direction

The long-term world supports a populated pre-collapse state with persistent people, households, homes, jobs/workplaces, schedules, vehicles and relationships, then simulates outbreak/collapse causally.

Distant actors/populations may use coarser deterministic simulation while preserving causal persistent state. The playable survivor eventually inhabits a real generated-world person with identity, occupation/workplace, home/property, family/household, relationships, pets, vehicle/resources and starting circumstances where applicable.

## 6. Base direction

A base is not a special map or required mode. The player may build/secure one or many locations anywhere normal construction/occupancy rules permit, relocate, abandon them, or live nomadically. Any later base/community UI summarizes underlying physical facts rather than creating a separate base reality.

## 7. Graphics recovery truth

The richer pre-rewrite artwork remains intact. The mature look came from golden `TacticalTiles.gd` combining six atlases plus four directional player sprites.

Golden semantic renderer blob: `3d8a0a70ac983408bb48f58fc659dfb07e216ed3`.

When rendering is rebuilt, it must consume canonical world/spatial data and recover exact semantic art behavior rather than approximate it.

## 8. Development process / anti-drift rules

Canonical process:

> **DESCRIBE -> USER APPROVES -> IMPLEMENT -> VERIFY.**

Global invariants:

1. Main/root is composition/wiring only.
2. Every independently replaceable system has a focused owner/public contract.
3. One major system per implementation slice by default.
4. No placeholder/fake systems presented as complete.
5. Generator is an input to world state, not owner of persistent reality.
6. Rendering never owns simulation truth.
7. Input requests semantic actions; it does not implement world rules.
8. Art is not physics.
9. Phone/Safari remains first-class.
10. Important decisions/lessons do not live only in chat.
11. Do not wire new modules into deprecated runtime through temporary compatibility code.
12. Persistent mechanics attach typed state through stable entity IDs rather than expanding `WorldEntityRecord` into a generic metadata bag.
13. Gameplay systems may use WHEN for duration/order but WHEN never absorbs mechanic-specific rules.
14. Movement legality consumes canonical Collision / Spatial Query rather than duplicating occupancy rules.

## 9. Documentation ownership / source order

- `PROJECT_NORTH_STAR.md` — game identity/philosophy.
- `DESIGN_DECISIONS.md` — settled cross-system decisions and rationale.
- `README_CONTEXT.md` — current phase/status/routing only.
- `README_SOPS.md` — coding/GitHub/Godot/Safari process lessons.
- `DESIGN_WORKFLOW.md` — approval/scope workflow.
- `SYSTEM_DESIGNS/*.md` — detailed subsystem contracts.
- `SYSTEM_DESIGNS/README.md` — approval/status ledger.
- `MODULAR_REBUILD_MASTER_DESIGN.md` — broad architecture inventory where compatible with newer direction.
- `CHANGELOG.md` — repository change history.

Source-of-truth order:

1. newest explicit user instruction;
2. `PROJECT_NORTH_STAR.md`;
3. `DESIGN_DECISIONS.md`;
4. current repository state;
5. `README_SOPS.md`;
6. `DESIGN_WORKFLOW.md`;
7. this context index;
8. IMPLEMENTED/APPROVED active `SYSTEM_DESIGNS/*.md`;
9. DRAFT system designs for current discussion;
10. compatible master-design material;
11. golden history for recovered behavior.

## 10. Recommended next bounded design

**Actor State / Stance & Movement Capability** is the recommended next discussion target, not an authorization to code it.

Why: Movement now deliberately leaves crouch/stance, fatigue, injury, encumbrance and other actor-specific capability facts outside its owner. A focused actor-state/capability contract can establish where those durable facts live and how they feed the replaceable movement policy without teaching WHAT, Collision or WHEN what “crouched,” “injured leg,” or “over-encumbered” means.

Rendering, input, vision, lighting, weather, sound and generation remain separate later systems unless the user chooses a different next approved slice.
