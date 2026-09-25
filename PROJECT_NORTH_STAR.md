# Tick Survival Lab — Project North Star

Updated: **2026-09-25**
Status: **canonical game identity; implementation follows ROADMAP.md**

> **Scavenge. Fight. Craft. Survive.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

## Identity

A top-down sprite-based zombie survival game on a persistent generated map. Day/night, weather, scavenging, combat, crafting, vehicles, power and water create practical survival decisions. Your base is an existing building you fortify, supply and maintain, with a generator and well where the site permits them.

The game feels like real time with automatic pauses. Its defining mechanics are shared tick time, action commitment and interruption, simultaneous consequences, mob force and fear. Cheap 2D presentation and bounded world work should support responsive play.

## The player loop

Leave shelter, search somewhere useful, face danger, bring supplies home, recover and improve shelter, then prepare for another trip. A player may relocate, maintain another fortified refuge or remain nomadic. No extraction menu or mandatory home property separates the world into raids.

## Time and combat

- WHEN is the single authoritative clock. Actions have variable durations and consequential phases.
- All effects due at a tick resolve coherently with explicit deterministic conflict rules. Distinct durations remain distinct; rendering and signal ordering do not decide physical outcomes.
- Input commits an action. Its rule defines whether, when and why it can be interrupted, including resource and partial-result consequences.
- Automatic pauses occur at legitimate decision points or qualifying interruptions. The player cannot freely pause/cancel to avoid committed exposure.
- Overlapping actor activity is presented together, not as a queue of enemy turns.
- Mob force creates crowd pressure, trapping and threats to fortified openings. Fear affects actual capability/execution and can recover. Both require readable causes and consequences.
- Hard application pause immediately protects work/life interruptions and browser backgrounding. It freezes pending actions without cancellation, free orders or gameplay changes, then safely resumes them.

## World and persistence

Keep the existing coherent map and generation/streaming architecture. Generation establishes virgin facts once; WHAT and mechanic stores own subsequent reality. Technical partitions never reset places or become separate realities.

Durable save/continue is required. Looted containers, broken windows, fortifications, vehicles, corpses, utilities, conditions, time/weather and environmental stories survive leaving and reopening the game. It is not yet implemented merely because in-session snapshots exist.

Parking must match buildings: driveways, carports, garages and appropriately sized lots with road and entrance access. A deterministic enrichment pass can add these to existing generated layouts where safe without overwriting player changes or regenerating buildings.

Environmental stories use actual physical objects: crashes, dead or turned occupants, failed refuges and abandoned fortified houses. They create salvage, shelter, danger and repair opportunities, persist after interaction and do not need living NPCs.

## Practical survival

Keep useful causal mechanics: inventory/equipment, health/injury, hunger/thirst, rest/fatigue, moodlets, broad skills, crafting/cooking, first aid, repair/reclamation, doors/windows, vehicles and utilities. Balance their rates, costs and feedback around expeditions and repeated days of play.

Power and water sources/networks have real service and damage states. Zombies can attack designated exposed physical components; failures and repairs follow world action. Generators and wells offer useful independence with understandable upkeep.

Fortifying and repairing an existing structure is in scope. Freeform construction, building new houses and settlement management are out of scope. Site-specific generator/well work must not become a general construction engine.

## Explicitly retired ambitions

No living survivor/raider/follower/social runtime, recruitment, household schedules, jobs, deep relationships, evacuation or island-wide epidemic simulation is required for this release. Zombies remain. Cheap initial population data may support generation, but a living society simulation is not a prerequisite for their existence.

This supersedes older North Star promises of freeform bases, personal family/household stories and simulated societal collapse. Shared useful mechanics must survive the retirement of their old consumers.

## Architecture and performance boundaries

- WHERE owns space; WHAT owns current physical truth; WHEN owns time.
- Generation supplies initial facts; rendering presents truth; input expresses intent; UI owns no gameplay state.
- Keep existing grid/footprints, stable identities, deterministic action semantics and modular owners. Do not restart the engine.
- Bound recurring work to relevant actors and changed state. Cache and invalidate perception, batch consequences and avoid whole-world scans and per-actor callback storms.
- Streaming must preserve modifications without monopolizing input/render frames.
- Phone/Safari is first-class. Intentional animation pacing is distinct from computation latency.

## Finish line

The complete scavenging, combat, crafting and survival loop must be playable, balanced, responsive and saved across repeated days. Read ROADMAP.md for required phases and acceptance evidence, PERFORMANCE_NORTH_STAR.md for cost discipline, README_SOPS.md for process and README_CONTEXT.md for the precise next operation. New simulation ambitions do not reopen the release boundary.
