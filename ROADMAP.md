# Tick Survival Lab — Roadmap to Beta

Status: **canonical priority roadmap**

Current game identity:

> **Sprite-based zombie survival game.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

Each independently owned phase follows `README_SOPS.md` and **DESCRIBE -> APPROVE -> IMPLEMENT -> VERIFY**. New explicit user direction supersedes older ordering.

## Current milestone state

- **Phase 1 — COMPLETE.** Physical items, freshness, semantic UI, interaction/reach, content breadth and world presentation foundations are implemented.
- **Phase 2 / System 32 Crafting — COMPLETE + CI VERIFIED.** Crafting transforms exact persistent inputs into exact persistent outputs, now through real broad-skill checks and concrete physical tools/materials.
- **World/island performance recovery — COMPLETE + HUMAN ACCEPTED baseline.** Preserve responsive decision-pause input, full physical-light window and stateless LOS.
- **Phase 3 / System 33 Power + Water — IMPLEMENTED + AUTOMATED VERIFIED; HUMAN PLAYTEST PENDING.** Preserve real local substations, roadside feeder trees/service drops, island-wide municipal plant and persistent rural wells. Wastewater/sewer/septic is retired.
- **Phase 4 / System 34 Physical Survival — IMPLEMENTED + AUTOMATED VERIFIED; HUMAN PLAYTEST PENDING.** Health, hunger, thirst, Rest and canonical Fatigue are live. Fatigue is 0 rested -> 100 exhausted; there is no parallel live Stamina pool.
- **Phase 5 Moodlets — IMPLEMENTED + AUTOMATED VERIFIED; HUMAN PLAYTEST PENDING.** Moodlets are derived warnings, not duplicate state.
- **Phase 6 Four Skills / Survival Interaction Foundation — IN PROGRESS.** The canonical four-skill migration, skill-aware crafting/search, primitive resource/items/recipes and bounded outdoor foraging are implemented. Additional real action consumers remain.

## Phase 6 — Four broad skills and real interactions

Canonical skills are exactly:

- **Awareness**
- **Stealth**
- **Mechanical**
- **Survival**

The shared philosophy is:

> **concrete physical prerequisite + owning world state + relevant broad skill + real WHEN time**

Skill changes competence; it never conjures a missing tool/material or replaces another system's truth.

### Implemented Phase-6 foundation

- schema-v2 four-skill persistent state and legacy six-skill migration;
- shared deterministic action-boundary `ActorSkillCheckService`;
- Mechanical/Survival-aware System-32 crafting;
- Survival-aware persistent-container scavenging without rerolling physical contents;
- real primitive loot semantics and bounded primitive Survival recipes;
- **System 35 Outdoor Foraging:** finite deterministic local outdoor stick/stone opportunities using real sky exposure, terrain and generated natural props; WHEN + Survival resolution; successful outputs become normal loose physical items; no passive respawn/global scan.

### Remaining bounded Phase-6 integrations

Implement only when their owning systems are real:

1. connect primitive crafted outputs to actual combat/tool/fire consumers rather than item-name special cases;
2. real first aid through Health/Injury ownership;
3. Mechanical repair and deconstruction/reclamation through the actual target owners;
4. vehicle hot-wiring once vehicle ownership exists;
5. fire-starting/ignition through a real fire owner;
6. real Awareness and Stealth gameplay consumers.

Hunting is not a separate skill; it emerges from Awareness, Stealth, Survival knowledge and the concrete weapon/trap/tool used.

## Phase 7 — Vehicles

Target classes: cars, trucks, motorcycles, bicycles and skateboards. Vehicle hot-wiring belongs to Mechanical once the vehicle owner exists.

## Phase 8 — Actor/NPC AI, combat and causal outbreak

Scope includes infected/zombie AI, survivors/followers/raiders, melee/firearms, conversations, population/coarse distant behavior and the causal outbreak/collapse. AI receives observer knowledge, not hidden world truth.

## Phase 9 — Final graphics/UI overhaul -> Beta

Audit desktop plus phone/Safari layout, inventory/menu/icon consistency, interaction readability, world art, lighting/weather/sound presentation, obsolete DEV UI, accessibility and final performance. Completion of Phase 9 is the planned Beta gate.

## Performance architecture gate — always active

Do not add frame-driven condition/skill/resource processing, per-item/per-actor simulation timers, recurring whole-world scans or fake presentation-owned truth. Prefer action/event boundaries, analytical state, revisions, bounded local queries and cached shared derivations.

## Current gameplay gate / next operation

Human-play the current Web build on WebGL2 desktop and phone/Safari, specifically:

1. Fatigue/rest/needs/health/moodlet feel;
2. four-skill crafting and persistent-container scavenging;
3. `FORAGE NEARBY` usability, finite depletion and physical stick/stone pickup;
4. movement responsiveness and protected lighting/LOS/startup behavior;
5. representative fresh-seed System-33 power/water/well presentation.

If no defect is found, the next bounded implementation is to connect the now-real primitive resources/crafted outputs to the next **actual consumer** without inventing combat/tool/fire effects prematurely. New explicit user direction can supersede this ordering.
