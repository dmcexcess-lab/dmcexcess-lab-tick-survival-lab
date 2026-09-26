# Tick Survival Lab — Project North Star

Updated: **2026-09-26**  
Status: **canonical game/experience identity**

> **Scavenge. Fight. Craft. Survive.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

## Identity

A top-down sprite-based zombie survival game on a persistent generated map. Day/night, weather, scavenging, combat, crafting, vehicles, power and water create practical survival decisions. Your base is an existing building you fortify, supply and maintain, with a generator and well where the site permits them.

The game feels like real time with automatic pauses. Its defining mechanics are shared tick time, action commitment and interruption, simultaneous consequences, mob force and fear. Cheap 2D presentation and bounded world work support responsive play and deeper persistent simulation.

## Player loop

**Leave shelter -> search somewhere useful -> face danger -> bring supplies home -> recover/craft/improve shelter -> prepare for another trip.**

A player may relocate, maintain another fortified refuge or remain nomadic. There is no extraction menu or mandatory home property separating the world into raids.

## Defining rules

- WHEN is the single authoritative clock. Actions have meaningful durations and commitment/interruption rules.
- Effects due on the same tick resolve coherently; renderer/signal ordering does not decide physical outcomes.
- Automatic pauses occur at legitimate decision points. Hard application pause protects real-life interruption without granting tactical cancellation.
- Mob force makes crowds physically dangerous through congestion/pressure, not merely stacked attack rolls.
- Fear changes capability/execution through the canonical condition model and can recover.
- Persistent world truth survives streaming and, when Phase 3 is complete, application/browser closure.
- Survival actions originate from the thing being acted on: inventory items and contextual world objects, not a permanent generic survival-action bar.

## Practical survival

Keep useful causal mechanics: inventory/equipment, health/injury, hunger/thirst, rest/fatigue, moodlets, broad skills, crafting/cooking, first aid, repair/reclamation, doors/windows, vehicles and utilities. Balance rates, costs and feedback around expeditions and repeated days of play.

Power and water have real service/damage states. Fortifying and repairing an existing structure is in scope. Freeform construction, new houses and settlement management are not.

## World and persistence

Keep the existing coherent map and generation/streaming architecture. Generation establishes virgin facts once; WHAT and mechanic stores own subsequent reality. Technical partitions never reset places or become separate realities.

Durable save/continue is required. Looted containers, broken windows, fortifications, vehicles, corpses, utilities, conditions, time/weather and environmental stories survive leaving and reopening the game.

Parking must eventually match buildings through deterministic site enrichment: driveways, carports, garages and appropriately sized lots without regenerating established places.

Environmental stories use actual physical objects: crashes, dead/turned occupants, failed refuges and abandoned fortified houses. They create salvage, shelter, danger and repair opportunities without living NPC society simulation.

## Explicitly retired ambitions

No living survivor/raider/follower/social runtime, recruitment, household schedules, jobs, deep relationships, evacuation or island-wide epidemic simulation is required for this release. Zombies remain. Cheap population data may support generation, but living society simulation is not a prerequisite for zombie survival gameplay.

No freeform base construction, colony system or replacement engine is required.

## Architecture/performance boundary

WHERE owns space; WHAT owns current physical truth; WHEN owns time. Generation supplies initial facts; rendering presents truth; input expresses intent; UI owns no gameplay state.

Keep existing grid/footprints, stable identities, deterministic action semantics and modular owners. Bound recurring work to relevant actors and changed state. Phone/Safari is first-class.

Detailed settled ownership belongs in `ARCHITECTURE.md`; cost-specific guidance is in `PERFORMANCE_NORTH_STAR.md` and is loaded when relevant rather than as routine active context.

## Finish line

The scavenging, combat, crafting and survival loop is playable, balanced, responsive and durable across repeated days and application restarts.

`ROADMAP.md` owns release order. `CURRENT.md` owns the active slice. New simulation ambitions do not silently reopen the release boundary.
