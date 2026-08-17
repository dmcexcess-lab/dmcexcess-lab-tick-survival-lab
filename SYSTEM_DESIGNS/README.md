# Tick Survival Lab — System Design Index / Approval Ledger

This directory is the durable detailed memory for individual systems. Major systems move through **NOT DESIGNED -> DRAFT -> APPROVED -> IMPLEMENTED** under `DESIGN_WORKFLOW.md`. Read `PROJECT_NORTH_STAR.md` and `DESIGN_DECISIONS.md` first.

## Status meanings
- **NOT DESIGNED** — known future system, no detailed contract yet.
- **DRAFT** — discussion only; do not implement.
- **APPROVED** — user approved; implementation may begin.
- **IMPLEMENTED** — approved design exists in canonical modular source and is tested.
- **SUPERSEDED** — historical design replaced by newer direction.

## Current canonical architecture

| Order | System | Status | Design source |
|---|---|---|---|
| 00 | WHERE / WHAT / WHEN Simulation Foundation | **IMPLEMENTED via children** | `00_FOUNDATION_WHERE_WHAT_WHEN.md` |
| 00A | Spatial Model — WHERE | **IMPLEMENTED** | `00A_SPATIAL_MODEL.md` |
| 00B | Persistent World / Entity State — WHAT | **IMPLEMENTED** | `00B_PERSISTENT_WORLD_STATE.md` |
| 00C | Tick / Action / Pause Kernel — WHEN | **IMPLEMENTED** | `00C_TICK_ACTION_PAUSE.md` |
| 01 | Collision / Spatial Query | **IMPLEMENTED** | `01_COLLISION_SPATIAL_QUERY.md` |
| 02 | Movement Actions | **IMPLEMENTED** | `02_MOVEMENT_ACTIONS.md` |
| 03 | Actor Locomotion / Movement Capability | **IMPLEMENTED** | `03_ACTOR_LOCOMOTION_MOVEMENT_CAPABILITY.md` |
| 04 | Recovered Multi-Atlas Art Catalog | **IMPLEMENTED** | `04_RECOVERED_MULTI_ATLAS_ART_CATALOG.md` |
| 05 | Ground Layer Renderer | **IMPLEMENTED** | `05_GROUND_LAYER_RENDERER.md` |
| 06A | Door State | **IMPLEMENTED** | `06A_DOOR_STATE.md` |
| 06 | Structure Layer Renderer | **IMPLEMENTED** | `06_STRUCTURE_LAYER_RENDERER.md` |
| 07 | Prop / Fixture / Vegetation Renderer | **IMPLEMENTED** | `07_PROP_FIXTURE_VEGETATION_RENDERER.md` |
| 08 | Player / Living Actor Renderer | **IMPLEMENTED** | `08_PLAYER_LIVING_ACTOR_RENDERER.md` |
| 09 | Actor Hand Equipment State | **IMPLEMENTED** | `09_ACTOR_HAND_EQUIPMENT_STATE.md` |
| 10 | Actor Hand Equipment Presentation | **IMPLEMENTED** | `10_ACTOR_HAND_EQUIPMENT_PRESENTATION.md` |
| 11 | Inventory / Containment | **IMPLEMENTED** | `11_INVENTORY_CONTAINMENT.md` |
| 12 | Item Transfer / Pickup / Drop / Equip Actions | **IMPLEMENTED** | `12_ITEM_TRANSFER_ACTIONS.md` |
| 13 | Actor Stats / Status Architecture | **IMPLEMENTED via children** | `13_ACTOR_STATS_STATUS_ARCHITECTURE.md` |
| 13A | Actor Health / Injury | **IMPLEMENTED** | `13A_ACTOR_HEALTH_INJURY.md` |
| 13B | Actor Needs / Rest | **IMPLEMENTED** | `13B_ACTOR_NEEDS_REST.md` |
| 13C | Actor Skills | **IMPLEMENTED** | `13C_ACTOR_SKILLS.md` |
| 13D | Item Physical Properties | **IMPLEMENTED** | `13D_ITEM_PHYSICAL_PROPERTIES.md` |
| 13E | Actor Carry / Encumbrance | **IMPLEMENTED** | `13E_ACTOR_CARRY_ENCUMBRANCE.md` |
| 13F | Actor Moodlets / Status Derivation | **IMPLEMENTED** | `13F_ACTOR_MOODLETS.md` |
| 14 | Canonical Playable Demo Integration | **IMPLEMENTED** | `14_CANONICAL_PLAYABLE_DEMO.md` |
| 00D | Global World Planning / Generation | **NOT DESIGNED** | `00D_GLOBAL_WORLD_GENERATION.md` |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED** | `00E_POPULATION_OUTBREAK_PLAYER_STORY.md` |
| 00F | Streaming / Materialization | **NOT DESIGNED** | `00F_STREAMING_MATERIALIZATION.md` |
| old-01 | Raid-map / extraction physical-world model | **SUPERSEDED** | `01_RAID_MAP_DATA.md` |

