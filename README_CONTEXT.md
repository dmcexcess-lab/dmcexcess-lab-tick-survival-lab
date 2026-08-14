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

**Milestone 0.2 — Action Execution Model is complete. Milestone 0.3A — Visual Perception is complete. Milestone 0.3B — Weather Foundation is functionally present; 0.3C Spatial Sound Visualization is next after weather/UI play-test cleanup.**

Canonical source includes map/world/scheduler/player/timing-dummy modules, tactical atlas/tiles, lighting, perception/fog, silent sound helpers, weather state/VFX, split dev/in-game HUDs, and deterministic map/tick/environment/perception smoke tests.

Ownership:

- `TacticalMapGenerator.gd` — authored initial physical map facts.
- `LocalWorldState.gd` — mutable local physical facts such as door state/collision.
- `TickScheduler.gd` — authoritative world tick, active action execution, interruption state, actor ordering, and player-ready state.
- `PlayerActor.gd` — current player location/facing/movement/stance state, base survivor HUD fields, and timing modifiers.
- `TimingDummy.gd` — autonomous scheduled actor used only for scheduler proof/tests and diagnostics; not zombie AI.
- `TacticalLighting.gd` — dependency-free lighting math adapted from First Fire.
- `TacticalSound.gd` — silent sound/localization helpers adapted from First Fire; propagation is pending.
- `TacticalWeather.gd` — current weather profile, visibility/light/sound-mask hooks, temperature hook, indoor thermal buffer, and wind display helper. It does not yet simulate weather patterns.
- `TacticalTiles.gd` — Tick-native renderer for the restored First Fire tactical atlas subset.
- `TacticalPerception.gd` — LOS, facing cone, opaque geometry, light/weather integration, visible cells, and remembered fog state.
- `MapPreview.gd` — development input/presentation harness only; it may present debug controls but must not become the permanent owner of simulation rules.

## Timing semantics

The control model is **real time with automatic pause**, represented synchronously in the current developer harness while authoritative outcomes remain discrete.

1. `player_ready == true` while waiting for a player choice.
2. A player action begins with explicit cost, start tick, interruption policy, optional phases, and payload.
3. `player_ready == false` while that action executes.
4. Other scheduled actors whose `next_tick` falls inside the action window execute in deterministic order.
5. The world advances to action completion unless interruption policy ends it early.
6. The scheduler auto-returns to `player_ready == true` when the action completes, interrupts, cancels, or hard-fails.

Implemented interruption policies: committed, resumable, canceled, and forced failure. Tie ordering is earliest `next_tick`, then lexical actor ID. Actors scheduled exactly on the player action end tick execute before the player becomes ready.

`TickSmoke.gd` proves concurrent actors, resumable reload progress, and committed-through-damage behavior.

## Mobile/touch semantics

The logical viewport is 640×844. The touch deck is a true three-row layout:

- left column: intentional empty top slot → `TURN L` → `CROUCH`;
- right column: `FORWARD` → `TURN R` → `BACK`;
- both turn controls share exactly the same Y position and height;
- forward/back preserve facing;
- crouch is a timed stance action.

**One physical touch must equal one action.** Mobile Safari may synthesize a mouse click after a touch; `MapPreview.gd` suppresses that synthetic click for a short window after handling `InputEventScreenTouch`. Do not remove this guard or reintroduce double-move / 180-degree-turn behavior.

Map tapping remains available. `MENU`/Escape opens the actual pause menu and Web exit uses same-tab browser navigation.

## HUD rule

Keep player-facing information separate from developer controls.

The normal in-game HUD is read-only and currently shows:

- survivor name;
- health;
- fatigue;
- carry weight/capacity;
- in-game time/date/current weather;
- current local temperature;
- indoor/outdoor status;
- outdoor wind speed when outside;
- `Looking at:` for the tile/object directly in front of the player.

The `DEV` overlay contains tick/debug diagnostics plus manual world test controls. Current editable dev fields are HH:MM, MM/DD, and current weather. HH:MM and MM/DD use native Godot `LineEdit` controls so iOS/Safari can summon the keyboard. Developer controls do not cost world ticks.

The current clock harness uses 600 world ticks per displayed in-game minute as a provisional presentation mapping. This is not yet a final global calendar-speed design promise.

Clock design direction: keep the authoritative action tick as a fine physical-opportunity unit (roughly second-scale for action intuition), but allow calendar/day progression to use a separate fixed compression factor. Do not force one action tick to equal one displayed game second; the final calendar multiplier should be tuned once infected timing and body needs are playable.

