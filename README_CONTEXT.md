# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, current `main` SHA, and the active system design(s). Read `MODULAR_REBUILD_MASTER_DESIGN.md` for architecture/global direction, but newer North Star/decision entries win where older assumptions conflict.

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
- mood driven later by recovered graphics, vision, lighting, weather, silent spatial sound and persistent consequences.

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
- **03 Actor Locomotion State & Movement Capability — IMPLEMENTED and CI-gated** under `game/scripts/simulation/actors/locomotion/`.

The canonical modules are intentionally tested beside the frozen playable reference until enough neighboring canonical presentation/input/world-composition systems exist for clean replacement rather than compatibility glue.

## 3. Foundation architecture

Canonical umbrella: `SYSTEM_DESIGNS/00_FOUNDATION_WHERE_WHAT_WHEN.md`.

The peer truths are:

- **WHERE:** global grid/facing/footprint/structure geometry.
- **WHAT:** persistent terrain/entities/placements and durable foundation mutations.
- **WHEN:** deterministic integer simulation clock, action/event scheduling and pause semantics.

Generation creates initial WHAT using WHERE. Gameplay systems bridge WHERE/WHAT with WHEN. Rendering only presents state.

### 00A WHERE — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/00A_SPATIAL_MODEL.md`.

Locked: global integer `Vector2i` cells, 1m planning scale, N/E/S/W facing, arbitrary whole-cell footprints, structure cells with explicit axis, no sub-cell baseline.

### 00B WHAT — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/00B_PERSISTENT_WORLD_STATE.md`.

Locked: one current persistent world, opaque stable IDs, semantic terrain/entities, WHERE placements, derived occupancy, validated `WorldMutationService` writes, safe reads, revisions/change events, deterministic atomic snapshot/restore, no generic mechanic metadata bag.

### 00C WHEN — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/00C_TICK_ACTION_PAUSE.md`.

Locked: non-negative integer world tick, deterministic scheduled work, variable-duration concurrent actor actions, semantic phases, COMMITTED/RESUMABLE/CANCELABLE interruption, tactical decision pause, separate hard application pause, same-tick batch drain, deterministic snapshot/restore.

## 4. Downstream canonical simulation

### 01 Collision / Spatial Query — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/01_COLLISION_SPATIAL_QUERY.md`.

Hard occupancy physics is explicit type-level collision plus sparse per-entity overrides. Required missing classification or missing terrain is UNKNOWN/fail-closed. Collision supports hypothetical rotated footprints/self-ignore and deliberately does not own actor-specific terrain traversal.

### 02 Movement Actions — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/02_MOVEMENT_ACTIONS.md`.

Locked movement rules:

- forward/back/turn-left/turn-right only;
- no diagonal/strafe/run yet;
- validate -> spend WHEN duration -> revalidate `movement.commit` -> mutate WHAT;
- no destination reservation;
- stale origin cannot overwrite newer placement;
- backward preserves facing;
- turns query the rotated footprint;
- typed `MovementPolicyDecision` distinguishes terrain failures from actor/capability failures;
- policy is reevaluated at commit; newly blocked capability fails, newly slower-but-allowed capability affects the next action instead of stretching the current schedule.

### 03 Actor Locomotion State & Movement Capability — IMPLEMENTED

Canonical design: `SYSTEM_DESIGNS/03_ACTOR_LOCOMOTION_MOVEMENT_CAPABILITY.md`.

Locked rules:

- explicit locomotion enrollment keyed by stable WHAT actor ID; missing record fails closed;
- persistent stance is semantic `standing` / `crouched` only;
- no persistent RUN flag and no run action until real consequences exist;
- crouch does not alter WHAT footprint/anchor;
- standing step 1.0x, crouched step 1.4x, turns 1.0x initial tuning;
- voluntary crouch/stand is a 4-tick base COMMITTED action with final `actor.stance.commit`;
- per-actor locomotion version prevents stale stance actions overwriting newer state;
- deterministic atomic locomotion snapshot/restore;
- future health/needs/inventory/equipment/skills influence mobility only through sorted read-only `ActorMobilityModifierProvider` contracts;
- capability provider BLOCKED outranks UNKNOWN, allowed BP adjustments combine deterministically;
- actor-aware Movement policy composes base terrain timing + actor capability without importing condition domains into Movement or WHEN.

