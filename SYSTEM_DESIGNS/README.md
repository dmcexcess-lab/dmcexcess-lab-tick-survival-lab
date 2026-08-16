# Tick Survival Lab — System Design Index / Approval Ledger

This directory is the detailed durable memory for individual systems.

A system is implemented only after its design status is **APPROVED** by the user.

Before using this ledger, read `PROJECT_NORTH_STAR.md` and `DESIGN_DECISIONS.md`. The ledger tracks system detail/status; it does not replace whole-game intent.

## Status meanings

- **NOT DESIGNED** — known future system, no detailed design yet.
- **DRAFT** — being discussed; do not implement.
- **APPROVED** — user approved the design; implementation may begin.
- **IMPLEMENTED** — approved design is present in the canonical modular runtime and tested.
- **SUPERSEDED** — retained for history but replaced by newer direction.
- **RECOVERY SOURCE** — historical behavior worth mining, not current architecture.

## Current foundational sequence

The earlier attempt to start with a tactical `RaidMapSpec` was too high-level and assumed a disconnected raid architecture that has since been removed.

The current recommended design order starts with **WHERE / WHAT / WHEN**. This is a planning order only; no foundational system is approved for code yet.

| Order | System | Status | Design file | Notes |
|---|---|---|---|---|
| 00A | Spatial Model — WHERE | **NOT DESIGNED** | `00A_SPATIAL_MODEL.md` | Invisible tactical grid, global coordinates, cell footprints/facing, structures/openings; resolve wall/door/window representation |
| 00B | Persistent World / Entity State — WHAT | **NOT DESIGNED** | `00B_PERSISTENT_WORLD_STATE.md` | Persistent IDs/entities/mutations, initial vs current state, world ownership independent of Godot scene nodes |
| 00C | Tick / Action / Pause Kernel — WHEN | **NOT DESIGNED** | `00C_TICK_ACTION_PAUSE.md` | Variable action duration, scheduling, auto-pause, held movement semantics, hard real-life pause |
| 00D | Global World Planning / Generation Contract | **NOT DESIGNED** | `00D_GLOBAL_WORLD_GENERATION.md` | Geography/roads/utilities/parcels/building footprints planned coherently; generator feeds initial world state |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED** | `00E_POPULATION_OUTBREAK_PLAYER_STORY.md` | Persistent people/homes/jobs/relationships, scalable simulation resolution, player embedded in generated world |
| 00F | Streaming / Materialization | **NOT DESIGNED** | `00F_STREAMING_MATERIALIZATION.md` | Performance/storage mechanism over one logical world; partitions never define reality |
| old-01 | Semantic tactical map / `RaidMapSpec` | **SUPERSEDED** | `01_RAID_MAP_DATA.md` | Design mine only; assumed separate raid maps and started above the real foundations |

## Why generation is not the foundation

Generation is one producer of initial world state. It must use the same spatial/entity contracts as every other system.

- world generation creates virgin terrain/structures/population;
- construction later adds or changes structures;
- destruction changes them;
- doors/containers/vehicles mutate through gameplay;
- save/load restores the resulting persistent state;
- rendering only reads that state.

Replacing the generator must not require replacing the spatial model, tick kernel, renderer, player controls or saved world format.

## Later modular systems

Exact order will be refined after the foundations are designed.

