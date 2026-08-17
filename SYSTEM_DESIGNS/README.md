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
| 17A.1 | Overweight Walk Fatigue / Absolute Carry Ceiling Correction | **IMPLEMENTED** | `17A1_OVERWEIGHT_WALK_FATIGUE_HARD_CARRY_LIMIT.md` |
| 18 | Door Interaction / Automatic Passage | **IMPLEMENTED** | `18_DOOR_INTERACTION_PASSAGE.md` |
| 19 | Local Building Generation / Archetype Critique Lab | **IMPLEMENTED** | `19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md` |
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
- Movement / Run / passage seams: `game/scripts/simulation/movement/`
- Door State + Door Interaction: `game/scripts/simulation/doors/`
- Locomotion/capability: `game/scripts/simulation/actors/locomotion/`
- Health / Needs / Skills / Carry / Moodlets: focused actor-domain folders under `game/scripts/simulation/actors/`
- Hands: `game/scripts/simulation/actors/equipment/`
- Inventory: `game/scripts/simulation/inventory/`
- Item transfer: `game/scripts/simulation/items/transfer/`
- Item physical properties: `game/scripts/simulation/items/properties/`
- Local building generation: `game/scripts/generation/buildings/`
- Art: `game/scripts/art/`
- canonical renderers: `game/scripts/render/`
- demo/bootstrap/input/player/UI: focused owners under their corresponding folders.

`game/scripts/reboot/` remains frozen reference only. `game/main.tscn` launches the canonical modular demo.

## Live demo after System 19

The live canonical demo is now the **Trailer Candidate 001 critique lot**:

- one controlled survivor, no NPCs/infected/loot;
- fixed 13×13 one-screen view, still no camera;
- one deterministic generated 6×12 single-wide trailer;
- real walls/windows/furniture and three real CLOSED doors;
- distinct living/kitchen, bathroom and bedroom;
- real System 18 door passage.

Door interaction truth:

- Walk through an eligible CLOSED door -> opens at Walk commit with no extra door ticks;
- damage-canceled Walk -> door remains CLOSED;
- Run through eligible CLOSED door -> opens during stride, emits LOUD semantic event, no door-impact HP damage;
- tap/click OPEN adjacent door while **facing it** -> 3-tick CANCELABLE close;
- wrong-facing close rejects at zero ticks, so turning costs existing turn ticks;
- future long-tap/right-click interaction menu remains reserved.

Movement / carry truth from Systems 17–17A.1 remains unchanged.

## Immediate next path

1. **User playtests/critiques Trailer Candidate 001.**
2. Convert critique into reusable `residential.trailer.singlewide` archetype rules rather than hand-editing the showcase instance.
3. Once trailer density/proportions feel right, add `residential.house.small_ranch` under the existing System 19 contract.
4. Repeat the critique loop for the house.
5. Add camera / larger local play space when multiple properties create an actual need to see beyond one screen.

The real item-interaction demo remains valid future work and can be layered into generated buildings later.

## Verification

First fully green Systems 18+19 candidate:

- SHA `c035fe7b3f5d0badab6c5b598996010e92d852b2`;
- Door Interaction run `32005363005`: SUCCESS;
- Local Building Generation run `32005363051`: SUCCESS.

Exact documentation-promotion SHA must pass the same dedicated contracts plus Pages before completion is claimed.

## Design rule

Every major system keeps a focused owner/public contract. If implementation unexpectedly requires crossing a forbidden boundary, return the design to review rather than cascading a patch.
