# Tick Survival Lab — Current State

Status: **canonical active working state**

## Working model

PROJECT = Tick Lab  
IDENTITY = turn-based open-world zombie survival  
CORE_LOOP = explore -> scavenge -> fight/escape -> craft/heal -> fortify/supply shelter -> survive  
ACTIVE_REWRITE_SLICE = 10 complete / road hierarchy + vehicles  
NEXT_REWRITE_SLICE = 11 / day-night, weather and world time  
ROADMAP_CHANGE = true / 2026-09-29

## Authoritative direction

Keep the game; retire the experimental execution architecture.

Canonical play remains:

player action -> direct consequence -> each relevant local actor acts at most once -> ordinary survival/time consequence -> return player control

Shared simulation ticks, generalized simultaneous resolution, universal commitment/interruption and heavyweight WHERE/WHAT/WHEN execution remain legacy.

## Closed canonical routes

Slices 1-9 remain canonical as previously recorded: movement/combat/scavenging/inventory/survival, contextual interaction, craft/cook/heal/repair/deconstruct, existing-opening fortification, and power/water utility interaction all route through ordinary authoritative owners and the simple-turn model.

### Road hierarchy + vehicles — Slice 10

Virgin island generation now establishes the transportation backbone before settlement access:

- four terrain-routed cross-island four-lane arterial routes form the sparse major network;
- small towns and rural crossroads attach through paved two-lane access;
- rural settlement access is gravel;
- local rural/scattered/farm/home lanes and spurs are dirt;
- paved production road surfaces materialize as asphalt with markings;
- gravel and dirt remain unpainted.

The existing procedural island, terrain-aware routing, settlement/building generation, deterministic projection/materialization and streaming architecture remain authoritative. Existing persistent worlds are not regenerated merely by loading them.

Production now boots:

`gameplay.tscn -> VehicleSimpleGameMain -> UtilitySimpleGameMain -> FortificationGameMain -> Slice7GameMain -> TurnBasedGameMain`

Canonical vehicle enter/exit/start/hotwire/forward/turn/reverse/brake/repair/modify/refuel/cargo actions no longer advance the legacy TickKernel timed vehicle route. They validate current authoritative state, directly commit the existing VehicleState/world placement/inventory owners, feed explicit elapsed time through the simple-turn survival seam, allow each relevant local infected at most one ordinary response, and return control.

Existing VehicleProfileCatalog/VehicleHeading geometry remains truth: cars retain the existing 1x3 footprint, trucks 2x3, ordinary 90-degree turns use the established three-cell turn path, reverse remains available, and collision/fuel/damage consequences remain authoritative. Vehicle cargo, condition, fuel, ignition/key/hotwire state, dedicated presentation and durable vehicle snapshots remain the same owners.

A valid start may contain zero nearby vehicles. That condition must never fail production boot.

The wider arterial geometry exposed a stale utility-support placement assumption during integration. Utility span support search was made robust to the corrected road width without changing utility topology/state ownership.

## Transitional compatibility boundary

The older runtime/service chain remains instantiated where bootstrap, persistence, utilities and later roadmap routes still require compatibility. Legacy vehicle services may remain present as content/consequence owners, but their generalized timed execution path is not canonical player execution.

Temporary narrow migration compositions (`Slice7GameMain`, `FortificationGameMain`, `UtilitySimpleGameMain`, `VehicleSimpleGameMain`) are migration debt and should fold away during legacy demolition rather than becoming a new generalized framework.

## Protected game behavior

Preserve throughout the remaining rewrite:

- real procedural persistent island and streaming;
- corrected arterial -> paved secondary -> gravel rural -> dirt local road hierarchy;
- generated settlements/buildings/world content;
- exact item identity, loot and inventory/equipment state;
- zombies and canonical combat consequences;
- bounded local infected actions and distant inactivity;
- canonical Health/injury/death/corpse state;
- survival condition/moodlet state;
- darkness/perception pressure;
- contextual action-from-thing;
- crafting/healing/repair/deconstruction;
- existing-opening fortification;
- power/water topology, generators, wells and failures;
- vehicle entities, footprints, cargo, fuel, damage and persistence;
- day/night/weather;
- durable New Game / Continue.

A base remains an existing building the player fortified and supplied. No colony/freeform-building system or base-ownership framework.

Recent production repairs remain canonical:

- UtilitySimpleGameMain has no inherited constant collision;
- an empty locally hydrated infected set is valid;
- zero nearby vehicles is valid;
- New Game must not fail merely because optional local content is absent;
- MENU, SAVE, SAVE & MENU and Continue remain functional.

## Verification lifecycle

Slice 10 owns:

- `game/scripts/ci/verify_slice10.gd`
- `.github/workflows/slice10.yml`

The focused verifier exercises real island generation across explicit seeds, production-facing paved/gravel/dirt materialization, settlement connection to the arterial hierarchy, actual production gameplay boot, and generated vehicle enter/start/move/turn/reverse/repair/refuel/cargo/exit through the direct simple-turn route. It also guards against canonical vehicle movement returning to TickKernel scheduling.

Per SOP, the next code-changing prompt must retire the Slice 10 verifier/workflow before Slice 11 production edits and create fresh Slice 11 verification.

## NEXT

**Rewrite Slice 11 — day/night, weather and world time.**

Reconnect authoritative world-time progression to the ordinary turn-based model. Define explicit elapsed-time advancement for canonical actions and derive day/night, ambient light and weather from authoritative world time without restoring a generalized action scheduler or per-frame whole-world simulation.

Preserve the existing daylight/weather content, darkness/perception gameplay, utility lighting, persistence and phone/Safari performance. Use the simplest existing authoritative time/weather owners and migrate only the concrete production routes required for durable canonical behavior.
