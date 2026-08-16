# Tick Survival Lab — System Design Index / Approval Ledger

This directory is the detailed durable memory for individual systems.

A system is implemented only after its design status is **APPROVED** by the user.

## Status meanings

- **DRAFT** — being discussed; do not implement.
- **APPROVED** — user approved the design; implementation may begin.
- **IMPLEMENTED** — approved design is present in the canonical modular runtime and tested.
- **SUPERSEDED** — retained for history but replaced by a newer approved design.
- **RECOVERY SOURCE** — historical behavior worth mining, not current architecture.

## Current rebuild ledger

| Order | System | Status | Design file | Notes |
|---|---|---|---|---|
| 01 | Semantic tactical map / `RaidMapSpec` contract | NOT DESIGNED | `01_RAID_MAP_DATA.md` | Recommended first system; stable seam between generation, physics and rendering |
| 02 | Recovered multi-atlas Art Catalog | NOT DESIGNED | `02_ART_CATALOG.md` | Recover exact golden `TacticalTiles.gd` semantics; no generation logic |
| 03 | Ground renderer | NOT DESIGNED | `03_GROUND_RENDERER.md` | Consumes semantic map data + ArtCatalog |
| 04 | Structure renderer | NOT DESIGNED | `04_STRUCTURE_RENDERER.md` | Walls/doors/windows only |
| 05 | Prop/fixture/vegetation renderer | NOT DESIGNED | `05_PROP_RENDERER.md` | World props only |
| 06 | Player renderer | NOT DESIGNED | `06_PLAYER_RENDERER.md` | Four directional player sprites |
| 07 | Authored visual test map | NOT DESIGNED | `07_VISUAL_TEST_MAP.md` | Proves recovered graphics before procedural generation |
| 08 | Player state + facing | NOT DESIGNED | `08_PLAYER_STATE_FACING.md` | State only; no UI |
| 09 | Collision/local world query | NOT DESIGNED | `09_COLLISION_WORLD.md` | Movement/door/blocking query boundary |
| 10 | Player movement | NOT DESIGNED | `10_PLAYER_MOVEMENT.md` | Consumes semantic intents + collision query |
| 11 | Tactical camera + zoom | NOT DESIGNED | `11_CAMERA_ZOOM.md` | One canonical zoom owner |
| 12 | Touch/keyboard/Safari input | NOT DESIGNED | `12_INPUT.md` | Emits semantic intents only |
| 13 | Tactical controls UI | NOT DESIGNED | `13_TACTICAL_CONTROLS.md` | Button presentation/hit regions, no movement rules |
| 14 | Static strategic map | NOT DESIGNED | `14_STRATEGIC_MAP.md` | Background/nodes/view/input separated from travel rules |
| 15 | Rural Edge generation coordinator/contracts | NOT DESIGNED | `15_RURAL_GENERATION.md` | Begins only after visual foundation is verified |
| 16 | Road topology generator | NOT DESIGNED | `16_ROADS.md` | Straight/bend/cross/T/etc. semantics |
| 17 | Rural property planner | NOT DESIGNED | `17_RURAL_PROPERTIES.md` | Parcels/frontage/access/site mix |
| 18 | Building/prefab placement | NOT DESIGNED | `18_BUILDING_PLACEMENT.md` | Semantic placement and transforms |
| 19 | Procedural room/layout system | NOT DESIGNED | `19_ROOM_LAYOUT.md` | Room graph, size, circulation, doors |
| 20 | Furniture/fixture/clutter dressing | NOT DESIGNED | `20_DRESSING.md` | Separate purpose-aware planners |
| 21 | Vegetation/utilities/civic dressing | NOT DESIGNED | `21_RURAL_ENVIRONMENT.md` | Trees/bushes/power/stop signs/etc. |
| 22 | Generator validation/quality | NOT DESIGNED | `22_GENERATOR_VALIDATION.md` | Independent quality gate |
| 23 | Prefab authoring tools | NOT DESIGNED | `23_PREFAB_AUTHORING.md` | Rebuilt only after generator/data contracts stabilize |
| 24 | Travel/deployment/extraction | NOT DESIGNED | `24_TRAVEL_EXTRACTION.md` | Static map reachability and raid return semantics |
| 25 | Tick/action scheduler recovery | DEFERRED | `25_TICKS.md` | Mine golden solved system later |
| 26 | Vision/perception recovery | DEFERRED | `26_PERCEPTION.md` | Later |
| 27 | Lighting recovery | DEFERRED | `27_LIGHTING.md` | Later |
| 28 | Weather recovery | DEFERRED | `28_WEATHER.md` | Later |
| 29 | Silent sound system | DEFERRED | `29_SOUND.md` | Later |
| 30 | Infected AI | DEFERRED | `30_INFECTED.md` | Later |
| 31 | Loot/inventory/search | DEFERRED | `31_INVENTORY.md` | Later |
| 32 | Combat/body/injury | DEFERRED | `32_COMBAT_BODY.md` | Later |

This order is a planning sequence, not permission to implement several systems together.

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
Complexity, redraw/update constraints, mobile requirements.

## 11. Safari/mobile
Touch/input/layout requirements where relevant.

## 12. Tests / acceptance criteria
Concrete proof that the system is finished.

## 13. Recovery sources
Historical commit/files/algorithms worth inspecting.

## 14. Future extension seams
How known future systems can attach without rewriting this one.

## 15. Approved decisions
User-approved choices with dates/brief rationale.
```

## Rule for changes after approval

If implementation reveals that an APPROVED design cannot work without crossing a forbidden module boundary, do not silently patch around it. Return the system design to DRAFT, explain the conflict, propose the smallest contract change, and get approval before continuing.
