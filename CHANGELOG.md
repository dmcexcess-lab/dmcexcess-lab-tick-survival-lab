# Changelog

## 05 Ground Layer Renderer — 2026-08-16

- Implemented **05 Ground Layer Renderer** after the user explicitly approved the focused renderer design.
- Added `GroundDrawCommand.gd` as a deterministic immutable-style presentation record containing global cell, local destination rectangle, semantic terrain ID, and copied Art Catalog selection.
- Added standalone `GroundLayerRenderer.gd` as the first canonical CanvasItem presentation layer. It reads canonical WHAT terrain and 04 Art Catalog selections only; it mutates no simulation state and has no generator/reboot/camera/input dependency.
- Visible-world input is explicit: global top-left cell, whole-cell visible dimensions, and positive display cell size. Global cells map to local draw rectangles relative to the visible origin, preserving large/negative persistent-world coordinates without giant CanvasItem positions.
- Recovered the golden ground draw path using lazy/cached textures from ArtSelection descriptors, `ArtSelection.region()`, `draw_texture_rect_region`, transpose=false, and clip_uv=true. No atlas path or index was copied into the renderer.
- Generic `road`, `dirt_road`, and `sidewalk` terrain now derive cardinal display topology from neighboring canonical semantic terrain. Paved and dirt roads share connectivity, while explicit recovered topology variants remain literal Art Catalog requests.
- Deliberately did not invent arterial/local/trail world truth. Generic paved roads use local/default topology until a future canonical Road Network system owns road classification.
- Added visible diagnostic cells for missing WHAT terrain, UNKNOWN art, invalid selections, and texture-load failure instead of silently substituting plausible grass/asphalt/concrete.
- Added event-driven redraw invalidation with no `_process()` redraw loop: configuration/view/world-reset and terrain changes in the visible window or one-cell cardinal topology halo redraw Ground; non-terrain, distant, and diagonal-only offscreen changes do not.
- Added `GroundLayerRendererSmoke.gd` and dedicated Godot 4.7.1 `Ground Layer Renderer contract`, covering source boundaries, Art Catalog regression, visible culling/order, negative coordinates, local rectangles, recovered surface precedence, all road topology families, mixed paved/dirt roads, dirt orientation, sidewalk curbs, explicit variants, diagnostics, texture loading, and redraw invalidation.
- Initial complete implementation head `0b1460a89140d0a9d84478c9300dacb84d991a11` passed the dedicated Ground contract with no production repair required.
- Preserved all golden art assets byte-for-byte and left WHAT/WHERE/WHEN, Collision, Movement, Actor Locomotion, generator, camera, input/UI, Structure/Prop/Actor renderers, lighting/weather/perception, and frozen reboot runtime untouched.
- Next bounded visual system: **Structure Layer Renderer**.

## 04 Recovered Multi-Atlas Art Catalog — 2026-08-16

- Recovered the mature golden `TacticalTiles.gd` semantic art-selection system into the canonical modular `game/scripts/art/` layer rather than creating or approximating new artwork.
- Preserved all six golden atlas assets and all four directional player sprites byte-for-byte. Dedicated CI now verifies their exact Git blob hashes on every art-catalog run so accidental art replacement becomes an immediate contract failure.
- Added `ArtSource.gd` and typed `ArtSelection.gd` descriptors so future renderers can resolve texture sources/atlas regions without world or generator data containing atlas paths or indices.
- Added `ArtBaselineManifest.gd` with the pinned recovery commit, golden `TacticalTiles.gd` blob, and the ten protected asset identities.
- Added `ArtCatalog.gd` with the complete recovered multi-atlas vocabulary: tactical, clutter, world-art, building-prop, final-surface and final-prop sources plus the four player-facing full textures.
- Recovered the golden selection precedence exactly for known content: ground uses final exact -> final alias -> world -> tactical; walls use final -> world -> tactical; props use final exact -> final alias -> building -> clutter -> tactical.
- Restored the complete richer vocabulary rather than the reboot subset, including all 48 final ground/surface entries, all 32 building props, all 24 clutter props and all 128 final environment props through index 127, plus tactical props and the golden barrel helper.
- Recovered themed/default door and window mappings and exact NORTH/EAST/SOUTH/WEST player sprite selection.
- Added `RoadArtTopology.gd` as pure presentation logic for straight/corner/T/cross/end/plain road sprites, the golden arterial plain-road special cases, dirt-road orientation and sidewalk-curb selection. It consumes connectivity masks rather than generator dictionaries or WHAT state.
- Deliberately improved missing-content failure behavior: unknown semantic ground/wall/prop/theme/facing requests now return typed `UNKNOWN` instead of silently rendering asphalt, alley wall or crate fallback art. Known golden mappings remain unchanged.
- Added `ArtCatalogSmoke.gd` and the dedicated Godot 4.7.1 `Recovered Art Catalog contract`, covering asset integrity, texture loading, atlas-region math, source precedence, representative/boundary mappings, topology, player facings and UNKNOWN behavior.
- Kept this slice descriptor-only: no CanvasItem renderer, no generator changes, no physics changes, no simulation changes, no art asset edits, and no wiring into the frozen `game/scripts/reboot/` playable reference.
- The next bounded visual system is the Ground Layer Renderer, which can consume canonical WHAT terrain plus Art Catalog selections without mixing structures, props, actors, camera, input or generation.

