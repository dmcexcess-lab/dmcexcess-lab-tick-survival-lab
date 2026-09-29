# Tick Survival Lab — Current State

Status: **canonical active working state**

## Working model

PROJECT = Tick Lab  
IDENTITY = turn-based open-world zombie survival  
CORE_LOOP = explore -> scavenge -> fight/escape -> craft/heal -> fortify/supply shelter -> survive  
ACTIVE_REWRITE_SLICE = 12 complete / open-world simulation boundary  
NEXT_REWRITE_SLICE = 13 / persistence migration  
ROADMAP_CHANGE = true / 2026-09-29

## Authoritative direction

Canonical play remains:

player action -> direct authoritative consequence -> each relevant local actor acts at most once -> explicit elapsed survival/world time advances -> daylight/weather/environment derive -> player control

Shared simulation ticks, generalized simultaneous resolution, universal commitment/interruption, detailed offscreen actor simulation and heavyweight WHERE/WHAT/WHEN execution remain legacy/retired.

## Closed canonical routes

Slices 1-11 remain canonical as previously recorded: movement/combat/scavenging/inventory/survival, contextual interaction, craft/cook/heal/repair/deconstruct, fortification, power/water, corrected roads, direct vehicles, authoritative world time/daylight/weather and durable New Game/Continue all use ordinary authoritative owners and the simple-turn model.

### Open-world simulation boundary — Slice 12

Canonical production now boots:

`gameplay.tscn -> Slice12GameMain -> Slice11GameMain -> VehicleSimpleGameMain -> UtilitySimpleGameMain -> FortificationGameMain -> Slice7GameMain -> TurnBasedGameMain`

Individual infected turns are bounded in two existing layers:

1. `WorldStreamingCoordinator` active streamed regions define the eligible neighborhood;
2. `SimpleTurnController.ACTIVE_RADIUS` remains the local action radius inside that neighborhood.

Only infected whose current authoritative WorldState placement is inside active streamed space are supplied to canonical local infected execution. Far/unloaded infected remain persistent entities/Health/world state but receive no ordinary pathfinding, movement, attack, perception/behavior or individual turn work.

Procedural infected resident records are projected once and cached. Streaming-boundary changes hydrate only resident homes that have entered active space. Same-region actions do not rescan the island population.

SimpleTurnController refreshes the active infected roster immediately before local infected responses. Entering a newly active neighborhood therefore makes relevant infected eligible without waking the rest of the island.

Leaving an area does not delete or reset infected. Their identity, placement, Health and meaningful state remain authoritative and durable for return/Continue.

World-time advancement remains separate from actor-turn advancement. Long actions such as eight hours of sleep still create one ordinary bounded local response boundary; they do not execute intermediate zombie turns.

No offscreen zombie wandering/combat/pathfinding/siege/traffic/population simulator was introduced.

## Protected game behavior

Preserve throughout the remaining rewrite:

- real procedural persistent island and streaming;
- corrected arterial -> paved secondary -> gravel rural -> dirt local roads;
- sparse realistic vehicle materialization;
- exact item/inventory/equipment truth;
- zombies, combat, health/injury/death/corpses;
- streaming-active + local-radius infected response boundary;
- dormant far/unloaded actors retaining persistent state;
- survival/moodlets;
- darkness/light-cone perception;
- contextual interaction, crafting/healing/repair/deconstruction;
- existing-opening fortification;
- power/water/generator/well truth;
- vehicle footprints/cargo/fuel/damage/persistence;
- authoritative world time, daylight and weather;
- utility/artificial lighting composition;
- durable New Game / Continue;
- phone/Safari bounded performance.

A base remains an existing building the player fortifies and supplies. No colony/freeform-building system, base-ownership framework or living NPC society.

Recent production repairs remain canonical:

- optional local infected/vehicle absence never fails boot;
- vehicle spawning remains sparse rather than one-of-every-kind near spawn;
- MENU, SAVE, SAVE & MENU and Continue remain functional.

## Verification lifecycle

Slice 12 owns:

- `game/scripts/ci/verify_slice12.gd`
- `.github/workflows/slice12.yml`

The focused verifier boots the real production scene and proves active-roster eligibility, far infected dormancy, bounded per-action actor work, idle-frame inactivity, an eight-hour time jump without repeated infected turns, streaming-boundary activation/deactivation without deleting persistent infected, durable snapshot/Continue preservation, Slice 11 world-time survival and dormant legacy TickKernel behavior.

Per SOP, the next code-changing prompt must retire the Slice 12 verifier/workflow before Slice 13 production edits and create fresh Slice 13 verification.

## NEXT

**Rewrite Slice 13 — persistence migration.**

Adapt durable Continue to the simplified canonical state while preserving procedural seed/world identity, player/inventory/equipment, meaningful infected/corpses, looted/deconstructed/fortified world consequences, vehicles, utilities, authoritative world time/weather and relevant world deltas.

Do not invent a second save architecture. Extend/consolidate the existing DurableSessionStore and ordinary authoritative owner snapshots, remove persistence dependencies on retired execution state where safe, and preserve compatibility/migration for current valid saves.