Implemented owners include:

- `ActorStance.gd`
- `ActorLocomotionRecord.gd`
- `ActorLocomotionState.gd`
- `ActorLocomotionMutationService.gd`
- `ActorMovementCapabilityDecision.gd`
- `ActorMobilityModifierProvider.gd`
- `ActorMovementCapabilityService.gd`
- `ActorMovementTraversalPolicy.gd`
- `ActorStanceActionResult.gd`
- `ActorStanceActionService.gd`
- `game/scripts/ci/ActorLocomotionSmoke.gd`
- `.github/workflows/actor-locomotion.yml`

## 5. Open-world / generation direction

Generation is not the engine and streaming partitions never define logical reality.

Long-term planning order:

**world seed -> geography -> towns/rural districts -> roads -> utilities -> parcels/addresses -> building footprints/types -> households/businesses/population -> local detail/materialization**.

Roads, utilities, rivers, parcels and other cross-region structures are planned globally before local materialization. Once facts exist, persistent WHAT owns later changes.

## 6. Outbreak / player story / bases

Long-term world state supports pre-collapse persistent people, households, homes, jobs/workplaces, schedules, vehicles and relationships, then causal outbreak/collapse simulation. Distant populations may use coarser deterministic resolution while preserving causal state.

The playable survivor eventually inhabits a real generated-world person with identity, occupation/workplace, home/property, family/household, relationships, pets, vehicle/resources and starting circumstances where applicable.

A base is an ordinary physical world location, not a special map/mode. Multiple bases, relocation, abandonment and nomadic play remain valid.

## 7. Graphics recovery truth

The richer pre-rewrite artwork remains intact. Mature presentation came from golden `TacticalTiles.gd` combining six atlases plus four directional player sprites.

Golden semantic renderer blob:

`3d8a0a70ac983408bb48f58fc659dfb07e216ed3`

Visual recovery means reconstructing exact semantic art-selection behavior into standalone canonical art/render systems, not approximating with one atlas or extending reboot presentation.

## 8. Development invariants

Canonical process:

> **DESCRIBE -> USER APPROVES -> IMPLEMENT -> VERIFY.**

Global rules:

1. Main/root is composition only.
2. One independently replaceable system = focused owner/public contract.
3. One major system per implementation slice by default.
4. No fake/placeholder systems presented as complete.
5. Generator is an input to world state, not persistent reality owner.
6. Rendering never owns simulation truth.
7. Input emits semantic intent; it does not implement mechanics.
8. Art is not physics.
9. Phone/Safari is first-class.
10. Durable decisions do not live only in chat.
11. Do not wire canonical modules into deprecated reboot through temporary adapters.
12. Persistent mechanic state uses typed stable-ID domain stores rather than expanding `WorldEntityRecord` into a metadata bag.
13. Gameplay systems use WHEN for duration/order; WHEN never learns mechanic meanings.
14. Movement consumes canonical Collision and typed policy decisions rather than duplicating occupancy/condition rules.
15. Actor condition domains affect mobility through narrow provider contracts instead of being imported into locomotion/Movement.

## 9. Documentation source order

1. newest explicit user instruction;
2. `PROJECT_NORTH_STAR.md`;
3. `DESIGN_DECISIONS.md`;
4. current repository state;
5. `README_SOPS.md`;
6. `DESIGN_WORKFLOW.md`;
7. this context index;
8. IMPLEMENTED/APPROVED active `SYSTEM_DESIGNS/*.md`;
9. current DRAFT designs;
10. compatible `MODULAR_REBUILD_MASTER_DESIGN.md` material;
11. golden history for recovered behavior.

## 10. Recommended next bounded design

**Recovered multi-atlas Art Catalog** is the recommended next discussion target, not authorization to code it.

Why now: the canonical simulation stack has real space, persistent state, time, collision, movement and actor locomotion/capability contracts. Recovering the exact golden semantic art-selection vocabulary next creates the stable presentation boundary needed before Ground/Structure/Prop/Actor renderers and an authored visual integration area are designed.

Do not jump from Art Catalog design into generation, input, weather, lighting or a full playable-runtime replacement in one slice. Those remain separate systems.