## Visual/perception semantics

- Tactical ground/wall/door/window/prop/barrel/survivor visuals come from the same-owner First Fire atlas subset.
- The survivor stays visually upright; facing is communicated by the vision cone.
- Existing map light markers feed per-cell lighting.
- Ambient level depends on day/night, theme, indoor/outdoor state and weather light modifier.
- Powered sources switch off when power is unavailable.
- Windows transmit sight and daylight.
- Flashlight is directional.
- Walls, closed doors, and opaque/tall props block LOS/light.
- Player visibility requires facing cone + clear LOS + enough light.
- Fog has unseen and remembered states.

Weather VFX are presentation-only real-time animation and may continue while simulation is paused. Rain, fog, wind debris and storm flash must not mutate authoritative weather/world state.

Weather VFX should not visibly pass through interiors or wall tiles. Current presentation filters rain/debris by outdoor cell and renders fog/storm flashes per outdoor non-wall cell. Weather is drawn beneath fog-of-war so the mask does not reveal hidden room geometry.

## Sound presentation rule

There is **no audible sound playback in Tick Survival Lab**.

Sound still exists as authoritative simulated physical/perception data because zombies, survivors, animals, weather, weapons, doors, vehicles, and environments need to emit and react to sound. The player receives it visually through yellow sound boxes/markers, including uncertain localization.

Do not add music, ambient audio, footsteps, gunshot playback, zombie voices, weather audio, or other actual game sound unless the user explicitly reverses this rule.

## Player/world separation

The persistent world is conceptually separate from the player character. The world/save owns seed, calendar, outbreak history, actors, zombies, structures, construction/destruction, items, corpses, vehicles, crops, settlements, infrastructure, and persistent consequences. The player is one mortal actor record within that world.

On player death, the user can eventually either play a new survivor in the same continuing world or start a new world seed. A later player may encounter the previous player's corpse, base, stash, family, vehicles, and consequences.

## Map/world direction

The imported First Fire map foundation remains an authored-layout catalog of 20×18 physical locations: Back Alley, Gas Station, Residential House, Apartment, Corner Store, Warehouse Yard, and Drainage Wash. Each can describe ground, indoor regions, walls, doors, windows/glass, obstacles, props, barrels, light markers, player spawn, and exits.

Do not replace this with a second incompatible map language. Long-term hierarchy should compose it into:

**tile/object → building/location → local area/block → biome/district → large island world**

The island mixes city, suburban, commercial/industrial, rural/farm, and woods/wilderness biomes. Destroyed/bombed bridges and failed crossings can show that the region once connected to a larger world.

## Long-term simulation direction

See `DESIGN.md`. Intended systems include persistent infected; visualized spatial sound; deterministic weather; dangerous timing-driven combat; body-region wounds and amputation; hunger/thirst/fatigue; inventory/loot/equipment; use-based skills and learning media; destructible/free-build environments; farming/crafting; autonomous survivors and animals; emergent settlements; patrols and supply routes; vehicles; infrastructure reclamation; and eventual outbreak epicenter/spread/response plus occupation/family starts.

## Near-term scope

After current weather/HUD mobile play-test cleanup, **0.3C Spatial Sound Visualization** should create tick-owned sound events, propagation/attenuation through physical cells, door/window/wall occlusion, weather masking, uncertain source localization, and yellow visual sound markers. Persistent infected can then consume the same perception + silent-sound model on the scheduler.

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

## Procedural region foundation

The current large-map stress slice uses `ProceduralRegionGenerator.gd` to build a deterministic 64×64 local region. It is deliberately a region/chunk prototype, not the final island size. The generator assigns residential, commercial, downtown, woods, and rural zones from seeded spatial centers, lays arterial/secondary roads, then applies biome-specific parcel/structure rules. Existing physical map facts (ground, indoor rectangles, walls, doors, glass, obstacles, props, lights, exits) remain the shared schema.

Scaling rule: world generation may cover large deterministic regions, but rendering, lighting, perception and eventually actor simulation must stay local/chunked around active areas. The final island should be composed from deterministic regions/chunks rather than represented as one permanently active mega-array.

The Web harness currently defaults to a 64×64 procedural region and exposes player-controlled map zoom. Zoom changes presentation only; world coordinates, movement cost, LOS and simulation geometry do not change.
