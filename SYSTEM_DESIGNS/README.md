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
| 15 | Canonical HUD / Facing Inspection | **IMPLEMENTED** | `15_CANONICAL_HUD_FACING_INSPECTION.md` |
| 16 | Canonical Player Shell / Inspectors / Stance Integration | **IMPLEMENTED** | `16_CANONICAL_PLAYER_SHELL.md` |
| 17 | Run / Damage-Interruptible Walking | **IMPLEMENTED** | `17_RUN_DAMAGE_INTERRUPTIBLE_WALKING.md` |
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
- 17: Movement additions plus `MovementDamageInterruptionService.gd` and `MovementRunExertionService.gd`; narrow 03/13A/13B public-seam revisions.

### Presentation / application
- 04: `game/scripts/art/`
- 05/06/07/08/10: focused files under `game/scripts/render/`
- 14: canonical app/demo/render-stack/input/player-control integration
- 15: HUD/facing/status query layer
- 16: Stats/Inventory/Menu shell + stance input integration
- 17: additive semantic Run input/controller/demo composition only; no renderer rewrite.

Canonical modules remain separate from frozen `game/scripts/reboot/` reference code. `game/main.tscn` launches the canonical demo.

## Current live demo shell

The deployed canonical demo has:

- one authored 13x13 WHAT map;
- exactly one controlled survivor, no NPCs/infected;
- Ground -> Structure -> Prop -> Living Actor renderer stack;
- real Collision + Movement + Locomotion + WHEN;
- System 15 real HUD;
- System 16 Crouch/Stand + Stats/Inventory/Menu/hard pause;
- **System 17 explicit Run Forward**.

System 17 movement behavior:

- Walk Forward/Back: one cell, healthy 10-tick demo baseline, CANCELABLE by real damage;
- Run Forward: two cells, healthy 6 ticks/stride / 12 total on demo terrain, COMMITTED;
- fatigue 80+ blocks Run start;
- each successful Run stride adds +1 real fatigue;
- crouched Run blocked;
- damage does not cancel Run or turns;
- Shift+W/Shift+Up and native touch RUN submit semantic Run intent.

Dedicated verification:

- `.github/workflows/run-damage-walking.yml`
- `game/scripts/ci/RunDamageWalkingSmoke.gd`

Initial System 17 code candidate `33580c2e9016c15591005536707b2729e580876e` passed dedicated run `31998617639` without production repair.

## Immediate path after System 17

Do not rebuild movement/player shell/renderers.

Next useful bounded integration is the **real item interaction demo**:

1. add real stable WHAT `item.*` entities and explicit 13D weights;
2. implement loose-item presentation;
3. compose existing System 10 BACK -> actor body -> FRONT hand layers;
4. expose System 12 pickup/drop/equip/unequip through semantic UI.

Door interaction remains separate.

## Other later modular systems
- Container Access / Search / Open / Lock — NOT DESIGNED
- Corpse / Decay / Contamination — NOT DESIGNED, direction approved
- Door interaction / physical transition — NOT DESIGNED
- Actor Appearance / character creator integration — NOT DESIGNED
- Loose-item renderer — NOT DESIGNED
- richer item quantity/condition/bulk — NOT DESIGNED
- first aid / health progression / sickness — NOT DESIGNED beyond 13A
- eating/drinking/rest/sleep progression — NOT DESIGNED beyond 13B
- global world generation — NOT DESIGNED
- construction/destruction — DEFERRED
- vision/perception, lighting, weather, silent spatial sound — DEFERRED
- infected AI, combat, vehicles — DEFERRED

## Design rule
Every major system keeps a focused owner/public contract. If implementation unexpectedly requires crossing a forbidden boundary, return the design to review rather than cascading a patch.
