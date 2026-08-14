# Tick Survival Lab — Project Context

> **MANDATORY CONTEXT RULE FOR GPT:** At the start of every new user prompt requesting code or repository changes, fetch and reread both `README_SOPS.md` and this file from current `main`, then inspect the current files relevant to that prompt. Do this once per prompt/change request, not before every edit inside the same coherent batch.

## Identity

Working repo/project name: **Tick Survival Lab**.

GitHub repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

This is an original Godot 4 top-down zombie-apocalypse survival simulation. Project Zomboid is a systemic-scope reference only; do not copy its proprietary code, art, maps, UI, names, text, or content.

First Fire is a same-owner source project. Reusable tactical/physical-world work may be adapted after inspection, but Tick must not inherit First Fire's camp/menu/expedition architecture.

Durable design references: `DESIGN.md`, `ROADMAP.md`, and `FIRST_FIRE_REUSE.md`.

## Current milestone

**Milestone 0.2 — Action Execution Model is complete. Milestone 0.3A — Visual Perception is complete. Milestone 0.3B — Spatial Sound is next.**

Canonical source now includes:

```text
game/
  assets/
    tactical_atlas.svg
  scripts/
    TacticalMapGenerator.gd
    LocalWorldState.gd
    TickScheduler.gd
    PlayerActor.gd
    TimingDummy.gd
    TacticalLighting.gd
    TacticalSound.gd
    TacticalTiles.gd
    TacticalPerception.gd
    MapPreview.gd
    ci/
      MapSmoke.gd
      TickSmoke.gd
      EnvironmentSmoke.gd
      PerceptionSmoke.gd
```

Ownership:

- `TacticalMapGenerator.gd` — authored initial physical map facts.
- `LocalWorldState.gd` — mutable local physical facts such as door state/collision.
- `TickScheduler.gd` — authoritative world tick, active action execution, interruption state, actor ordering, and player-ready state.
- `PlayerActor.gd` — current player location/facing/movement mode and timing modifiers.
- `TimingDummy.gd` — tiny autonomous scheduled actor used only for scheduler proof/tests and developer diagnostics; not zombie AI.
- `TacticalLighting.gd` — dependency-free lighting math adapted from First Fire.
- `TacticalSound.gd` — dependency-free sound/localization helpers adapted from First Fire; real propagation still pending.
- `TacticalTiles.gd` — Tick-native renderer for the restored First Fire tactical atlas subset.
- `TacticalPerception.gd` — LOS, facing cone, opaque geometry, light integration, visible cells, and remembered fog state.
- `MapPreview.gd` — development input/presentation harness only.

## Implemented timing semantics

The control model is **real time with automatic pause**, represented synchronously in the current developer harness while authoritative outcomes remain discrete.

1. `player_ready == true` while waiting for a player choice.
2. A player action begins with explicit cost, start tick, interruption policy, optional phases, and payload.
3. `player_ready == false` while that action executes.
4. Other scheduled actors whose `next_tick` falls inside the action window execute in deterministic order.
5. The world advances to action completion unless interruption policy ends it early.
6. The scheduler auto-returns to `player_ready == true` when the action completes, interrupts, cancels, or hard-fails.

Implemented interruption policies: committed, resumable, canceled, and forced failure. Tie ordering is earliest `next_tick`, then lexical actor ID. Actors scheduled exactly on the player action end tick execute before the player becomes ready.

`TickSmoke.gd` proves concurrent actors, resumable reload progress, and committed-through-damage behavior.

## Implemented visual/perception semantics

The First Fire tactical visual foundation is no longer deferred.

- Ground, wall, door, window, prop, barrel, and directional survivor visuals come from a same-owner First Fire tactical atlas subset under `game/assets/tactical_atlas.svg`.
- Existing map light markers feed real per-cell lighting.
- Ambient level depends on day/night, theme, and indoor/outdoor state.
- Powered sources switch off when power is unavailable.
- Windows transmit sight and daylight.
- A directional flashlight profile demonstrates carried cone lighting.
- Walls, closed doors, and opaque/tall props block line of sight and light.
- Player visibility requires facing cone + clear LOS + sufficient light at distance.
- Fog has two states: unseen and remembered-but-not-currently-visible.
- Turning, moving, doors, time, power, and flashlight state recalculate perception.

`PerceptionSmoke.gd` proves closed/open door occlusion, forward-vs-behind cone behavior, directional flashlight contribution, and persistent fog memory.

Developer controls include WASD/arrows, Tab walk/run, E/Space/Enter door, R reroll, F flashlight, 4 day/night, 5 power, and 1/2/3 scheduler timing proofs.

## Player/world separation

The persistent world is conceptually separate from the player character. The world/save owns seed, calendar, outbreak history, actors, zombies, structures, construction/destruction, items, corpses, vehicles, crops, settlements, infrastructure, and persistent consequences. The player is one mortal actor record within that world.

On player death, the user can eventually either play a new survivor in the same continuing world or start a new world seed. A later player may encounter the previous player's corpse, base, stash, family, vehicles, and consequences.

## Map/world direction

The imported First Fire map foundation remains an authored-layout catalog of 20×18 physical locations: Back Alley, Gas Station, Residential House, Apartment, Corner Store, Warehouse Yard, and Drainage Wash. Each can describe ground, indoor regions, walls, doors, windows/glass, obstacles, props, barrels, light markers, player spawn, and exits.

Do not replace this with a second incompatible map language. Long-term hierarchy should compose it into:

**tile/object → building/location → local area/block → biome/district → large island world**

The island mixes city, suburban, commercial/industrial, rural/farm, and woods/wilderness biomes. Destroyed/bombed bridges and failed crossings can show that the region once connected to a larger world.

## Long-term simulation direction

See `DESIGN.md`. Intended systems include persistent infected; spatial sound; dangerous timing-driven combat; body-region wounds and amputation; hunger/thirst/fatigue; inventory/loot/equipment; use-based skills and learning media; destructible/free-build environments; farming/crafting; autonomous survivors and animals; emergent settlements; patrols and supply routes; vehicles; infrastructure reclamation; and eventual outbreak epicenter/spread/response plus occupation/family starts.

## First Fire reuse policy

Before recreating a major tactical/world subsystem, inspect current First Fire for same-owner reusable work. Port coherent rules only after removing `Game`, encounter UI, camp, expedition, objective, and save-schema coupling.

Already reused/adapted: tactical map schema, tactical atlas/tile rendering subset, lighting helpers, FOV/LOS/fog concepts, and sound/localization helpers.

## Near-term scope

Next is **0.3B Spatial Sound**: create tick-owned sound events, propagation/attenuation through physical cells, door/window/wall occlusion, and uncertain source localization. Then persistent infected can consume the same perception + sound model on the scheduler.

Preferred dependency direction:

**map/data → persistent world state → tick scheduler/rules → actor simulation → presentation/input**

Rules get one durable owner. UI must not own simulation state. The map generator must not become a dumping ground for combat, inventory, AI, saves, or social systems.

## Source-of-truth order

1. Newest explicit user instruction
2. Current `main` repository state
3. `README_SOPS.md`
4. This file
5. `DESIGN.md` / `ROADMAP.md` / `FIRST_FIRE_REUSE.md`
6. Human `README.md`
7. Conversation memory only as supporting context

## Continuous deployment

`.github/workflows/pages.yml` is the permanent build/deploy gate. It validates canonical files, imports/parses with Godot 4.7.1, runs deterministic map/tick/environment/perception smoke tests, starts the real scene headlessly, exports Web, uploads the artifact, and deploys GitHub Pages.
