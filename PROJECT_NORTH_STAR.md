# Tick Survival Lab — Project North Star

Updated: **2026-09-27**  
Status: **canonical game/experience identity**

> **Scavenge. Fight. Craft. Survive.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

## Identity

A top-down sprite-based turn-based zombie survival game on a persistent generated island. Day/night, weather, scavenging, combat, crafting, vehicles, power and water create practical survival decisions. Your base is an existing building you fortify, supply and maintain, with a generator and well where the site permits them.

The game deliberately uses a conventional turn structure. Complexity belongs in interacting survival rules and persistent consequences, not in a custom universal execution architecture.

## Player loop

**Leave shelter -> search somewhere useful -> face danger -> bring supplies home -> recover/craft/improve shelter -> prepare for another trip.**

A player may relocate, maintain another fortified refuge or remain nomadic. There is no extraction menu or mandatory home property separating the world into raids.

## Defining rules

- One player action resolves directly, then only relevant local actors receive at most one ordinary action before control returns.
- Current authoritative state decides each sequential consequence; renderer/signal ordering never owns gameplay truth.
- Distant or unloaded actors do not receive individual turns merely because time passed or a frame rendered.
- Crowd congestion, fear, darkness/perception and survival pressure remain gameplay rules where they materially affect play; they are not reasons to restore the retired shared-tick architecture.
- Health, injury, inventory/equipment, corpses, vehicles, utilities and other meaningful consequences belong to persistent authoritative state.
- Survival actions originate from the thing being acted on: inventory items and contextual world objects, not a permanent generic survival-action bar.

## Practical survival

Keep useful causal mechanics: inventory/equipment, health/injury, hunger/thirst, rest/fatigue, moodlets, broad skills, crafting/cooking, first aid, repair/reclamation, doors/windows, vehicles and utilities. Balance rates, costs and feedback around expeditions and repeated days of play.

Power and water have real service/damage states. Fortifying and repairing an existing structure is in scope. Freeform construction, new houses and settlement management are not.

## World and persistence

Keep the existing coherent procedural map and generation/streaming architecture. Generation establishes virgin facts once; authoritative persistent state owns subsequent reality. Technical partitions never reset places or become separate realities.

Durable save/continue is required. Looted containers, broken windows, fortifications, vehicles, corpses, utilities, conditions, time/weather and environmental stories must survive leaving and reopening the game.

Parking must eventually match buildings through deterministic site enrichment: driveways, carports, garages and appropriately sized lots without regenerating established places.

Environmental stories use actual physical objects: crashes, dead/turned occupants, failed refuges and abandoned fortified houses. They create salvage, shelter, danger and repair opportunities without living NPC society simulation.

## Explicitly retired ambitions

No living survivor/raider/follower/social runtime, recruitment, household schedules, jobs, deep relationships, evacuation or island-wide epidemic simulation is required for this release. Zombies remain. Cheap population data may support generation, but living society simulation is not a prerequisite for zombie survival gameplay.

No freeform base construction, colony system, replacement engine, shared universal simulation tick, generalized simultaneous action resolver or replacement WHERE/WHAT/WHEN framework is required.

## Architecture/performance boundary

WorldState and narrow domain owners hold authoritative truth. Generation supplies initial facts; rendering presents truth; input expresses intent; UI owns no gameplay state.

Keep existing grid/footprints, stable identities and deterministic state changes where useful. Bound per-action work to relevant actors and changed state. Phone/Safari is first-class.

Detailed settled ownership belongs in ARCHITECTURE.md; cost-specific guidance is in PERFORMANCE_NORTH_STAR.md and is loaded when relevant rather than as routine active context.

## Finish line

The scavenging, combat, crafting and survival loop is playable, balanced, responsive and durable across repeated days and application restarts.

ROADMAP.md owns release order. CURRENT.md owns the active slice. New simulation ambitions do not silently reopen the release boundary.