## 03 Actor Locomotion State & Movement Capability — 2026-08-16

- Implemented **03 Actor Locomotion State & Movement Capability** after the user explicitly approved the design with “Approved!”.
- Added a shared stable-ID locomotion domain rather than rebuilding the golden player-only `PlayerActor` god object. Persistent locomotion state is explicitly enrolled and currently contains semantic `standing` / `crouched` stance plus a per-actor stale-action version.
- Added deterministic mutation-safe locomotion reads, explicit mutation service, store revision, semantic change signals, deterministic actor-ID-sorted snapshot/restore, and atomic malformed-snapshot rejection. Locomotion may persist while an actor is tactically unplaced; WHAT placement remains independent.
- Added timed voluntary crouch/stand actions through WHEN. Stance changes use a 4-tick base cost, COMMITTED interruption semantics, a final `actor.stance.commit` phase, safe expected-version/source/target payload data, hard-pause safety, and stale-state revalidation before mutation.
- Kept crouching on the same WHAT tactical footprint. Initial tuning is standing walk 1.0x, crouched walk 1.4x, standing/crouched turn 1.0x.
- Deliberately did **not** add running. `run` is not persistent physical state, and a faster run action remains deferred until real fatigue/stamina/sound consequences exist. The capability vocabulary reserves future `movement.run_forward`; crouched actors already report it blocked without implementing the action.
- Added `ActorMovementCapabilityService` with deterministic integer basis-point scaling and sorted read-only `ActorMobilityModifierProvider` extension points. Future Health, Needs/Fatigue, Inventory/Encumbrance, Equipment and Skills systems can modify/block mobility without exposing their internals to Movement, WHAT, Collision or WHEN.
- Added deterministic provider rules: duplicate IDs rejected, ALLOWED adjustments combine additively, UNKNOWN fails closed, explicit BLOCKED outranks UNKNOWN, and non-positive combined duration scale is invalid.
- Implemented the approved narrow revision to 02 Movement: added typed `MovementPolicyDecision`, typed step/turn policy evaluation, and explicit actor/capability statuses in `MovementActionResult` instead of mislabeling condition failures as terrain failures.
- Added `ActorMovementTraversalPolicy` to compose base terrain/timing policy with actor capability while leaving `MovementActionService` owner of collision, timed submission, commit revalidation and WHAT placement mutation.
- Movement now reevaluates actor-aware policy at `movement.commit`: newly blocked capability fails after the already-spent duration; newly slower-but-still-allowed capability does not stretch the current action and applies to the next request.
- Added `ActorLocomotionSmoke.gd` plus a dedicated Godot 4.7.1 `Actor Locomotion contract` workflow. Verification covers enrollment/snapshots, stance timing, hard pause, stale versions, provider aggregation, actor-aware Movement, capability changes mid-action, and the existing Movement regression smoke.
- The frozen `game/scripts/reboot/` playable reference remains untouched; no input, renderer, health, needs, inventory, sound, perception, generation or run implementation was added.

## Collision / Spatial Query Implementation — 2026-08-16

- Implemented the first downstream system after the completed WHERE / WHAT / WHEN foundation: **Collision / Spatial Query**.
- Added `SYSTEM_DESIGNS/01_COLLISION_SPATIAL_QUERY.md` as the canonical contract and promoted it to IMPLEMENTED after dedicated Godot verification.
- Added `CollisionProfile.gd` and `CollisionCatalog.gd` so hard movement collision is explicit physics keyed by semantic entity type rather than inferred from art, WHERE channel alone, or duplicated per world entity.
- Added `CollisionOverrideState.gd` as a sparse durable per-entity override store keyed by stable WHAT entity IDs. Static entities normally consume no collision state beyond their shared type profile; dynamic exceptions such as an open door can override the default and later return to it.
- Added deterministic atomic snapshot/restore and revision tracking for collision overrides without making the collision store own WHAT.
- Added `SpatialQueryResult.gd` with explicit **CLEAR / BLOCKED / UNKNOWN** outcomes. UNKNOWN is fail-closed for missing terrain or required unclassified STRUCTURE/OBJECT/ACTOR entities, preventing unmaterialized void or missing physics configuration from silently becoming passable.
- Added `SpatialQueryService.gd` as a read-only WHERE + WHAT query facade for occupants, placements, terrain presence, arbitrary cell sets, rotated whole-cell footprints and hypothetical entity relocation with self-ignore.
- Kept terrain traversal capability out of collision. Existing terrain must be present for a normal occupancy query, but future Movement/Traversal owns actor-specific rules such as water, mud, climbing or vehicle restrictions.
- Added collision coverage diagnostics for missing required type profiles and orphan per-entity overrides so future generator/content validation can catch physics omissions at creation/CI time rather than during play.
- Recovered the useful decision from golden `LocalWorldState.gd` (`f8fd11ebbf0ff2b3958fd46000404cbb12142fc5`)—walls/obstacles/closed doors block while open doors do not—without restoring fixed local-map bounds, category dictionaries or door state inside collision.
- Added permanent headless `CollisionSpatialQuerySmoke.gd` coverage for mutation-safe catalog reads, static blockers, explicit non-blockers, fail-closed unknowns, loose-item behavior, dynamic overrides, missing terrain, self-ignore, overlapping blockers, rotated multi-cell footprints, coverage diagnostics and atomic override restore.
- CI now gates `COLLISION_SPATIAL_QUERY_SMOKE_OK` after WHERE / WHAT / WHEN and includes source guards proving collision does not import the reboot runtime or WHEN.
- Deliberately did **not** implement Movement Actions, pathfinding, door behavior, terrain traversal, generation or rendering in this slice. The frozen playable reference remains visually unchanged.

