# Tick Survival Lab — Roadmap to Beta

Status: **canonical priority roadmap**

Current game identity:

> **Sprite-based zombie survival game.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

Each independently owned phase follows `README_SOPS.md` and **DESCRIBE -> APPROVE -> IMPLEMENT -> VERIFY**. New explicit user direction supersedes older ordering.

## Current milestone state

- **Phase 1 — COMPLETE.** Physical items, freshness, semantic UI, interaction/reach, content breadth and world presentation foundations are implemented.
- **Phase 2 / System 32 Crafting — COMPLETE + CI VERIFIED.** Crafting transforms exact persistent inputs into exact persistent outputs through real broad-skill checks and concrete physical tools/materials.
- **World/island performance recovery — COMPLETE + HUMAN ACCEPTED baseline.** Preserve responsive decision-pause input, full physical-light window and stateless LOS.
- **Phase 3 / System 33 Power + Water — IMPLEMENTED + AUTOMATED VERIFIED; HUMAN PLAYTEST PENDING.** Preserve real local substations, roadside feeder trees/service drops, island-wide municipal plant and persistent rural wells. Wastewater/sewer/septic is retired.
- **Phase 4 / System 34 Physical Survival — IMPLEMENTED + AUTOMATED VERIFIED; HUMAN PLAYTEST PENDING.** Health, hunger, thirst, Rest and canonical Fatigue are live. Fatigue is 0 rested -> 100 exhausted; there is no parallel live Stamina pool.
- **Phase 5 Moodlets — IMPLEMENTED + AUTOMATED VERIFIED; HUMAN PLAYTEST PENDING.** Moodlets are derived warnings, not duplicate state.
- **Phase 6 Four Skills / Survival Interaction Foundation — IN PROGRESS.** Four-skill migration, skill-aware crafting/search, primitive resources/recipes and bounded outdoor foraging are implemented. The final consumer-closure pass is next after vehicle human acceptance or newer explicit direction.
- **Phase 7 / System 36 Vehicles — IMPLEMENTED + AUTOMATED VERIFIED; HUMAN PLAYTEST PENDING.** Persistent playable vehicles are deployed from `SYSTEM_DESIGNS/36_VEHICLES.md`.

## Phase 6 — Four broad skills and real interactions

Canonical skills are exactly:

- **Awareness**
- **Stealth**
- **Mechanical**
- **Survival**

Shared philosophy:

> **concrete physical prerequisite + owning world state + relevant broad skill + real WHEN time**

Skill changes competence; it never conjures a missing tool/material or replaces another system's truth.

### Implemented Phase-6 foundation

- schema-v2 four-skill persistent state and legacy migration;
- shared deterministic action-boundary `ActorSkillCheckService`;
- Mechanical/Survival-aware System-32 crafting;
- Survival-aware persistent-container scavenging without rerolling physical contents;
- real primitive loot semantics and bounded primitive Survival recipes;
- **System 35 Outdoor Foraging:** finite deterministic local outdoor stick/stone opportunities using real sky exposure, terrain and generated natural props; WHEN + Survival resolution; successful outputs become real persistent items and enter personal inventory when carry admission allows, with a physical loose-item fallback at hard capacity;
- **System 36 Mechanical vehicle consumers:** real matching keys, Mechanical hot-wiring, bounded repair, real installed cargo-rack modification, weighted cargo, finite fuel and real vehicle target interactions.

### Final Phase-6 closure after vehicle human acceptance

Perform one comprehensive skills/crafting/items/usable-object run-through covering:

1. cooking through real ingredients/tools/heat sources and Survival;
2. first aid through Health/Injury ownership and Survival;
3. richer Mechanical vehicle component maintenance where real parts have real owners/consumers;
4. Mechanical repair of broken world objects and deconstruction/reclamation through actual target owners;
5. real fire/ignition through tinder/fuel/ignition prerequisites and Survival;
6. primitive crafted outputs connected to actual combat/tool/fire consumers rather than item-name special cases;
7. food/drink/medicine usable-item consumers through real owning systems;
8. usable world objects such as beds, sinks/water sources, refrigeration, stoves/ovens, lights/switches, workbenches, generators/utilities, doors/windows and vehicles;
9. real Awareness and Stealth gameplay consumers;
10. construction restricted to **reinforcing existing doors/windows and repairing broken objects** — no freeform base-building system.

