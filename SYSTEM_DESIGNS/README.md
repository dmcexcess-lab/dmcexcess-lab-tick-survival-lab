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
| 18 | Door Interaction / Automatic Passage | **DRAFT** | `18_DOOR_INTERACTION_PASSAGE.md` |
| 19 | Local Building Generation / Archetype Critique Lab | **DRAFT** | `19_LOCAL_BUILDING_GENERATION_ARCHETYPE_LAB.md` |
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
- neutral item acquisition-capacity seam: `game/scripts/simulation/items/ItemAcquisitionCapacityPolicy.gd`
- Item physical properties: `game/scripts/simulation/items/properties/`
- Moodlets: `game/scripts/simulation/actors/moodlets/`
- Door State: `game/scripts/simulation/doors/`

Presentation/application remains separate:

- Art: `game/scripts/art/`
- existing canonical renderers: `game/scripts/render/`
- canonical demo/bootstrap/input/player-control under focused app/demo/input/player/UI owners.

`game/scripts/reboot/` remains frozen reference only. `game/main.tscn` launches the canonical demo.

## Live demo after System 17A.1

The canonical demo has one controlled survivor, no NPCs/infected, the authored 13x13 sample map, existing renderer stack, real HUD, Stats/Inventory/Menu, Crouch/Stand and Run.

Movement truth:

- Walk: one cell, terrain base cost, damage-CANCELABLE;
- Run: two committed forward strides at 60% of each stride's Walk terrain pace before actor factors;
- terrain × stance × fatigue × encumbrance multiply movement duration;
- fatigue 80+ blocks Run;
- 100%+ soft carry capacity blocks Run;
- over-capacity Walk remains legal/slower;
- Walk adds **no** movement fatigue at or below soft capacity;
- overweight Walk fatigue depends on terrain only, not how far overweight the survivor is;
- Run fatigue depends on terrain + encumbrance;
- known hard Run blockers cause physical impact, attempted-stride fatigue, 5 HP damage, and stop the sprint;
- UNKNOWN space still fails closed.

Carry truth:

- default soft capacity remains 18 kg;
- absolute hard possession ceiling is derived at 2x soft capacity, therefore 36 kg by default;
- normal loose-world pickup may reach but not exceed the hard ceiling;
- incoming container contents count toward projected pickup weight;
- System 12 consumes a neutral capacity policy rather than importing Carry internals.

The live authored demo still has no physical item entities, so the hard pickup ceiling is currently canonical/tested simulation behavior awaiting later item-interaction composition.

System 16 Web Leave Game navigates directly to Google rather than attempting browser history.

## Active design drafts — 2026-08-16

### System 18 — Door Interaction / Automatic Passage

Proposed player behavior:

- Walk through a normal CLOSED door -> it opens automatically at Walk commit and movement continues;
- Run through a normal CLOSED door -> it opens during the committed stride, movement continues, and a LOUD semantic door event is emitted;
- short click/tap on a nearby OPEN door -> timed manual close;
- future long-tap/right-click interaction menu is reserved but deferred.

Architecture uses existing 06A Door State plus Collision overrides and a narrow generic Movement passage-resolver seam so Movement never imports door rules.

### System 19 — Local Building Generation / Archetype Critique Lab

Proposed first archetype:

`residential.trailer.singlewide`

System 19 is intentionally below future global world planning. A caller supplies a legal envelope/orientation/frontage/seed; System 19 produces a validated semantic building plan and materializes initial physical WHAT + explicitly CLOSED Door State.

Development loop:

> spawn deterministic trailer -> user critiques -> refine trailer rules -> then add small house/ranch archetype under the same contract.

The first trailer target has distinct living/kitchen, bathroom, bedroom, physical doors/windows, functional furniture, and validated one-cell circulation.

## Recommended approval / implementation order

1. **System 18 Door Interaction** first — small prerequisite that makes generated buildings naturally enterable.
2. **System 19 Local Building Generation** second — implement generator contract + Trailer Candidate 001 in a one-screen critique lot.
3. User critiques generated trailer and generator rules are refined.
4. Add small ordinary house/ranch archetype under the same generator contract.
5. Add camera / larger local play space only once multiple structures create a real need to see beyond one screen.

The item-interaction demo remains valid future work, but current explicit direction prioritizes doors + building generation before expanding camera/map scale.

## Design rule

Every major system keeps a focused owner/public contract. If implementation unexpectedly requires crossing a forbidden boundary, return the design to review rather than cascading a patch.