## 00C WHEN / Tick Action Pause Implementation — 2026-08-16

- Implemented the third bounded WHERE / WHAT / WHEN foundation slice, **00C Tick / Action / Pause Kernel (WHEN)**, after the user explicitly authorized the timing system with “Now go when.”
- Added `SYSTEM_DESIGNS/00C_TICK_ACTION_PAUSE.md` as the standalone contract and promoted it to IMPLEMENTED after dedicated Godot verification. WHEN owns only simulation time/order: integer world ticks, scheduled events, timed actions, phases, interruption timing, tactical decision auto-pause and hard application pause.
- Added `game/scripts/foundation/time/TickRules.gd`, `ActionPhase.gd`, `TimedAction.gd`, `ScheduledEvent.gd`, `TickEventQueue.gd` and `TickKernel.gd` as focused timing owners with no direct dependency on WHERE, WHAT, the reboot runtime, generator, renderer or gameplay-mechanic modules.
- Replaced the golden scheduler's player-centric “one active player action plus actor list” model with a deterministic shared scheduled-event min-heap. One actor may have one active action, while many actors/systems may have concurrent work on the same authoritative clock.
- Locked deterministic event ordering as **due tick -> priority -> owner/source key -> insertion serial**. Render FPS, wall-clock time, dictionary order and signal connection order do not decide simulation order.
- Added the critical **same-tick batch rule**: once tick T begins resolving, every event due at T—including work scheduled for T by another T event—drains before player-decision auto-pause may engage. This prevents a player action completing first in a same-tick batch from creating a phantom extra turn.
- Added variable-duration `TimedAction` records with semantic `ActionPhase` checkpoints. A phase can commit a mechanic-owned effect at an exact offset while WHEN remains ignorant of meanings such as movement, reload, healing, damage or door interaction.
- Added canonical **COMMITTED / RESUMABLE / CANCELABLE** interruption policies. RESUMABLE actions preserve elapsed progress and remaining checkpoints across interruption; COMMITTED actions ignore ordinary interruption unless explicitly failed; CANCELABLE actions terminate and cannot resume.
- Added a configurable single-player decision actor. The kernel automatically pauses when that actor becomes ready again, but only after the entire current-tick batch resolves. Held movement remains an input concern that may submit another ordinary action when the actor is ready.
- Added a separate **hard application pause** that advances zero simulation ticks and preserves mid-action progress/events exactly. Future Safari/app lifecycle code can invoke this without the timing kernel knowing anything about browser focus or UI.
- `TickKernel` is explicitly driven rather than `_process()`-driven and jumps directly between due ticks instead of scanning empty time. Long-horizon/coarse distant population, weather or infrastructure events can therefore share the same clock without simulating thousands of irrelevant intermediate ticks.
- Added deterministic atomic in-memory snapshot/restore for world tick, action/event serials, active and resumable actions, pending events, decision state and hard-pause state. Timing queue records are serializable data rather than live actor Nodes/callback objects.
- Added a bounded diagnostic trace and bounded operation guard so pathological same-current-tick rescheduling stops explicitly instead of hanging the simulation or inventing time advancement.
- Added permanent headless `TickKernelSmoke.gd` coverage for event ordering, empty-time jumps, dynamic same-tick scheduling, full-batch decision pause, concurrent actors, exact phases/completion, all interruption policies, hard pause, event cancellation/validation, deterministic snapshot restore, serial continuation and pathological zero-time loop protection.
- Verification exposed two **test-harness** mistakes rather than timing-kernel defects: a snapshot test demanded knowledge the serialized schema could not prove after historical events had already drained, and a GDScript lambda test assumed direct mutation of a captured scalar. The tests were corrected to use a provably inconsistent snapshot and an explicitly mutable counter; both reusable lessons were recorded in `README_SOPS.md` rather than adding fake production complexity or weakening timing guarantees.
- Recovered the useful concepts from golden `TickScheduler.gd` (`0d1efa7f76ca58a0357fd9a3d0703320b2ad8d69`)—world ticks, explicit costs, progress/phases, interruption semantics, player-ready pause and snapshots—while deliberately rejecting its global player-action ownership and live actor-object scheduling architecture.
- Updated the North Star, cross-system decision log, context, SOP, system ledger and CI source guards so the canonical **WHERE / WHAT / WHEN foundation triad is now complete and independently tested**.
- Deliberately **did not wire WHEN into `game/scripts/reboot/` or the live scene**. The deployed Web build remains the frozen/deprecated reference runtime; no 00D generation or other downstream system was started in this slice.

## 00B WHAT / Persistent World State Implementation — 2026-08-16

