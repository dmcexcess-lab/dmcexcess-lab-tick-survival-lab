# Tick Survival Lab — System Design Index / Approval Ledger

Major systems move through **NOT DESIGNED -> DRAFT -> APPROVED -> IMPLEMENTED** under `DESIGN_WORKFLOW.md`. Read `PROJECT_NORTH_STAR.md` and `DESIGN_DECISIONS.md` first.

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
| 16 | Canonical Player Shell / Inspectors / Stance | **IMPLEMENTED** | `16_CANONICAL_PLAYER_SHELL.md` |
| 17 | Run / Damage-Interruptible Walking | **IMPLEMENTED** | `17_RUN_DAMAGE_INTERRUPTIBLE_WALKING.md` |
| 17A | Movement Exertion / Encumbrance / Run Impact Revision | **IMPLEMENTED** | `17A_MOVEMENT_EXERTION_ENCUMBRANCE_RUN_IMPACT.md` |
| 00D | Global World Planning / Generation | **NOT DESIGNED** | `00D_GLOBAL_WORLD_GENERATION.md` |
| 00E | Population / Household / Outbreak / Player Story | **NOT DESIGNED** | `00E_POPULATION_OUTBREAK_PLAYER_STORY.md` |
| 00F | Streaming / Materialization | **NOT DESIGNED** | `00F_STREAMING_MATERIALIZATION.md` |
| old-01 | Raid-map / extraction physical-world model | **SUPERSEDED** | `01_RAID_MAP_DATA.md` |

## Implemented source ownership

Foundation and simulation remain separated by domain:

- WHERE: `game/scripts/foundation/spatial/`
- WHAT: `game/scripts/foundation/world/`
- WHEN: `game/scripts/foundation/time/`
- Collision: `game/scripts/simulation/collision/`
- Movement / 17 / 17A physical actions and stateless coordinators: `game/scripts/simulation/movement/`
- Locomotion/capability: `game/scripts/simulation/actors/locomotion/`
- Health: `game/scripts/simulation/actors/health/`
- Needs: `game/scripts/simulation/actors/needs/`
- Skills: `game/scripts/simulation/actors/skills/`
- Carry: `game/scripts/simulation/actors/carry/`
- Hands: `game/scripts/simulation/actors/equipment/`
- Inventory: `game/scripts/simulation/inventory/`
- Item transfer: `game/scripts/simulation/items/transfer/`
- Item physical properties: `game/scripts/simulation/items/properties/`
- Moodlets: `game/scripts/simulation/actors/moodlets/`

Presentation/application remains separate:

- Art: `game/scripts/art/`
- existing canonical renderers: `game/scripts/render/`
- canonical demo/bootstrap/input/player-control under focused app/demo/input/player/UI owners.

`game/scripts/reboot/` remains frozen reference only. `game/main.tscn` launches the canonical demo.

## Live demo after System 17A

The canonical demo has one controlled survivor, no NPCs/infected, the authored 13x13 sample map, existing renderer stack, real HUD, Stats/Inventory/Menu, Crouch/Stand and Run.

Movement truth:

- Walk: one cell, terrain base cost, damage-CANCELABLE;
- Run: two committed forward strides at 60% of each stride's Walk terrain pace before actor factors;
- terrain × stance × fatigue × encumbrance multiply movement duration;
- fatigue 80+ blocks Run;
- 100%+ carry capacity blocks Run;
- over-capacity Walk remains legal/slower;
- successful Walk fatigue depends on terrain only;
- Run fatigue depends on terrain + encumbrance;
- known hard Run blockers cause physical impact, attempted-stride fatigue, 5 HP damage, and stop the sprint;
- UNKNOWN space still fails closed.

System 16 Web Leave Game now navigates directly to Google rather than attempting browser history.

Dedicated System 17A verification:

- `.github/workflows/movement-exertion-encumbrance.yml`
- `game/scripts/ci/MovementExertionEncumbranceSmoke.gd`

Hardened implementation candidate `eeb5eb421337df3067f45b41fb4837fdb9b8875b` passed dedicated run `32000627706` after a test-fixture-only retention correction; production required no repair.

## Immediate next path

Do not rebuild movement/player shell/renderers. Return to the real item-interaction demo:

1. add a few real stable WHAT `item.*` entities with 13D weights;
2. add the missing loose-item presentation;
3. compose existing System 10 BACK -> actor body -> FRONT held-item layers in the live stack;
4. expose real System 12 pickup/drop/equip/unequip through semantic keyboard/touch interaction;
5. let existing HUD/Inventory read the committed truth.

Door interaction remains a separate later system.

## Design rule

Every major system keeps a focused owner/public contract. If implementation unexpectedly requires crossing a forbidden boundary, return the design to review rather than cascading a patch.
