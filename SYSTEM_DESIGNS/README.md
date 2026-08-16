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

The earlier attempt to start with a tactical `RaidMapSpec` was too high-level and assumed a disconnected raid architecture that has since changed.

The current design order starts below generation/rendering:

| Order | System | Status | Design file | Notes |
|---|---|---|---|---|
| 00A | Spatial Model | **NOT DESIGNED** | `00A_SPATIAL_MODEL.md` | Next recommended design: invisible tactical grid, cell footprints/facing, global coordinates, resolve wall/door/window representation |
| 00B | Tick / Action / Pause Kernel | **NOT DESIGNED** | `00B_TICK_ACTION_PAUSE.md` | Variable action duration, scheduling, auto-pause, held movement semantics, hard real-life pause |
| 00C | Persistent World Identity / State | **NOT DESIGNED** | `00C_PERSISTENT_WORLD.md` | Logical global world, persistent mutations/entities, generation ownership boundary, streaming/storage as implementation detail |
| 00D | Population / Household / Outbreak / Player Story foundations | **NOT DESIGNED** | `00D_POPULATION_OUTBREAK_PLAYER_STORY.md` | Persistent people/homes/jobs/relationships, scalable simulation resolution, player embedded in generated world |
| 01 | Generalized Local World Data Contract | **NOT DESIGNED** | `01_WORLD_AREA_DATA.md` | Replaces old raid-specific map concept after 00A–00D establish lower-level truths |
| old-01 | Semantic tactical map / `RaidMapSpec` | **SUPERSEDED** | `01_RAID_MAP_DATA.md` | Useful design mine only; assumed separate raid maps and began above the now-required world foundations |

No foundational system is approved for code yet.

## Later modular systems

Exact order may change after the foundation designs, but these remain known domains rather than permission to implement them together.

| System | Status | Notes |
|---|---|---|
| Recovered multi-atlas Art Catalog | NOT DESIGNED | Recover exact golden `TacticalTiles.gd` semantics; support semantic N/E/S/W prop orientation with rotation or explicit variants |
| Ground renderer | NOT DESIGNED | Reads canonical world/spatial data + ArtCatalog |
| Structure renderer | NOT DESIGNED | Walls/doors/windows only, after Spatial Model settles their representation |
| Prop/fixture/vegetation renderer | NOT DESIGNED | Whole-cell footprints/orientation; world props only |
| Player renderer | NOT DESIGNED | Four directional player sprites initially |
| Authored visual test area | NOT DESIGNED | Proves recovered graphics independently of procedural generation |
| Actor/player state + facing | NOT DESIGNED | Actor foundation should not become player-only if NPC/zombie actors can share it |
| Collision/local world query | NOT DESIGNED | Reads spatial/world state; no UI/generator ownership |
| Player movement | NOT DESIGNED | Requests/executes discrete movement through tick/action + collision contracts |
| Tactical camera + zoom | NOT DESIGNED | One canonical zoom owner |
| Touch/keyboard/Safari input | NOT DESIGNED | Emits semantic intents; hard-pause lifecycle requirements later |
| Tactical controls UI | NOT DESIGNED | Presentation/hit regions only |
| Global world planner | NOT DESIGNED | Geography/roads/utilities/parcels/addresses/building footprints before local materialization |
| World streaming/materialization | NOT DESIGNED | Performance mechanism over global logical world, never source of world truth |
| Local procedural materialization/generation | NOT DESIGNED | Detailed rooms/furniture/clutter/etc. respecting the global plan |
| Road network/topology | NOT DESIGNED | Global coherent network rather than independent chunk exits |
| Property/parcel planner | NOT DESIGNED | Parcels/frontage/access/site mix |
| Building/prefab placement | NOT DESIGNED | Semantic placement/transforms respecting global facts |
| Procedural room/layout | NOT DESIGNED | Room graph, circulation, doors |
| Furniture/fixture/clutter dressing | NOT DESIGNED | Purpose-aware planners, directional art semantics |
| Vegetation/utilities/civic dressing | NOT DESIGNED | Local detail respecting global utility/network facts |
| World/generator validation | NOT DESIGNED | Independent coherence/quality gates |
| Prefab authoring tools | NOT DESIGNED | Shared canonical semantic data/art renderer; separate controller/view/storage/validation |
| Base/claim/community layer | NOT DESIGNED | Thin higher-level layer over real persistent physical world locations |
| Expedition/extraction loop | NOT DESIGNED | Risk/reward return-to-safety behavior inside open world, not necessarily instanced raids |
| Health/body/first aid | NOT DESIGNED | Mini-Zomboid severity/treatment model; reduced physiology, preserved consequence |
| Needs/fatigue/temperature | NOT DESIGNED | Coarse meaningful states, real consequences |
| Vision/perception | DEFERRED | Major mood/gameplay system; mine golden solved work |
| Lighting | DEFERRED | Major mood/gameplay system; mine golden solved work |
| Weather | DEFERRED | State/system + separate VFX; major mood contributor |
| Silent spatial sound | DEFERRED | Physical sound events/localization; no default audible playback |
| Infected AI | DEFERRED | Uses shared actor/action/perception/sound/world contracts |
| Loot/inventory/search | DEFERRED | Persistent physical containers/items; expedition risk/reward consumer |
| Combat | DEFERRED | Tick/action-based exposure and injury consequences |
| Vehicles | DEFERRED | Physical world objects/travel/logistics later; exact driving abstraction not yet decided |
| Construction/destruction | DEFERRED | Persistent world mutation/base-building consumer |

## Design template

Each system file should use this shape:

```markdown
# <System Name>

Status: DRAFT

## 1. Goal
One problem this system solves.

## 2. Non-goals
Nearby responsibilities explicitly outside this system.

## 3. Owner(s)
Standalone script(s) intended to own the system.

## 4. Public contract
Inputs, outputs, methods, signals and semantic data.

## 5. Data ownership
What this system may read/write.

## 6. Allowed dependencies
The small set of modules it may know about.

## 7. Forbidden dependencies
Systems it must never reach into.

## 8. Detailed behavior
Rules and semantics.

## 9. Edge/failure cases
Invalid states and expected handling.

## 10. Performance
Complexity, update constraints, mobile requirements.

## 11. Safari/mobile
Touch/input/lifecycle requirements where relevant.

## 12. Tests / acceptance criteria
Concrete proof that the system is finished.

## 13. Recovery sources
Historical commit/files/algorithms worth inspecting.

## 14. Future extension seams
Known later systems that must be able to connect without rewriting this system.

## 15. North-star fit
How this system serves Ultima-style turn-based mini Zomboid without owning unrelated future behavior.

## 16. Approved decisions
User-approved choices with dates/brief rationale.
```

## Rule for changes after approval

If implementation reveals that an APPROVED design cannot work without crossing a forbidden module boundary, do not silently patch around it. Return the system design to DRAFT, explain the conflict, propose the smallest contract change, and get approval before continuing.