- Implemented the second bounded WHERE / WHAT / WHEN foundation slice, **00B Persistent World / Entity State (WHAT)**, after the user explicitly authorized WHAT as the next system.
- Added `SYSTEM_DESIGNS/00B_PERSISTENT_WORLD_STATE.md` and locked one authoritative **current persistent world** rather than parallel generated/original and modified/current gameplay realities. Future save storage may optimize with baselines/journals/regions, but gameplay sees one truth.
- Added `game/scripts/foundation/world/WorldEntityId.gd` and `WorldEntityRecord.gd` for stable opaque persistent IDs plus semantic entity types independent of Godot Nodes, rendering, storage order and tactical placement.
- Added `WorldPlacement.gd` as the WHAT/WHERE seam: spatial channel, global anchor, N/E/S/W facing, arbitrary whole-cell footprint and optional HORIZONTAL/VERTICAL structure axis. Entities may intentionally remain persistent while unplaced.
- Added separate `TerrainStore.gd`, `EntityStore.gd` and `PlacementStore.gd` owners rather than one giant world dictionary or generic metadata bag.
- Added `OccupancyIndex.gd` as a **derived** global-cell/channel lookup rebuilt from placements. WHAT permits overlap and does not invent collision/construction legality; those decisions remain with later owning systems.
- Added `WorldMutationService.gd` as the validated normal write path for entity create/remove, place/unplace and terrain set/clear. `WorldState.gd` exposes mutation-safe reads instead of leaking internal dictionaries/records.
- Added `WorldChange.gd` plus monotonic world revisions so later rendering, caches, persistence adapters and simulation systems can observe foundation-level entity/placement/terrain changes without WHAT learning mechanic-specific meanings.
- Added deterministic, atomic in-memory snapshot/restore to `WorldState.gd`, including runtime-ID serial and revision. Occupancy is intentionally not serialized and is rebuilt from canonical placement truth. This is a state boundary, not the final browser/disk save implementation.
- Added permanent headless `WorldStateSmoke.gd` coverage for stable IDs, immutable-style reads, negative-coordinate terrain, rotated multi-cell placement, structure-axis validation, overlap indexing, move/unplace/remove behavior, revision/change signals, deterministic snapshot round-trip, occupancy rebuild, atomic malformed-snapshot rejection and post-restore ID allocation.
- CI now independently gates both `SPATIAL_MODEL_SMOKE_OK` and `WORLD_STATE_SMOKE_OK`, plus source guards proving WHAT does not import the reboot runtime or `TickScheduler`.
- During verification, the contract test exposed GDScript strictness issues rather than design failures: typed `Array[T]` values cannot safely use ternaries with a bare `[]`, and typed-return functions may need an explicit fallback return after an apparently infinite loop. Both lessons were added to `README_SOPS.md` instead of weakening tests.
- Deliberately **did not wire WHAT into `game/scripts/reboot/` or the live scene**. WHERE and WHAT remain canonical independently tested foundation source; WHEN is the next bounded design target.
- Updated the system ledger, context, design-decision log and SOP so future work treats WHAT as IMPLEMENTED and does not smuggle door/health/inventory/vehicle/construction logic into the foundation entity record.

## 00A WHERE / Spatial Model Implementation — 2026-08-16

- Promoted the first bounded WHERE / WHAT / WHEN slice, **00A Spatial Model (WHERE)**, from design into the canonical modular source after the user explicitly authorized implementation from the reviewed foundation design.
- Added `SYSTEM_DESIGNS/00A_SPATIAL_MODEL.md` as the implementation contract and locked the spatial choices that were previously unresolved: global integer `Vector2i` cells, N/E/S/W semantic facing, arbitrary whole-cell footprint masks, deterministic 90-degree rotation around a stable anchor, **structure cells** rather than edge walls, explicit HORIZONTAL/VERTICAL structure axis, and centralized `SpatialModel.CELL_METERS = 1.0` planning scale.
- Added `game/scripts/foundation/spatial/SpatialFacing.gd` as the standalone four-way facing/direction owner with cardinal vectors, vector conversion, left/right/opposite and deterministic relative-offset rotation.
- Added `SpatialFootprint.gd` as an immutable-style geometry value object with single-cell/rectangle helpers, arbitrary relative-cell masks, duplicate removal, stable anchors, facing rotation and world-cell derivation including negative global coordinates.
- Added `SpatialStructureGeometry.gd` as the geometry-only structure-axis owner. Horizontal structures expose north/south approaches plus east/west continuity; vertical structures expose east/west approaches plus north/south continuity. It does not inspect world state.
- Added `SpatialLayer.gd` as the shared occupancy-channel vocabulary (`TERRAIN`, `STRUCTURE`, `OBJECT`, `ACTOR`, `LOOSE_ITEM`, `EFFECT`) without storing occupants.
- Added `SpatialModel.gd` as the small pure-geometry facade for adjacency, front/back/left/right cells, four-neighbor queries, Manhattan distance/cardinal adjacency, footprint world cells, overlap and integer bounds.
- Added permanent headless `SpatialModelSmoke.gd` contract coverage for facing, rotation, footprint behavior, duplicate removal, negative/global coordinates, overlap/bounds, structure axes, spatial channels and the canonical cell scale.
- Wired the spatial smoke into Pages CI ahead of the frozen-reference smokes and added source guards for every WHERE owner. The new spatial contract passed Godot import/parse and its dedicated smoke without requiring changes to the old runtime.
- Deliberately **did not wire WHERE into `game/scripts/reboot/` or the live scene**. The deployed reboot remains frozen reference code; temporary compatibility glue is rejected until WHAT and WHEN have their own approved contracts.
- Updated the North Star, decision log, human README, context index and system ledger so structure cells/scale are no longer described as unresolved and the project status is now **modular foundation implementation** with WHERE implemented and WHAT next.