| System | Status | Notes |
|---|---|---|
| Recovered multi-atlas Art Catalog | NOT DESIGNED | Recover exact golden `TacticalTiles.gd` semantics; semantic N/E/S/W orientation with rotation or explicit variants |
| Ground renderer | NOT DESIGNED | Reads canonical world/spatial data + ArtCatalog |
| Structure renderer | NOT DESIGNED | Walls/doors/windows only, after Spatial Model settles representation |
| Prop/fixture/vegetation renderer | NOT DESIGNED | Whole-cell footprints/orientation; world props only |
| Player/actor renderer | NOT DESIGNED | Four directional sprites initially; should not make underlying actor model player-only |
| Authored visual test area | NOT DESIGNED | Proves recovered graphics independently of procedural generation |
| Actor state/facing | NOT DESIGNED | Shared actor foundation for player/NPC/infected where appropriate |
| Collision/spatial query | NOT DESIGNED | Reads spatial/world state; no UI/generator ownership |
| Movement actions | NOT DESIGNED | Uses spatial query + tick/action contracts |
| Tactical camera + zoom | NOT DESIGNED | One canonical zoom owner |
| Touch/keyboard/Safari input | NOT DESIGNED | Emits semantic intents; hard-pause lifecycle requirements |
| Tactical controls UI | NOT DESIGNED | Presentation/hit regions only |
| Road network/topology | NOT DESIGNED | Global coherent network rather than independent chunk exits |
| Property/parcel planner | NOT DESIGNED | Parcels/frontage/access/site mix |
| Building/prefab placement | NOT DESIGNED | Semantic placement/transforms respecting global facts |
| Procedural room/layout | NOT DESIGNED | Room graph, circulation, doors |
| Furniture/fixture/clutter dressing | NOT DESIGNED | Purpose-aware planners, directional art semantics |
| Vegetation/utilities/civic dressing | NOT DESIGNED | Local detail respecting global utility/network facts |
| World/generator validation | NOT DESIGNED | Independent coherence/quality gates |
| Prefab authoring tools | NOT DESIGNED | Shared canonical semantic data/art renderer; separate controller/view/storage/validation |
| Construction/destruction | DEFERRED | Persistent world mutation; player may build/secure bases anywhere legal |
| Base/community summary layer | NOT DESIGNED | Optional thin summary/management layer over physical world facts; no special base map |
| Health/body/first aid | NOT DESIGNED | Mini-Zomboid severity/treatment model; reduced physiology, preserved consequence |
| Needs/fatigue/temperature | NOT DESIGNED | Coarse meaningful states, real consequences |
| Vision/perception | DEFERRED | Major mood/gameplay system; mine golden solved work |
| Lighting | DEFERRED | Major mood/gameplay system; mine golden solved work |
| Weather | DEFERRED | State/system + separate VFX; major mood contributor |
| Silent spatial sound | DEFERRED | Physical sound events/localization; no default audible playback |
| Infected AI | DEFERRED | Uses shared actor/action/perception/sound/world contracts |
| Loot/inventory/search | DEFERRED | Persistent physical containers/items in the continuous world |
| Combat | DEFERRED | Tick/action-based exposure and injury consequences |
| Vehicles | DEFERRED | Persistent physical world objects/travel/logistics later |
| Old raid/extraction/session architecture | **SUPERSEDED** | No required raid/extraction/staging loop in current design |

## Design template

Each system file should include:

1. **Status** — NOT DESIGNED / DRAFT / APPROVED / IMPLEMENTED / SUPERSEDED.
2. **Goal** — the one problem this subsystem solves.
3. **Non-goals** — nearby responsibilities it explicitly does not own.
4. **Owner(s)** — intended standalone script/module owners.
5. **Public contract** — inputs, outputs, methods, signals and semantic data.
6. **Data ownership** — what state it may mutate and what it may only read.
7. **Allowed dependencies**.
8. **Forbidden dependencies**.
9. **Detailed behavior/rules**.
10. **Edge/failure cases**.
11. **Performance requirements**.
12. **Safari/mobile requirements** where relevant.
13. **Tests / acceptance criteria**.
14. **Recovery sources** from historical code when applicable.
15. **Future extension seams** for known later systems.
16. **North-star fit** — how it serves Ultima-style turn-based mini Zomboid without owning unrelated behavior.
17. **Approved decisions** with rationale.

## Rule for changes after approval

If implementation reveals that an APPROVED design cannot work without crossing a forbidden module boundary, do not silently patch around it. Return the system design to DRAFT, explain the conflict, propose the smallest contract change, and get approval before continuing.
