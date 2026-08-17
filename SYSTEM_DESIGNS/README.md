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
| 16 | Canonical Player Shell / Inspectors / Stance Integration | **DRAFT** | `16_CANONICAL_PLAYER_SHELL.md` |
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
- 15: `game/scripts/ui/FacingInspectionQuery.gd`, `ActorStatusSummaryQuery.gd`, and `CanonicalStatusHud.gd`; live wiring remains composition-only in `CanonicalDemoMain.gd`

System 16 is **DRAFT only**. Proposed owners are `ActorStatsInspectorQuery.gd`, `ActorInventoryInspectorQuery.gd`, `CanonicalPlayerShell.gd`, plus bounded additions to the existing input/player-action integration. No System 16 production code may be implemented until explicit approval.

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

System 15 adds the first real survival-status presentation to that same live build:

- authoritative tick and current facing;
- read-only one-cell-ahead `Looking at:` physical inspection;
- real HP, fatigue, hunger, thirst, sleep pressure;
- real derived carry current/capacity;
- real derived moodlets;
- no perception claim, no fake values, no frame polling.

The duplicate pre-System-15 help line and second controls-owned tick/action label are vestigial and are being removed so the HUD is the sole action/tick status surface.

Dedicated System 15 verification: `.github/workflows/canonical-hud.yml` and `game/scripts/ci/CanonicalHudSmoke.gd`. Hardened code head `fb19c7b86569c388dcb251b2b61210e745f3909a` passed run `31994628336`; the only earlier failure was an over-broad CI text match, not production behavior.

## Immediate path after HUD

System 16 is now the active **DRAFT** design. It proposes one integration slice that reuses already-real systems for:

1. timed Crouch/Stand through existing System 03;
2. read-only `STATS` over real status/injury/skill/stance state;
3. read-only `INVENTORY` over real Hands/Containment/Carry state;
4. `MENU` plus modal hard-pause ownership and Resume/Leave Game;
5. gameplay input blocking while modal UI is open.

The next gate is explicit user approval or revision of `16_CANONICAL_PLAYER_SHELL.md`. Do not implement it while DRAFT.

After System 16, likely bounded additions are demo items/loose-item presentation + System 10 held-item composition and real System 12 interaction UI, then door interaction.

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
The canonical demo now has phone/keyboard navigation plus real HUD/`Looking at:`/status. System 16 DRAFT defines the remaining first-shell target: Crouch/Stand, `STATS`, `INVENTORY`, `MENU`, safe hard pause during modal inspection/menu, Resume + Leave Game, and no fabricated values.

## Design rule
Every major system keeps a focused owner/public contract. If implementation unexpectedly requires crossing a forbidden boundary, return the design to review rather than cascading a patch.