## WHERE / WHAT / WHEN Simulation Foundation Design — 2026-08-16

- Added `SYSTEM_DESIGNS/00_FOUNDATION_WHERE_WHAT_WHEN.md` as the thorough DRAFT architecture for the three peer simulation foundations beneath generation/rendering: **WHERE (Spatial Model), WHAT (Persistent World / Entity State), and WHEN (Tick / Action / Pause Kernel)**.
- Defined WHERE around one global integer tactical-grid coordinate language, N/E/S/W directions, arbitrary whole-cell footprints, deterministic footprint rotation, layered occupancy concepts and structure/opening geometry. The document recommends structure cells with explicit axis rather than cell-edge walls for simplicity/recovered-art compatibility, but that recommendation remains DRAFT until explicitly approved.
- Defined WHAT as durable world truth independent of procedural generators, Godot Nodes, renderers and streaming partitions. Proposed stable opaque entity IDs, semantic world types, explicit stores/mutation paths, derived occupancy indexes, generated-initial-state versus current-persistent-state separation, and ordinary persistent physical state as the basis for player-built bases anywhere.
- Defined WHEN as one integer world-tick/action/event kernel for player actions, other actors and future scheduled systems. Preserved useful golden `TickScheduler.gd` concepts—explicit costs, deterministic ordering, phases, committed/resumable/cancelable interruption, resumable snapshots and player-ready auto-pause—while generalizing beyond a player-centric actor list to a deterministic scheduled-event queue.
- Separated normal tactical auto-pause from **hard real-life application pause**. Hard pause advances zero simulation ticks and must preserve in-progress action state across work/customer/browser/mobile interruptions.
- Designed one world tick to support both detailed nearby actions and coarse distant population/outbreak events, allowing causal open-world simulation without executing every invisible footstep.
- Added explicit cross-system examples for movement, doors, simplified serious injuries, construction/base building, global world generation and outbreak simulation, plus compatibility checks for rendering, vision, lighting, weather, silent spatial sound, inventory, AI, vehicles, construction and streaming.
- Added shared determinism/performance rules: integer coordinates/ticks, stable IDs, deterministic event tie-breaking, named/sub-seeded RNG streams, event-driven world-change notifications, no full-world per-tick scans, no permanent Node per persistent object, visible/detail simulation only where relevant.
- Recorded the **WHERE / WHAT / WHEN decomposition as settled in concept** in `DESIGN_DECISIONS.md`; the detailed umbrella remains DRAFT and does not authorize code.
- Updated `SYSTEM_DESIGNS/README.md` so 00A/00B/00C point to the umbrella draft and explicitly require bounded subsystem approval before implementation. Generation remains downstream as a producer of initial WHAT using WHERE.
- Updated `README_CONTEXT.md` so the current task is review of the foundation draft before any new runtime code, and corrected `DESIGN_WORKFLOW.md` to remove the last stale extraction-style gameplay language from current project philosophy.
- No gameplay/runtime code changed. The deployed Web build remains the frozen/deprecated clean-reboot reference.

## Project North Star / Persistent-World Anti-Drift Reset — 2026-08-16

