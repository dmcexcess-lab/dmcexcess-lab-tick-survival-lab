# Tick Survival Lab — Roadmap to Beta

Last reconciled: **2026-09-09**

Status: **core feature roadmap closed; beta-candidate acceptance/polish remains defect-driven**

Current game identity:

> **Sprite-based zombie survival game.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

New explicit user direction supersedes older ordering. `README_SOPS.md` remains process authority; `README_CONTEXT.md` records the exact executable checkpoint and next operation.

## Current milestone state

The older roadmap lagged materially behind the executable. The repository now has real production owners and player-facing consumers for the major systems that were still listed below as future work.

- **Phase 1 — COMPLETE.** Persistent WHERE/WHAT/WHEN foundation, procedural island/streaming, rendering, inventory/equipment, loot, freshness, semantic UI, reach/interaction, day/night, weather, physical light/sound and broad world/content foundations are live.
- **Phase 2 / Crafting — COMPLETE.** Exact persistent inputs become exact persistent outputs through real tools/materials, broad-skill checks and WHEN. Cooking recipes use real ingredients and heat-source requirements.
- **Phase 3 / Power + Water — COMPLETE CORE.** Real local substations, roadside feeder/service infrastructure, grid-independent municipal water service and deterministic rural wells are live. Wastewater/sewer/septic and generated rivers are intentionally retired.
- **Phase 4 / Physical Survival — COMPLETE CORE.** Health/injury, hunger, thirst, Rest, Fatigue, food/drink consumption, furniture rest/sleep and first aid are connected to player UI/actions. Fatigue remains 0 rested -> 100 exhausted; no parallel live Stamina pool exists.
- **Phase 5 / Moodlets — COMPLETE.** Moodlets derive from canonical actor condition rather than duplicating state.
- **Phase 6 / Four Skills + Real Interactions — COMPLETE CORE.** Awareness, Stealth, Mechanical and Survival have real consumers. Crafting, scavenging, foraging, repair, deconstruction/reclamation, first aid, primitive survival outputs, vehicle maintenance and world-object interactions use concrete prerequisites plus owning state plus broad skill plus real WHEN.
- **Phase 7 / Vehicles — COMPLETE CORE.** Skateboard, bicycle, motorcycle, car and truck transport, cargo, keys/locks/hot-wire, fuel, repair, cargo-rack install, crash consequence and headlights are live. Current exact-cell/typed-heading fidelity is canonical; richer component replacement is optional expansion.
- **Phase 8 / NPC AI, Combat + Causal Outbreak — COMPLETE CORE.** Melee/firearms, resident-backed infected, observer-scoped sight/hearing, environmental opening pressure, resident survivor projection, neutral survivors, recruitable followers, hostile raiders, contextual talk/recruit/dismiss and same-identity local survivor -> infected transition are production-composed. See `SYSTEM_DESIGNS/40_SURVIVOR_SOCIAL_OUTBREAK.md`.
- **Phase 9 / Beta Gate — CORE DELIVERY REACHED; ACCEPTANCE/POLISH ONGOING.** The production game is exported to Web/Pages with desktop/mobile interaction work, real sprites/rendering, lighting/weather/sound, inventory/menu controls and protected CI. Remaining work is concrete human-play defects, browser/mobile acceptance, balance/art/content tuning and optional fidelity—not an undiscovered missing gameplay architecture phase.

## Canonical four skills

The skill schema is exactly:

- **Awareness**
- **Stealth**
- **Mechanical**
- **Survival**

Shared rule:

> **concrete physical prerequisite + owning world state + relevant broad skill + real WHEN time**

Skill changes competence. It never conjures a missing tool/material or replaces another system's truth.

Hunting is not a separate skill; it emerges from Awareness, Stealth, Survival knowledge and the concrete weapon/trap/tool used.

Construction remains deliberately restricted: **no freeform base-building system.** Player construction is reinforcement/repair of existing physical structures such as doors/windows and broken objects.

## Core systems now connected

The executable includes real player-facing paths for:

- generated island roads/towns/rural buildings, coastline, utilities and streaming;
- day/night, weather, light, shadows, powered streetlights and spatial sound;
- inventory, equipment, loot/search, food/drink/medicine, freshness and carrying;
- sleep/rest, Health/injury, condition/Fatigue and first aid;
- crafting/cooking, primitive resources, foraging, repair and deconstruction/reclamation;
- doors/windows including open, smash/break, board/reinforce, climb and environmental pressure;
- generators, switches/lights, sinks/water sources, beds/chairs and other usable objects;
- Awareness/Stealth/Mechanical/Survival consumers;
- skateboards, bicycles, motorcycles, cars and trucks with class-specific movement and maintenance;
- melee/firearms and actor-generic Health/death consequences;
- eight resident-backed active infected using observer-scoped perception/hearing and shared WHEN;
- four resident-backed survivor NPC exemplars with neutral/follower/raider roles;
- contextual survivor conversation and recruit/dismiss interactions through the normal interaction panel;
- causal local infection from real infected combat impacts, preserving the exact resident identity as it changes cohorts;
- generic infected pressure against real doors/windows without a second zombie-only damage/navigation stack.

## Intentional fidelity backlog — not core blockers

Do not call these implemented until they are actually built, but do not confuse them with an unfinished core game either:

- detachable/replacement vehicle battery and wheel consumers;
- arbitrary-angle rotated vehicle collision polygons beyond the current deterministic typed-heading raster model;
- partial-liquid fuel quantities rather than whole transfer units;
- island-wide streamed parked-vehicle population beyond the bounded playable-area population;
- broader vehicle modifications and salvage/collision detail;
- persistent deep relationships, factions, diplomacy, long-form dialogue and authored quest content;
- large survivor settlements/follower command interfaces;
- island-wide aggregate offscreen epidemic propagation between distant households;
- more sophisticated route planning if a concrete generated-world navigation failure proves the bounded local movement policy insufficient;
- additional art variety, balance/content density and accessibility polish.

Any future implementation must continue using existing owners rather than adding duplicate clocks, population counts, health stacks, inventory truth, perception truth, or presentation-owned gameplay state.

## Performance architecture gate — always active

Do not add frame-driven condition/skill/resource processing, per-item/per-actor simulation timers, recurring whole-world scans or fake presentation-owned truth. Prefer action/event boundaries, analytical state, revisions, bounded local queries and cached shared derivations.

NPCs use the shared player-decision/WHEN cadence. Boot, stream activation, perception changes and sound changes may update intention, but they must not grant free autonomous world-tick actions.

## Beta acceptance operation

With the core feature roadmap closed, the next work is **human-play acceptance and defect-driven polish**, not another architecture phase:

1. play the deployed build on desktop and mobile/Safari;
2. record only concrete failures in interaction, UI readability, rendering, streaming, controls, pacing, combat/NPC behavior, balance or content presentation;
3. repair each failure in its existing owner with a fresh prompt-local verifier;
4. keep optional fidelity requests separate from bugs/core closure;
5. preserve exact-head CI/Pages verification and handoff in `README_CONTEXT.md`.

A green automated build does not substitute for human game-feel acceptance, but there is no longer a roadmap item that requires inventing a new core gameplay subsystem before that acceptance can proceed.
