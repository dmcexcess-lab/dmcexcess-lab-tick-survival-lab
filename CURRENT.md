# Tick Survival Lab — Current State

Status: **canonical active working state**

## Working model

PROJECT = Tick Lab  
IDENTITY = turn-based open-world zombie survival  
CORE_LOOP = explore -> scavenge -> fight/escape -> craft/heal -> fortify/supply shelter -> survive  
ACTIVE_REWRITE_SLICE = 11 complete / day-night, weather and world time  
NEXT_REWRITE_SLICE = 12 / open-world simulation boundary  
ROADMAP_CHANGE = true / 2026-09-29

## Authoritative direction

Canonical play remains:

player action -> direct authoritative consequence -> each relevant local actor acts at most once -> explicit elapsed survival/world time advances -> daylight/weather/environment derive -> player control

Shared simulation ticks, generalized simultaneous resolution, universal commitment/interruption and heavyweight WHERE/WHAT/WHEN execution remain legacy.

## Closed canonical routes

Slices 1-10 remain canonical as previously recorded: movement/combat/scavenging/inventory/survival, contextual interaction, craft/cook/heal/repair/deconstruct, existing-opening fortification, power/water utilities, corrected road hierarchy and direct vehicle gameplay all use ordinary authoritative owners and the simple-turn model.

### World time / daylight / weather — Slice 11

Canonical production now boots:

`gameplay.tscn -> Slice11GameMain -> VehicleSimpleGameMain -> UtilitySimpleGameMain -> FortificationGameMain -> Slice7GameMain -> TurnBasedGameMain`

`WorldTimeService` is the authoritative scenario clock for canonical play. It uses the existing Candidate 001 profile (5 ticks/second, 08:00 start, repeating 24-hour day) but no longer depends on TickKernel advancement. Each completed canonical action advances world time to the same explicit elapsed tick already committed by survival. Idle render frames and wall-clock time advance nothing.

`OutdoorAmbientLightService` and the existing DaylightProfile remain daylight truth. Dawn/day/dusk/night and their smooth ambient-light curve derive directly from authoritative world time. Existing physical lighting, light-cone perception, utility/street lights, flashlights and vehicle headlights remain downstream and compose normally.

Existing `WeatherService`, `WeatherState` and `WeatherProfile` remain weather truth. Canonical play switches Weather to explicit coarse world-time advancement rather than TickKernel-scheduled physical transitions. Deterministic profile transitions, analytic wetness, atmospheric optics, acoustic masking, lightning state and GPU weather presentation remain existing owners. Long actions can cross multiple weather transitions in one bounded operation without giving distant/local actors repeated turns.

The HUD now presents compact authoritative day/time/weather information.

Durable sessions persist optional `world_time` state alongside existing weather state. Continue restores exact clock/weather progression. Older compatible saves without the new owner recover canonical time from restored survival elapsed state rather than failing.

Legacy TickKernel may remain instantiated for still-unmigrated compatibility owners, but canonical world-time/weather progression does not advance it.

## Protected game behavior

Preserve throughout the remaining rewrite:

- real procedural persistent island and streaming;
- corrected arterial -> paved secondary -> gravel rural -> dirt local roads;
- sparse realistic vehicle materialization;
- exact item/inventory/equipment truth;
- zombies, combat, health/injury/death/corpses;
- bounded local infected turns and distant inactivity;
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

A base remains an existing building the player fortifies and supplies. No colony/freeform-building system or base-ownership framework.

Recent production repairs remain canonical:

- optional local infected/vehicle absence never fails boot;
- vehicle spawning is sparse rather than one-of-every-kind near spawn;
- MENU, SAVE, SAVE & MENU and Continue remain functional.

## Verification lifecycle

Slice 11 owns:

- `game/scripts/ci/verify_slice11.gd`
- `.github/workflows/slice11.yml`

The focused verifier proves production boot, idle-frame time stability, ordinary and vehicle action advancement exactly once, frozen legacy TickKernel, a bounded eight-hour action, bounded infected responses, daylight phase/brightness derivation, retained perception/artificial-light owners, deterministic coarse weather progression, compact HUD output and real durable snapshot/Continue restoration.

Per SOP, the next code-changing prompt must retire the Slice 11 verifier/workflow before Slice 12 production edits and create fresh Slice 12 verification.

## NEXT

**Rewrite Slice 12 — open-world simulation boundary.**

Only the player’s currently relevant neighborhood should receive individual actor turns. Far/unloaded world state remains persistent data rather than an always-running simulation. Coarse offscreen progression may be calculated only when needed and must not recreate island-wide per-turn work.

Preserve the completed direct-action model, authoritative world time/weather, streaming, persistence, zombies, environmental state and phone/Safari performance. Use existing streaming/materialization boundaries and current authoritative owners rather than inventing a second simulation architecture.