- Added `PROJECT_NORTH_STAR.md` as the short canonical game-identity document future work must reread before local subsystem design. Primary shorthand is now **“Ultima-style turn-based mini Zomboid.”**
- Added the project principle **“Mini means reduced complexity, not reduced consequence or mood.”** Survival systems should preserve meaningful decisions, causality, danger and atmosphere without reproducing unnecessary internal simulation variables.
- Updated the human `README.md` around the current persistent-open-world direction, turn-based variable-duration action model, real-life hard-pause requirement, invisible tactical grid, simplified-but-consequential health philosophy, extraction-style expedition risk, physical base, outbreak simulation and customizable player stories.
- Added `DESIGN_DECISIONS.md` as an append/supersede cross-system decision log so later work can recover why a foundational decision was made instead of inferring intent from whichever code happens to exist.
- Explicitly superseded the earlier disconnected **static strategic map -> generated raid -> extraction** world model as the long-term physical foundation. Extraction-shooter influence now means risk/reward expeditions inside a logically continuous persistent world; internal streaming/storage partitions are implementation details rather than separate realities.
- Recorded the global-world-planning rule: roads, utilities, parcels and other cross-region structures are planned in global coordinates before local materialization so independently loaded chunks cannot invent incompatible seams.
- Recorded the long-term causal outbreak goal: pre-collapse people/households/jobs/homes/schedules can be simulated through collapse, with coarse deterministic distant simulation permitted for performance as long as persistent causal state is preserved.
- Recorded the Player Story direction: the player eventually customizes/inhabits a real person embedded in the generated world, including home, occupation/workplace, household/family, relationships, pets/vehicle/resources and outbreak-start circumstances where appropriate.
- Recorded the base direction: a base is fundamentally a real physical world location, with higher-level UI only summarizing underlying storage/workspaces/power/water/vehicles/residents/etc.
- Recorded the current spatial baseline: authoritative **invisible tactical grid**, cell-to-cell actors, whole-cell object footprints and semantic N/E/S/W orientation. Renderer owns whether clutter/furniture uses 90-degree rotation or explicit alternate-facing art. Wall/door/window cell-vs-edge representation remains deliberately unresolved for Spatial Model design.
- Recorded the hard interruption-safety rule: real-life work/customer interruptions must freeze simulation safely and must never count as a tactical mistake.
- Rewrote `README_CONTEXT.md` as an accurate routing index for the current open-world direction and moved the foundational design order below map generation/rendering: Spatial Model -> Tick/Action/Pause -> Persistent World -> Population/Outbreak/Player Story -> generalized local-world contract.
- Reordered `SYSTEM_DESIGNS/README.md` accordingly and marked the old raid-specific `RaidMapSpec` draft **SUPERSEDED** rather than silently adapting it to a different world architecture.
- Strengthened `DESIGN_WORKFLOW.md` and `README_SOPS.md` with a mandatory North-Star drift check, cross-system decision logging, future-seam review, and the rule that chat must not outrun the repo when the game direction materially changes.
- Added CI guards requiring the North Star and decision log to remain present and checking the current core identity/open-world design statements while the deprecated reference runtime continues to build unchanged.
- No new modular runtime/gameplay code was implemented in this pass; the deployed Web build remains the frozen clean-reboot reference.

## Design-First Modular Workflow / System Approval Ledger — 2026-08-16

- Added `DESIGN_WORKFLOW.md` as the mandatory project process: **DESCRIBE -> APPROVE -> IMPLEMENT -> VERIFY** for every major new subsystem or rewrite.
- Added an explicit scope gate requiring GPT to push back before coding when a prompt spans multiple major systems, break the work into dependency-ordered pieces, recommend the first bounded system, and obtain approval before implementation.
- Added a strict no-placeholder/no-fake-completion rule. Missing prerequisite systems must be designed first or explicitly deferred rather than replaced with temporary mechanics that silently become architecture.
- Added targeted clarification rules for genuinely ambiguous historical references, destructive scope, module ownership, stable public contracts, Safari/mobile interaction, timing, persistence and player-visible semantics. Ordinary spelling/typos do not require clarification when intent is clear.
- Recast `README_CONTEXT.md` as a concise routing/current-state index rather than the encyclopedia of every subsystem. Detailed canonical system memory now belongs under `SYSTEM_DESIGNS/`.
- Added `SYSTEM_DESIGNS/README.md` as the subsystem approval ledger and reusable system-design template. Major systems move through DRAFT -> APPROVED -> IMPLEMENTED (or SUPERSEDED), and DRAFT explicitly does not authorize coding.
- Added a change-impact declaration requirement: before implementing an approved system, identify the modules expected to change, neighboring modules that must remain untouched, and whether any public contract changes.
- Added the rule that if implementation unexpectedly requires crossing a forbidden module boundary, work stops and the system design returns to DRAFT rather than cascading a convenient patch into neighboring systems.
- Strengthened `README_SOPS.md` into a living repository SOP with the new scope/approval gates plus reusable Godot, Safari and GitHub lessons. Reusable discoveries must be written back to SOP/system docs during the same coherent prompt instead of living only in chat history.
- Added CI guards requiring the design workflow and system approval ledger to remain present and preserving the frozen reference runtime while Phase 0 design work continues.
- Set the recommended first detailed subsystem design to the semantic tactical map / `RaidMapSpec` contract. No new modular runtime code was implemented in this pass.

## Modular Rebuild Reset / Golden Recovery Contract — 2026-08-16