Hunting is not a separate skill; it emerges from Awareness, Stealth, Survival knowledge and the concrete weapon/trap/tool used.

## Phase 7 — System 36 Vehicles

Status: **IMPLEMENTED + AUTOMATED VERIFIED; HUMAN PLAYTEST PENDING.**

Implemented vehicle classes:

- cars;
- trucks;
- motorcycles;
- bicycles;
- skateboards.

Canonical movement/handling now live:

- **skateboard:** actor-like 2-cell smooth-surface movement, no added Fatigue, no fuel, nearly silent;
- **bicycle:** 3-cell vehicle movement, no fuel, quiet, real Fatigue cost;
- **motorcycle:** powered 3-cell movement, lower fuel use, low storage, easier Mechanical hot-wire than cars;
- **car/truck:** powered 3-cell movement with larger storage and higher fuel use by class;
- bicycle/motorcycle/car/truck use **12 typed vehicle headings at 30-degree increments** over deterministic integer-grid rasters;
- true vehicle classes require **2 cells of stopping/braking distance**;
- no separate Driving skill; hot-wiring/repair/modification belong to Mechanical.

Also implemented:

- sparse persistent vehicle state keyed by WHAT entity ID;
- bounded generated parked vehicles on plausible materialized road/driveway/parking/pavement cells near the canonical playable start;
- enter/exit and mounted input routing without replacing ordinary on-foot movement;
- real matching key entities, locks and persistent hot-wire bypass;
- compact finite fuel by class;
- real vehicle inventory containers with weight/capacity and live STORE/TAKE controls;
- real cargo-rack installation that keeps the component item persistent;
- bounded Mechanical repair using real tools/materials;
- crash body damage, real occupant HP damage and spatial impact/movement sound;
- powered headlights merged into the existing physical-light owner;
- dedicated vehicle renderer and System-36 owning CI gate.

Explicit remaining closure instead of fake completion:

- exact arbitrary-angle rotated collision polygons are not authoritative; typed 30° headings use deterministic raster movement with the existing cardinal WHAT footprint vocabulary;
- fuel cans are whole-item transfer units, not partial-liquid simulation;
- vehicle population is currently a bounded canonical playable-area seeding pass, not an island-wide streaming population source;
- battery/wheel items exist physically but dedicated replacement consumers are not yet implemented;
- broader modifications remain future real-component consumers;
- human browser/game-feel acceptance is pending.

## Phase 8 — Actor/NPC AI, combat and causal outbreak

Scope includes infected/zombie AI, survivors/followers/raiders, melee/firearms, conversations, population/coarse distant behavior and the causal outbreak/collapse. AI receives observer knowledge, not hidden world truth.

## Phase 9 — Final graphics/UI overhaul -> Beta

Audit desktop plus phone/Safari layout, inventory/menu/icon consistency, interaction readability, world art, lighting/weather/sound presentation, obsolete DEV UI, accessibility and final performance. Completion of Phase 9 is the planned Beta gate.

## Performance architecture gate — always active

Do not add frame-driven condition/skill/resource processing, per-item/per-actor simulation timers, recurring whole-world scans or fake presentation-owned truth. Prefer action/event boundaries, analytical state, revisions, bounded local queries and cached shared derivations.

## Current next operation

Human-play the deployed **System 36 Vehicles** build and repair any concrete vehicle/game-feel/browser issues found. After that acceptance gate—or a newer explicit user direction—perform the comprehensive skills/crafting/items/usable-object closure pass described above. New explicit user direction supersedes this ordering.