## Implemented source owners

### Foundation / simulation
- 00A: `game/scripts/foundation/spatial/`
- 00B: `game/scripts/foundation/world/`
- 00C: `game/scripts/foundation/time/`
- 01: `game/scripts/simulation/collision/`
- 02: `game/scripts/simulation/movement/`
- 03: `game/scripts/simulation/actors/locomotion/`
- 06A: `game/scripts/simulation/doors/`
- 09: `game/scripts/simulation/actors/equipment/`
- 11: `game/scripts/simulation/inventory/`
- 12: `game/scripts/simulation/items/transfer/`
- 13A: `game/scripts/simulation/actors/health/`
- 13B: `game/scripts/simulation/actors/needs/`
- 13C: `game/scripts/simulation/actors/skills/`
- 13D: `game/scripts/simulation/items/properties/`
- 13E: `game/scripts/simulation/actors/carry/`
- 13F: `game/scripts/simulation/actors/moodlets/`

### Presentation / application
- 04: `game/scripts/art/`
- 05/06/07/08/10: focused files under `game/scripts/render/`
- 14: `game/scripts/app/CanonicalDemoMain.gd`, `game/scripts/demo/CanonicalDemoFixture.gd`, `game/scripts/render/TacticalRendererStack.gd`, `game/scripts/input/`, `game/scripts/player/DemoPlayerActionController.gd`, and `game/scripts/ui/DemoMovementControls.gd`

The canonical modules remain separate from frozen `game/scripts/reboot/` reference code. As of System 14, `game/main.tscn` launches the canonical demo instead of Reboot.

## Current System 13 contract summary

**13A Health** owns real HP and broad persistent injuries. **13B Needs** owns fatigue/hunger/thirst/sleep pressure. **13C Skills** owns six catalog-driven base skills plus XP/levels. **13D Item Physical Properties** owns explicit semantic item weight in grams. **13E Carry** persists capacity but derives current weight from real Hands + Containment + Weight. **13F Moodlets** derives readable statuses and stores no ordinary duplicated moodlet state.

03 remains the mobility-composition owner. Needs and Carry plug into its existing narrow modifier-provider seam; Movement does not import either domain.

Dedicated verification: `.github/workflows/actor-stats.yml`, success token set from six child smokes. Initial complete candidate `78ed167678257749b093acd54e53e9f065cd8ce5` passed run `31992365565` with no production repair.

## Current canonical playable demo

System 14 is the first live canonical composition and supersedes Reboot as the deployed entry point.

- one authored 13x13 canonical WHAT sample map;
- exactly one controlled survivor, no NPCs/infected;
- existing Ground -> Structure -> Prop -> Living Actor renderer composition;
- real Collision + Movement + Locomotion + WHEN for walking/turning;
- W/arrow keyboard input and native touch/Safari buttons emitting the same semantic intents;
- fixed one-screen tactical view; camera/zoom intentionally deferred until a larger world requires it.

Dedicated verification: `.github/workflows/canonical-demo.yml` and `game/scripts/ci/CanonicalDemoSmoke.gd`. Initial complete integration head `41ccfedd658082f5d249b5107363658705ea4b03` passed run `31993465800` with no production repair after the complete candidate reached CI.

## Immediate path after the walking demo

The next work should extend the live canonical demo rather than rebuild already-proven renderers. Likely bounded additions, only when requested:

1. `Looking at:` / Stats / Inventory / Menu UI reading already-real systems.
2. Held-item layers/items and Item Transfer interaction in the demo.
3. Camera/zoom only when world content expands beyond one screen.
4. Larger authored/generated world content behind the same canonical simulation/render contracts.

## Other later modular systems
- Container Access / Search / Open / Lock — NOT DESIGNED
- Corpse / Decay / Contamination — NOT DESIGNED, direction approved
- Door interaction / physical transition — NOT DESIGNED
- Actor Appearance / character creator integration — NOT DESIGNED
- Loose-item renderer — NOT DESIGNED
- Quantity / stack / durability / richer item definitions — NOT DESIGNED
- Capacity/transfer blocking or bulk policy — NOT DESIGNED; current 13E only derives consequences
- Health progression / first aid / sickness — NOT DESIGNED beyond 13A state
- Needs progression / eating / drinking / sleeping actions — NOT DESIGNED beyond 13B state
- Road/property/building/room/dressing generation systems — NOT DESIGNED
- Construction/destruction — DEFERRED
- Vision/perception, lighting, weather, silent spatial sound — DEFERRED
- Infected AI, combat, vehicles — DEFERRED

## Requested future demo UI target
The canonical walking demo now exists. Later UI may add Safari/iPhone navigation refinements, desktop equivalents, recovered-style `Looking at:`, concise real actor stats, `STATS`, `INVENTORY`, and `MENU` buttons, safe pause during inspection/menu, Resume + Leave Game, and no fabricated values.

## Design rule
Every major system keeps a focused owner/public contract. If implementation unexpectedly requires crossing a forbidden boundary, return the design to review rather than cascading a patch.