- Reclassified the current clean-reboot runtime under `game/scripts/reboot/` as **frozen/deprecated reference code** rather than the architecture to keep extending. The live Web build remains available until its modular replacement is proven.
- Added `MODULAR_REBUILD_MASTER_DESIGN.md` as the canonical next-build architecture and consolidated the current game direction, rural-generation rules, static strategic-map progression, vehicle-gateway concept, prefab direction, recovered/deferred systems, and implementation order.
- Made modularity a hard project rule: the root `Main.gd` is bootstrap/composition only. Rendering, input, controls, camera, zoom, player movement, collision, generation, strategic map, prefab authoring, extraction/travel, persistence, validation, and later simulation systems must each have standalone owners rather than accumulating as functions in Main.
- Pinned golden pre-clean-rewrite recovery commit `1763958f44eb7f855fd49944c00d1ffe608c0abe` for exact visual/system archaeology.
- Confirmed that the richer pre-rewrite artwork was **not lost**. The six important atlas files and four directional player sprites on current `main` are byte-identical to the golden commit. The visual regression came from replacing `TacticalTiles.gd`'s semantic multi-atlas selection/render behavior with a simplified reboot catalog, not from missing image files.
- Recorded exact golden/current asset blob hashes in the master design/context/SOP so future recovery work can distinguish an unchanged art asset from a changed renderer.
- Identified golden `TacticalTiles.gd` (`3d8a0a70ac983408bb48f58fc659dfb07e216ed3`) as the source of the mature multi-atlas visual vocabulary. Its semantic mappings/road topology/prop-selection behavior will be recovered into a standalone `ArtCatalog` plus separate ground/structure/prop/player renderers instead of copied back into another monolithic presentation script.
- Established a semantic world-data boundary: procedural generation must output concepts such as house walls, gravel driveways and kitchen sinks plus explicit physics facts; it may not output atlas indices or invoke renderer functions. This makes the random generator independently replaceable without changing graphics, player controls, camera, strategic map or other systems.
- Documented a proposed highly modular folder layout with independent app/data/art/render/camera/input/player/world/strategic/raid/generation/prefab-dev/UI/time/perception domains and separate generation planners/validators.
- Consolidated the current Rural Edge target: two-lane rural roads with straight/bend/crossroads variation, dirt/gravel access roads, broad vegetation/open land, utility/power infrastructure, sparse stop signs, roughly 3–4 residential properties as a normal scale rather than a rigid quota, farm/country-house/manufactured-home variation, and normally zero/one compact gas/convenience/corner store with no rural strip malls.
- Preserved the strongest recent geometry lessons: functional procedural rooms normally at least 3x3, storefront/public rooms around 5x5–7x7, support rooms around 3x3, wall-aware installed fixtures, circulation-aware clutter, and authoritative door-axis/approach validation.
- Defined the next implementation order: first build a bootstrap-only Main and recover the **exact old visual stack on a tiny authored test map**; only after the visuals are visibly verified should the new modular Rural Edge generator be written. Prefab tooling, travel/extraction, ticks, vision, lighting, weather and silent spatial sound follow as separate subsystem phases.
- Updated `README_CONTEXT.md` and `README_SOPS.md` so future code prompts are forced to treat the modular master design as canonical, inspect the actual golden implementation when recovering old behavior, avoid cross-subsystem rewrites, and ask targeted clarification before genuinely ambiguous destructive changes.
- This reset is deliberately **design/architecture only**: no current runtime scripts or retained art files were deleted or rewritten in this pass.

## Prefab Workshop / Authored Generator Inserts — 2026-08-16

- **Safari/mobile access fix:** replaced the easy-to-miss small strategic-map prefab control with a large bottom-center **PREFAB BUILDER** touch button, and enlarged/renamed the tactical prefab control to the same clear label.
- Added an in-game **Prefab Workshop** so reusable tactical structures can be authored directly in the running game instead of hardcoding every floor plan into `RebootSiteGenerator.gd`.
- Added `RebootPrefabEditor.gd`, a touch/mouse-first developer overlay with a **16x14 maximum canvas**, matching one far-zoom tactical window. Access it from `PREFAB BUILDER` in tactical play, the large `PREFAB BUILDER (n)` button on the strategic map, or F2 on desktop.
- Added a native `LineEdit` prefab-name field for reliable Web/Safari keyboard behavior.
- Added tap/click and drag painting for common floor tiles, canonical house/light/store/industrial walls, windows, horizontal-wall doors, vertical-wall doors, and three pages of common furniture/fixture/prop tools.
- Added ERASER plus two-tap CLEAR and DELETE protection for destructive editing actions.
- SAVE trims empty outer rows/columns, so a structure only occupies its actual used footprint rather than carrying the full 16x14 editor canvas.
- Added `RebootPrefabLibrary.gd` as the durable authored-content owner. Prefabs are serialized as portable JSON data at `user://reboot_prefabs.json` rather than becoming generator code.
- Web prefab persistence is intentionally **browser/device-local**. It is separate from the future survivor/world save system and does not automatically commit or synchronize authored prefabs to GitHub/another device.
- Added hard authored-prefab validation before SAVE. Door H/V orientation uses the same v4 wall-axis contract as procedural doors; bad wall intersections, blocked approaches, overlapping structure/props, and doors without same-axis structural neighbors are rejected.
- Exterior authored doors are supported: their approach clearance can extend outside the stored prefab footprint and is checked against the destination map during placement.
- Integrated saved prefabs into future Rural Road generation. After normal deterministic procedural generation, the runtime deterministically attempts **at most one** authored prefab insert before running the canonical site validator.
- Safe placement rejects player-spawn proximity, main roads, side roads, existing building buffers, existing structures, non-vegetation props, incompatible road/asphalt/field ground, and doorway-clearance conflicts. If no valid footprint exists, the map remains purely procedural.
- Authored prefabs currently appear as **additional structures** rather than replacing one of the four residences or roadside business. Semantic prefab roles/room tagging are intentionally deferred so the existing Rural Road property contract remains intact.
- Added `RebootPrefabSmoke.gd` as a permanent Pages CI gate. It builds a real cabin prefab, checks 16x14-to-used-footprint trimming, storage encode/decode round trip, deliberate broken-door rejection, deterministic stamping, preserved door-axis metadata, authored-use metadata, and full `RebootSiteGenerator.validate()` success after insertion.
- Added `PREFAB_WORKSHOP.md` and updated reboot context/SOP/core docs so prefab authoring, local persistence, safe stamping, and future export/import/semantic-role work have explicit owners and boundaries.

