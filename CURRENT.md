# Tick Survival Lab — Current State

Status: **release candidate / rewrite complete**

## Working model

PROJECT = Tick Lab  
IDENTITY = turn-based open-world zombie survival  
CORE_LOOP = explore -> scavenge -> fight/escape -> craft/heal -> fortify/supply shelter -> survive  
ACTIVE_REWRITE_SLICE = 15 complete / balance, performance and release acceptance  
NEXT_REWRITE_SLICE = none / rewrite complete  
ROADMAP_CHANGE = true / 2026-09-29

## Operational direction

The rewrite is finished.

Do not invent Slice 16 or reopen architecture work merely to continue rewriting.

Normal work after this checkpoint is:

**release maintenance / gameplay polish / content expansion driven by actual player experience**

Fix concrete player-facing defects, measured performance problems and worthwhile content gaps. Preserve the established canonical architecture unless a real release/maintenance defect proves a change necessary.

## Canonical production path

Real player startup is:

`main.tscn -> StartupMenu -> gameplay.tscn -> ProductionGameMain`

Production gameplay composition remains:

`ProductionGameMain -> VehicleSimpleGameMain -> UtilitySimpleGameMain -> FortificationGameMain -> Slice7GameMain -> TurnBasedGameMain`

Canonical action flow remains:

player action -> direct authoritative consequence -> each relevant local infected acts at most once -> explicit elapsed survival/world time advances -> environment derives -> player control

Fresh script-class resolution is a release requirement. Production must not depend on stale Godot editor/class-cache state.

## Slice 15 release acceptance

Release acceptance used the real StartupMenu path rather than direct internal scene boot.

The focused production scenario runs at a phone-sized 390x844 host viewport and proves:

- fresh script-class cache loads the complete production spine;
- StartupMenu NEW GAME reaches ProductionGameMain;
- session boot succeeds with no boot error;
- player movement works and returns control;
- generated loot can be searched and an exact generated item taken;
- exact food/drink consumption works;
- canonical melee combat works;
- generated contextual door interaction works;
- canonical crafting works;
- local infected work stays bounded by the active roster;
- far persistent infected remain dormant;
- an eight-hour action advances authoritative world time once without zombie catch-up turns;
- inventory/equipment, Health/injury, crafting, first aid, interaction/fortification, utilities, vehicles, world time/weather and perception/lighting owners remain available;
- real SAVE & MENU returns to StartupMenu;
- real StartupMenu CONTINUE restores the same world/player state;
- idle frames advance neither world time nor actor simulation;
- deleted Slice 14 controller architecture is not reconstructed.

## Balance acceptance

The deterministic production release start used for acceptance produced:

- 24 active local infected;
- 44 known persistent infected;
- 13 searchable containers within the near expedition range;
- 23 contained items;
- 5 food/drink consumables;
- 2 medical items;
- 1 construction-material item;
- 18 consumables within the wider expedition range.

Existing survival values were retained rather than tuned without evidence.

Condition channels begin at 60/100. After the representative loop plus an eight-hour elapsed action, observed conditions remained viable:

- satiety 43;
- hydration 69 after drinking;
- rest 46;
- engagement 55;
- comfort 60;
- calm 57.

The evidence did not justify broad loot/combat/survival numeric retuning. Scarcity remains part of the game; one deterministic start lacking a strict `tools`-family item within the measured radius was not treated as proof of a broken resource economy.

## Performance acceptance

The major measured release-performance issue was durable save representation.

Before Slice 15 storage compression:

- initial canonical session: about 11.31 MB raw;
- representative post-expedition/far-region canonical session: about 43.88 MB raw.

The same payloads DEFLATE to roughly:

- initial: 364 KB;
- post-expedition: 1.34 MB.

DurableSessionStore now compresses the existing serialized payload at the file-envelope boundary when compression is beneficial.

Important invariants:

- canonical session schema is unchanged;
- authoritative save truth is unchanged;
- schema-2 persistence ownership is unchanged;
- old pre-Slice-15 uncompressed save envelopes remain loadable;
- checksum validation applies to the stored payload;
- compressed payloads validate/decompress before ordinary session validation.

The real post-expedition primary save measured about 1.34 MB on disk instead of writing the roughly 43.9 MB raw Variant payload.

Streaming/local simulation remained bounded during acceptance:

- one active streaming region at release start;
- local infected actions bounded by the active infected roster;
- far infected dormant;
- idle frames perform no gameplay simulation.

No speculative renderer/world rewrite was introduced.

## Phone/Safari acceptance

Phone/Safari remains first-class.

Production keeps the 640x844 logical game canvas with `canvas_items` stretch. Movement controls are touch-first. Camera controls explicitly suppress synthetic mouse events after touch. Loot/crafting surfaces remain phone-oriented modal panels.

The release verifier boots and plays the real production app with a 390x844 host viewport and completes the core acceptance path through SAVE & MENU / Continue.

No release-blocking phone control/layout defect was found in this slice. Future device-specific polish should be driven by actual device play rather than speculative UI redesign.

## Persistence

Durable schema 2 remains canonical and saves gameplay facts rather than execution machinery.

It persists world/materialization identity, player/domain state, exact inventory/equipment, Health/conditions, loot/world interactions, infected/corpses, vehicles, utilities, weather/world time and refrigeration state.

It does not persist TickKernel execution, combat runtime, perception cache, active streaming membership, active infected roster or controller/render state.

Schema-1 session compatibility and pre-Slice-15 uncompressed file-envelope compatibility remain supported.

Closing/reopening does not advance world time or run catch-up zombie turns.

## TickKernel compatibility

TickKernel remains a noncanonical compatibility remnant for the previously documented limited seams:

- FORAGE timed route;
- older utility generator/power/flashlight/lighting clock/event APIs;
- spatial sound, perception and some phone UI clock/pause APIs;
- infected cohort/opening-pressure compatibility behavior.

Canonical direct gameplay, survival/world-time progression and persistence do not use TickKernel as authoritative time.

Do not make removal of these remaining references a maintenance goal unless one becomes a concrete player-facing or measured performance problem.

## Protected game

Preserve:

- open procedural persistent island and streaming;
- corrected road hierarchy;
- sparse realistic vehicles;
- direct turn-based movement/combat;
- bounded local infected responses and dormant far actors;
- scavenging and exact inventory/equipment;
- Health/injury/death/corpses;
- survival/moodlets;
- contextual doors/windows;
- crafting/cooking/healing;
- repair/deconstruction;
- existing-opening fortification;
- power/water/generators/wells;
- vehicles/cargo/fuel/damage;
- authoritative world time/daylight/weather;
- freshness/refrigeration;
- darkness/light-cone/artificial lighting;
- durable New Game / SAVE / SAVE & MENU / Continue;
- phone/Safari viability.

A base remains an existing building the player chooses to fortify and supply.

No colony management, freeform construction or living survivor society is required for the focused release.

## Verification lifecycle

Slice 15 owns:

- `game/scripts/ci/verify_slice15.gd`
- `.github/workflows/slice15.yml`

The verifier is the current release gate and should remain focused on the real player startup/lifecycle rather than becoming an ever-growing historical integration suite.

Any future code-changing maintenance prompt must follow README_SOPS.md: retire the previous prompt-local verifier/workflow before production edits and create fresh verification focused on that maintenance task.

## NEXT

**No next rewrite slice. Rewrite complete.**

Continue with ordinary release maintenance, gameplay polish and content expansion driven by actual player experience.

Prioritize:

1. production boot/save/Continue defects;
2. controls/usability blockers;
3. broken gameplay actions;
4. measured phone/Safari performance problems;
5. balance problems demonstrated by repeated play;
6. feedback/polish;
7. optional content expansion.

Do not return to architecture work without a concrete player-facing reason.
