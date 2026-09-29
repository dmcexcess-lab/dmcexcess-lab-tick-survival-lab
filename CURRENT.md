# Tick Survival Lab — Current State

Status: **canonical active working state**

## Working model

PROJECT = Tick Survival Lab  
IDENTITY = turn-based open-world zombie survival  
CORE_LOOP = explore -> scavenge -> fight/escape -> craft/heal -> fortify/supply shelter -> survive  
ACTIVE_REWRITE_SLICE = 9 complete / power and water  
NEXT_REWRITE_SLICE = 10 / vehicles  
ROADMAP_CHANGE = true / 2026-09-28

## Authoritative direction

Keep the game; retire the experimental execution architecture.

Canonical play remains:

player action -> direct consequence -> relevant local actors each act at most once -> ordinary survival/time consequence -> return player control

Shared simulation ticks, generalized simultaneous resolution, universal commitment/interruption and heavyweight WHERE/WHAT/WHEN execution are legacy.

## Closed canonical routes

Slices 1-8 remain canonical as previously recorded: movement/combat/scavenging/inventory/survival, contextual interaction, craft/cook/heal/repair/deconstruct, and existing-opening fortification all route through the simple-turn model and authoritative domain owners.

### Power and water — Slice 9

`gameplay.tscn` now boots `UtilitySimpleGameMain -> FortificationGameMain -> Slice7GameMain -> TurnBasedGameMain`.

Canonical portable-generator REFUEL / START / STOP / REPAIR and failed-distribution-support repair no longer schedule generalized timed actions. They validate the actual utility target and contact reach, reuse the existing exact fuel/tool/material/Mechanical requirements and skill checks, mutate the existing portable-generator or power-network owner directly, consume exact carried material entities transactionally, award existing Mechanical XP, and feed explicit elapsed action cost through the established simple-turn/survival completion seam.

Generator inspection remains zero-time. Failed preconditions remain zero-time. A real failed Mechanical attempt consumes its established attempt time through the same explicit completion seam. Successful utility work completes one bounded simple turn, so relevant local infected still receive at most one response before control returns.

No replacement utility state was introduced. Existing generated grid/network topology, `NeighborhoodUtilityRuntimeState`, power-network condition state, portable-generator state, water/well/independent-source facts, powered-workstation availability, lighting/refrigeration consumers, and existing durable persistence remain the truth. The old utility action services remain compatibility/content sources for IDs and requirements, not the canonical player execution route.

## Transitional compatibility boundary

The older runtime/service chain remains instantiated where bootstrap, persistence, vehicles, utilities and later roadmap routes still require it. Migrated gameplay must not extend generalized scheduling. Temporary narrow migration compositions (`Slice7GameMain`, `FortificationGameMain`, `UtilitySimpleGameMain`) should fold away during final consolidation/legacy demolition rather than becoming a new framework.

## Protected game behavior

Preserve throughout the remaining rewrite:

- real procedural persistent island and streaming;
- generated roads/buildings/world content;
- exact item identity, loot and inventory/equipment state;
- zombies and canonical combat consequences;
- bounded local infected actions and distant inactivity;
- canonical Health/injury/death/corpse state;
- survival condition/moodlet state;
- darkness/perception pressure;
- action-from-thing contextual interaction;
- migrated crafting/healing/repair/deconstruction content;
- cooking availability tied to real workstation/utility facts;
- authoritative 0-3 board fortification on existing openings;
- existing infected opening-pressure behavior against boards;
- vehicles;
- generated power/water topology and independent shelter utilities;
- day/night/weather;
- durable New Game / Continue including utility, fortification and material consequences.

A base remains an existing building the player fortified and supplied. No colony/freeform-building system or base-ownership framework.

## Production boot repair and verification

The immediate production boot regression reported after Slice 9 closure was traced to a real GDScript inheritance parse failure: `UtilitySimpleGameMain` redeclared `HAMMER` and `NAILS`, which already exist in parent `FortificationGameMain`. The utility-local constants are now uniquely named, so the production utility composition parses and loads correctly.

The earlier quiet-area infected boot repair remains valid: zero locally hydrated infected is an allowed procedural result and does not itself fail startup.

A second production boot regression was then reproduced from player feedback after island generation: legacy `VehicleGameMain` treated zero plausible parked vehicles within the initial seeding radius as fatal. That is now nonfatal. A valid procedural start may have no nearby vehicle; the vehicle runtime remains available and later world/streaming state may contain vehicles. The production boot verifier now exercises multiple explicit browser-style seeds rather than relying only on headless seed 20001, and guards against restoring the fatal nearby-vehicle requirement.

Current prompt-local verification:

- `game/scripts/ci/verify_immediate_boot.gd`
- `.github/workflows/immediate-production-boot.yml`

The verifier loads `UtilitySimpleGameMain.gd`, loads and instantiates the actual `gameplay.tscn`, and requires the production session to reach `session_boot_ok()`. Exact repaired code-head multi-seed boot run `36524037335` passed and exact repaired code-head Pages run `36524037415` passed.

Per SOP, the next code-changing prompt must retire this prompt-owned verifier/workflow before Slice 10 production edits and create fresh Slice 10 verification.

## NEXT

**Rewrite Slice 10 — vehicles.**

Reconnect existing vehicle enter/exit/drive/turn/reverse/repair/refuel and vehicle-world consequences to the same ordinary direct-action model while preserving the existing real vehicle entities, footprints, inventories/conditions, spawned parking/road placement, dedicated presentation, persistence and world collision truth.

Use the simplest existing authoritative vehicle owners and explicit elapsed-time consequences. Do not invent a vehicle simulation framework, generalized scheduler, traffic AI, new road model or redesign vehicle gameplay. Preserve the intended car/truck footprints and turning/reversing behavior already represented by the project where present. Migrate only what is concretely required to make the player-facing vehicle route canonical and durable.