## Rural Road Generator v4 / Door Geometry & Road Variety — 2026-08-16

- Corrected the reported remaining "wall behind doors" problem as a **generator floor-plan defect rather than an art defect**. The tactical door tile was already correct; several prefabs were placing doors on or too near perpendicular partition geometry.
- Added authoritative door-axis metadata. Horizontal-wall doors reserve north/south approach cells; vertical-wall doors reserve east/west approach cells.
- Door cells and their perpendicular approaches are now structural reservations: later wall/window/fixture/clutter generation cannot overwrite them.
- Added a stronger door invariant: each door must retain structural neighbors on both sides of its own wall axis while its perpendicular approaches remain clear. This rejects doors embedded in wall crosses/T-junctions even when the door cell itself contains no wall.
- The new validator caught real prefab errors during implementation: country-house exterior doors shared an x-axis with an interior divider, one farmhouse partition door sat too close to a perpendicular junction, and manufactured-home door lines were separated proactively. The floorplans were corrected rather than weakening validation.
- Established **3x3 as the minimum usable functional-room size**. The rural store's old 3x1 manager office and 2x2 bathroom are now 3x3; every recorded home/business room must satisfy the same minimum.
- Rural roadside business contract is now 7x7 storefront, 3x3 stock room, 3x3 manager office, 3x3 bathroom and 7x3 rear service space.
- Rebuilt the rural main-road generator as connected topology rather than one hard-coded straight strip. Seeds now produce **straight roads, bent/curved-looking roads, or crossroads**.
- Added horizontal/vertical/corner/T/cross/end road sprite selection from the retained road-topology artwork.
- Protected authoritative main-road cells from later field, yard, building-floor, driveway or gas-forecourt painting so generated road connectivity cannot be visually overwritten after the fact.
- Property connectors now meet the main road using its local alignment, allowing homes/businesses to connect correctly to bent roads rather than assuming one global y coordinate.
- Permanent eight-seed smoke now requires all three road variants plus the 3x3 room minimum and axis-correct door geometry, while retaining the rural five-site composition, utility/power, vegetation, tactical-art, determinism and player checks.

## Rural Road Generator v3 / Original Tactical Tile Restoration — 2026-08-16

- Corrected the reboot's art restoration after playtesting showed that the v2 mapping still was **not the original tactical look**. The remembered structural vocabulary came from the early `TacticalTiles.gd` path, not the later `world_art` shell/opening tiles.
- Restored the exact original tactical-atlas structural mapping: wall variants **16–22**, closed door **23**, open door **24**, and window **25**. Common ground/floors and many common props also return to the original tactical/clutter sheets.
- Added hard door-clearance grammar and reframed rural tactical generation around four residences plus one roadside gas station/corner store, with one farm complex, manufactured housing, country houses, utility poles/power lines, sparse stop signs and rural vegetation.
- Added the first compact roadside business grammar and strengthened eight-seed deterministic validation. Generator v4 supersedes the older same-cell-only door validation and fixed straight-road assumption.

## Rural Road Generator v2 / Composite Art Restoration — 2026-08-16

- Replaced the reboot-v1 one-property rural archetypes with one coherent **Rural Road** biome grammar. A tactical map became a sample of rural road rather than one giant showcase farmhouse/trailer property.
- Reduced residential scale and introduced smaller functional room grammar, roadside lots, driveways/mailboxes, outbuildings, vegetation and fixture-placement validation.
- Expanded generator smoke coverage to eight deterministic Rural Road seeds.
- Attempted to restore the pre-reboot composite art vocabulary, but this pass incorrectly treated the later `world_art` structural shell/door vocabulary as the remembered old tile set. Generator v3 superseded that mapping with the actual early `TacticalTiles.gd` structural indices.

## Clean Reboot Core / Rural Generator v1 — 2026-08-16

- Replaced the active prototype runtime with a deliberately small clean-reboot core while retaining the existing environment and directional player artwork.
- Switched `game/main.tscn` to `scripts/reboot/RebootMain.gd`; the running build no longer loads the legacy v4-v6 generator chain, tick/calendar stack, weather, lighting, perception/fog, extraction-session presentation, or the old Safari autoload.
- Added `RebootArt.gd` as the reboot-only art catalog and `RebootSiteGenerator.gd` as a new deterministic 64x64 site generator that does not wrap or repair the legacy generator.
- Added the minimal player/movement/rotation core, phone-first controls, three tactical zoom levels, event-driven visible-cell renderer, static outskirts-to-city strategic map, reboot-only CI, and clean reboot documentation.
- Vision cone, lighting, weather, silent sound, infected, loot/inventory, combat, injuries, ticks/calendar, vehicles, extraction consequences and persistence remain intentionally deferred until the generator/player foundation is strong.

## Prototype era — archived in Git history

The earlier v0-v6 work established the retained art vocabulary and explored ticks, perception, weather, procedural regions, streetscapes, extraction travel and focused interiors. That runtime is no longer canonical after the clean reboot. Its detailed changelog remains available in repository history at commits before this reboot.