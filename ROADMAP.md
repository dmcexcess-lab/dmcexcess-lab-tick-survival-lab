# Tick Survival Lab — Roadmap to a Finished Survival Game

Updated: **2026-09-25**
Status: **release scope reset; implementation and acceptance remain open**

This roadmap replaces the previous “core roadmap closed” assessment. The September 25 user direction is authoritative over older scope in subsystem documents. Existing code is a foundation to finish, not proof that the revised requirements are accepted. This update changes the plan only; it does not claim the runtime has been changed.

## 1. The game we are finishing

**Scavenge. Fight. Craft. Survive.**

A sprite-based zombie survival game on a persistent map, with day/night, weather, useful buildings, vehicles, electricity and water. Your base is an existing house or other building you fortify, supply and maintain. A generator and a well give it practical independence.

The distinctive combat experience is shared tick time, interruptible versus committed actions, simultaneous consequences, mob force and fear. It feels like real time with automatic pauses, but the player cannot freely choose when a tactical pause occurs.

The core loop is:

**Leave shelter → search a useful location → face danger → bring supplies home → recover, craft and improve the shelter → prepare for the next trip.**

There is no required extraction state or mandatory home property. Moving shelter or remaining nomadic is allowed. Persistence includes closing the application and continuing later.

## 2. Scope boundary

### Required for this release

- Existing persistent generated map, coherent roads/buildings, readable exploration and bounded streaming.
- Shared tick clock, variable action duration, automatic decision pauses, explicit interruption/commitment rules and simultaneous tick resolution.
- Zombies with readable perception, pursuit, combat and attacks on relevant physical openings/infrastructure.
- Mob force and fear as consequential combat mechanics.
- Scavenging, building-specific loot, carrying, equipment, crafting/cooking, repair, reclamation and useful progression.
- Health/injury, food, water, rest/fatigue, moodlet deterioration and recovery balanced around expeditions.
- Existing-building fortification, storage, beds, generator and well use/maintenance.
- Day/night and weather with bounded, understandable effects on play.
- Power and water features with real service state, damage, failure and recovery.
- Contextual parking and vehicles, including carports, garages and parking lots added to existing generated building layouts.
- Persistent environmental story scenes: crashes, abandoned refuges and fortified houses with dead or turned occupants.
- Durable save/continue, safe application pause, desktop and mobile/Safari usability.
- A finite release acceptance pass covering the complete loop.

### Removed from this release

- Living survivor NPCs, companions/followers, raiders, recruitment and dialogue systems.
- Household/job/schedule/relationship simulation as a runtime requirement.
- Society simulation, evacuation, emergency response and island-wide causal epidemic propagation.
- Freeform base construction, new player-built houses, colonies and settlement management.
- New architecture phases or world-generation rewrites without a concrete release blocker.

Zombies remain active game actors. “Abandon simulation” retires the broader world/society model; it does not remove ticks, physical consequences, persistence, needs, utilities or weather. Existing population data may remain a cheap generation input where useful, but live resident simulation must not be required to spawn or run zombies.

Removing systems must preserve shared health, inventory, movement, perception and tick owners still used by the player and zombies. This is a bounded retirement and integration task, not a replacement engine.

## 3. Combat and time contract

### One clock, simultaneous resolution

- WHEN/TickKernel remains the single authoritative clock.
- Every active actor's due effects at a tick resolve through a coherent consequence boundary. Multi-tick actions retain their distinct due ticks.
- Evaluate relevant intents against a stable view, resolve conflicts deterministically, and publish a coherent result. Renderer frames and callback order must not decide winners.
- Movement, attacks, damage/death, crowd force, openings and interruption require explicit same-tick ordering. In particular, simultaneous lethal attacks and contested movement must have defined outcomes.
- Simultaneous does not mean everyone has the same action duration. It means all effects due together share a consistent resolution, and overlapping activity is presented together rather than as individual enemy turns.
- Existing same-tick movement batching is a starting point, not evidence that all combat effects are simultaneous already.

### Commitment and interruption

Each release action must declare its duration, consequential phases, interruptible/committed windows, qualifying interruption causes, resource expenditure, and partial/failure result. Apply this to movement, attacks, item use, first aid, crafting, repairs, vehicle actions, sleep and long actions.

The player chooses at a legitimate decision boundary. Once an action begins, arbitrary cancellation or a tactical pause must not erase its exposure. A qualifying interruption may end an action or open a decision according to its rule; minor events must not create accidental free turns. Longer choices expose the survivor to more world time.

Hard application pause is separate: menu/focus loss/backgrounding freezes everything immediately, preserves the pending action, and grants no new tactical order or cancellation. Resume continues that action safely. Menus must not provide a loophole to execute gameplay changes while time is frozen.

### Mob force and fear

Crowds must create physical pressure beyond stacked damage: congestion, trapping, displacement/overwhelm where permitted, and collective pressure on openings. Obstructions and fortifications resist force; actors never phase through blocked cells. Exact force formulas, displacement/conflict rules and resistance values are bounded implementation design work before coding.

Fear must change meaningful capability or action execution under danger and recover when safety is restored. Reuse canonical condition/moodlet state; do not add a parallel fear meter with conflicting truth. Define the actual triggers, effects, recovery and interaction with action commitment before implementation. Avoid unlimited fear/force chains that deny all recovery or repeatedly charge the same event.

**Acceptance:** ordinary player controls can demonstrate quick versus slow commitments, a valid interruption, an uninterruptible window, simultaneous contested outcomes, mob pressure, fear and recovery, and safe hard pause. All outcomes are explainable from visible feedback and the action rules.

## 4. Delivery order and acceptance

Phase 1 is **COMPLETE** as of 2026-09-25. Phases 2–8 remain **OPEN**. Existing features should be reused and tested through their actual play paths. A phase closes only when its listed player outcomes are demonstrated; partial technical work stays partial. Work remains bounded under README_SOPS.md.

### Phase 0 — Establish the release contract

**Plan completed in this documentation update.** Reconcile game identity, scope and handoff; preserve old decisions as explicitly superseded history. Keep the existing executable as the recovery baseline. No code was removed or changed by this phase.

### Phase 1 — Retire live survivor/society dependencies — COMPLETE 2026-09-25

Production no longer hydrates or activates living survivor cohorts, survivor AI/perception/hearing, neutral/follower/raider roles, social interaction providers/handlers, or survivor-to-infected conversion. The infected path now composes the non-dynamic `ActiveInfectedCohortService`; resident-derived generation/identity data remains available where the zombie path needs it. Dormant survivor/social implementation files remain only as recovery/history substrate.

Focused production verification kept the eight infected cohort intact, found zero live non-infected survivor NPCs, completed an ordinary player commitment, and confirmed world time, the player inventory container and utilities still operate. Same-run-class CI evidence changed boot from 19,780,576 µs to 19,563,557 µs; the measured player commitment retained 8 infected evaluations while removing 2 survivor evaluations / 43,198 µs of survivor behavior work from the pre-change sample. These are single-run observations, not a stable performance benchmark. Zombie/perception performance remains Phase 2 work.

### Phase 2 — Make shared-tick combat responsive and coherent

**Progress — commitment-window slice complete 2026-09-25.** WHEN actions can now declare a persistent `commit_offset_ticks` point of no return. Before that boundary their original CANCELABLE/RESUMABLE policy applies; at and after it they are effectively COMMITTED. Melee strikes wire contact as that boundary, so interruptible light attacks can be stopped during wind-up but cannot be retroactively canceled after contact. Existing fully committed heavy attacks/shoves retain their behavior. The focused production verifier also protects same-tick phase batching and snapshot restoration. Phase 2 remains open for full simultaneous consequence ordering, zombie callback/perception cost, mob force, canonical fear effects, presentation coherence and crowded-fight performance.

**Progress — simultaneous melee consequence slice complete 2026-09-25.** Same-tick melee strike targets and damage are now frozen before mutation, HP damage is aggregated per target, every valid same-tick contact still records its own injury/impact, and lethal death/corpse transition is deferred until that consequence batch closes. Mutual lethal blows therefore both land and both actors die; multiple attackers do not lose already-due hits because the target reaches zero HP during that tick. Phase 2 remains open for contested movement/shove ordering, mob force, canonical fear tuning/effects, zombie callback/perception cost, coherent presentation and crowded-fight performance.

**Progress — causal movement/shove/crowd-pressure transition slices complete 2026-09-25.** Canonical movement evaluates due trajectories from one stable incoming occupancy state, distinguishes conditional origin release from destination arrival, resolves exclusive claims from frozen physical state, allows compatible release chains, and treats reciprocal ordinary walks as head-on edge conflicts. Combat shove seals forced trajectories into the same late spatial batch; shove versus movement and lethal same-tick death ordering are resolved causally without hidden initiative. Parallel forced inputs now add, opposing cardinal force subtracts, and residual force after overcoming one body can propagate through one packed actor and combine with downstream pressure. Static geometry terminates the chain and fixed-point occupancy prevents phasing. Zombie behavior remains simple intention selection; crowd jams and surges are simulation outcomes rather than authored formations. Phase 2 remains open for deeper pile compression/force transmission, knockdown or crush consequences, canonical fear, zombie callback/perception cost, presentation coherence and crowded-fight performance.

Implement the combat/time contract above using the existing kernel. Address per-actor callback fan-out, repeated perception queries and coherent presentation. Preserve due-tick causality and input ownership. Finish targeting, hit/miss/range/occlusion rules, damage, death/corpses, injury feedback, weapon costs and clear failure reasons. Include mob force and fear rather than postponing them as optional polish.

Profile streaming separately. Use existing bulk terrain improvements; resolve measured transition work without regenerating places or removing world consequences. Do not hide CPU stalls with animation.

The recorded baseline is p50 364 ms, p95 488 ms, p99 513 ms per accepted action, with an 8.76-second outlier and about 10 active NPCs. These were headless diagnostic measurements, not mobile timing.

**Engineering targets carried forward from the measured diagnostic:** ordinary decision simulation approximately under 50 ms for the current roughly 10–12 actor case, no gameplay-blocking frame above 100 ms in the acceptance route, and no multi-second transition hitch. Separate intentional presentation duration from CPU time. Report hardware/runtime and verify actual Safari response. Tune the maximum relevant zombie crowd within a declared, measured budget; the small baseline is not sufficient proof of mob combat performance.

**Done when:** the combat demonstrations pass, the ordinary route and crowded fight meet the declared budgets, transitions do not freeze play, and actor outcomes appear concurrent rather than as serial NPC turns.

### Phase 3 — Save, leave and continue

Use existing authoritative stores/snapshots to implement a versioned durable session format. Include seed/generation version, world mutations, inventory/containment, actors/zombies/corpses, conditions/skills, vehicles, structures/fortifications, utilities, loot/story placement, day/weather and necessary time/action state. Preserve stable identities and deterministic continuation.

Provide clear New Game and Continue behavior, an explicit durable-save path and automatic safe checkpoints. Do not rely solely on a browser unload event. Define how an interrupted pending action is restored without cancellation exploits, duplicated consumption or duplicated rewards. Detect invalid/incompatible saves and preserve the last valid save rather than silently overwriting it. Surface browser storage failure honestly.

**Done when:** save, close the browser/application, reopen and resume; moved vehicles, looted containers, broken windows, repaired utilities, fortified shelter and survivor state all remain. Repeating save/load or crossing regions produces no duplication/reset. Backgrounding and hard pause preserve pending commitments.

### Phase 4 — Finish the expedition and fortified-house loop

Wire and verify scavenging, carrying, item use, crafting/cooking, first aid, sleep/rest, repairs, deconstruction and door/window interactions through normal controls. Retain Awareness, Stealth, Mechanical and Survival; use concrete tools/materials, state prerequisites and real action time.

Fortification is work on an existing building. A usable shelter has storage, rest, reinforced openings and provision for a generator and well. Generator/well acquisition, installation or repair must be accessible through bounded site-specific interactions and costs, not a general construction system.

Power and water must have readable source/service/failure states. Define which exposed components zombies can attack, how they select them, what damage interrupts and how the player repairs or replaces them. Damage must arise from world action, not an arbitrary offscreen outage roll. A well's power dependence, if any, must be stated; grid-independent water must not accidentally acquire a new dependency.

**Done when:** the player can supply and fortify a house, operate a generator and well, experience a zombie-caused infrastructure failure and restore service. Crafting, repairs and supplies meaningfully improve later expeditions. No new house-building UI or settlement simulation is introduced.

### Phase 5 — Put vehicles where vehicles belong

Add a deterministic site-enrichment pass keyed to persistent building/parcel identity. It can extend already generated building layouts with suitable driveways, carports, garages and parking lots without regenerating buildings or changing existing identities.

Fit additions to available land, orientation, setbacks, road connections, doors, utilities and neighboring footprints. Garages/carports are generated site features, not player freeform construction. Building type and available parking capacity determine plausible vehicle classes, occupancy, headings and condition. Homes, apartments, shops, workshops and farms should differ. Preserve the existing transport classes and their real movement, storage, fuel/lock/repair rules; fix release-blocking defects rather than expanding the vehicle simulation.

On an existing saved map, apply enrichment once with a version/placement record. Preserve visited/modified areas, player property, parked vehicles and loot. If a site cannot be enriched safely, leave it unchanged; never bulldoze or relocate existing facts. Version and persist both applied and intentionally skipped results as appropriate so reloads do not reroll a site.

**Done when:** representative residential, commercial and farm sites have believable, usable vehicle access; cars do not occupy walls, blocked entrances or impossible parking. Moving or stripping a vehicle persists. Revisit/reload never duplicates or respawns it.

### Phase 6 — Add persistent environmental stories

Build a bounded initial library of scenes using real objects and existing mechanics:

- Road crashes: valid road placement, damaged vehicles, cargo, bodies and optional zombies.
- Fortified houses: actual boards/barricades, damage, dead or turned occupants and variable supplies.
- Abandoned refuges: signs of departure, depleted stores and usable or failed equipment.
- Repair opportunities: a garage/workshop vehicle with useful tools or missing essentials.

Give each scene site requirements, weighted rarity, physical placement rules, loot/danger ranges and a persistent scene identity. Scene choices occur once; returning does not reset them. Avoid stacking incompatible scenes or blocking essential routes without a traversable alternative. Stories must not silently overwrite prior player modifications.

The scene communicates through the environment. There are no living quest-giver NPCs or resurrected society simulation. Valuable scenes need not all be traps; fortified houses need not all be jackpots.

**Done when:** scenes make sense spatially, offer real salvage/shelter/danger choices, remain changed after interaction and save/load, and use the same combat/crafting/repair systems as ordinary play.

### Phase 7 — Balance repeated days of play

Balance begins during earlier phases; this is the integrated tuning pass after the required content exists. Keep values in their existing owning data/configuration paths. Avoid scattering contradictory overrides across UI and action code.

| Area | Required balance work | Evidence of success |
|---|---|---|
| Loot | Building-specific categories, quantities, rarity, tools, food, medicine, fuel and repair materials; inspect initial inventory too | A plausible first day is possible, buildings have distinct value, and later trips remain worthwhile |
| Loot persistence | Define initial placement and one-time story salvage explicitly; no automatic reset on streaming/revisit/load | Cleared locations stay cleared; no duplication or infinite local resource exploit |
| Needs/moodlets | Food/water use, fatigue, injury, fear, environmental effects, onset/escalation/recovery and action penalties | Status creates expedition decisions without constant clicking or unavoidable deterioration loops |
| Combat | Weapon reach/duration/cost/damage, crowd density, force, fear, injury and escape options | The player can understand why a commitment was risky; equipment helps without eliminating danger |
| Crafting/shelter | Recipe inputs, tool availability, duration, yields, fortification durability and upkeep | Repairs/crafting solve practical problems and shelter provides useful recovery |
| Vehicles/utilities | Spawn condition, keys/fuel/repair needs, generator consumption, well access and infrastructure damage | Transport and independence are earned, useful and maintainable |
| Time/weather/travel | Day/night length, visibility, weather severity, trip distances, building density and downtime | Day and night change plans; exploration produces decisions rather than mostly empty travel |

Do not invent resource respawn or a new endlessly renewable economy to compensate for bad initial distribution. If renewable sources are needed, use explicit existing world mechanics with clear costs and state. Exact rates and difficulty targets are tuning work, not invented completion claims in this roadmap.

**Done when:** a complete first-day route and a multi-day campaign exercise food, water, injury/fear recovery, shelter, vehicle progression and useful expeditions without debug grants. Record shortages, surplus, deaths/escapes, action costs and recovery; change values based on those observations.

### Phase 8 — Acceptance and release

Perform a bounded release acceptance operation on the same candidate build. This is a planned end-to-end play exercise, not permission to revive the retired historical CI fleet.

Required scenarios:

1. New Game → scavenge → eat/drink → craft/treat → fortify → sleep → next-day expedition.
2. A small fight and a crowd encounter demonstrating commitment, interruption, simultaneous outcomes, force, fear and escape/death.
3. Repair/use a vehicle, leave it elsewhere, revisit it and restore it through save/continue.
4. Generator/well use, real zombie infrastructure damage and repair.
5. Day/night and weather changes during ordinary play, including long actions.
6. A crash and fortified/abandoned-house scene, interacted with and revisited after reload.
7. Multiple streaming boundaries with persistent changes and acceptable action/transition performance.
8. Desktop and mobile/Safari input, readable controls/status, no queued-input overshoot, safe backgrounding/hard pause and durable Continue.

Fix blockers in their existing owners, then rerun the affected scenario. Release requires no unresolved reproducible crash, save-loss, progression-blocking defect or ordinary-play freeze on the declared target scenarios. Report known nonblocking limitations explicitly. Export/deploy success proves publication; it does not prove gameplay acceptance.

**Finished means the required survival loop works, remains saved, feels responsive and is enjoyable across repeated days.** No optional new system is needed to explain why release has not happened.

## 5. Execution and completion discipline

- Reuse current owners; no reboot, duplicate clock, parallel inventory, second health stack or presentation-owned consequences.
- One bounded player outcome per operation. Update its status and evidence in the handoff; do not label an entire phase finished because a helper or test passed.
- Maintain the finite release checklist above. New ideas are outside this release unless the user explicitly trades scope.
- Follow README_SOPS.md for approvals, prompt-local verification and exact-head deployment. This roadmap does not silently approve the review's proposed testing-process changes.
- No routine historical whole-project suite or twelve-seed matrix. Focused generation cases must demonstrate the changed behavior; integrated acceptance occurs in the designated release operation.
- Keep docs tied to implementation: “planned,” “implemented,” and “accepted” are different states.

## 6. Next operation

**Phase 2: implement the shared-tick combat contract and make the surviving zombie path responsive and coherent.** Begin from the current infected cohort/kernel/combat seams. Define and implement simultaneous due-tick consequence ordering, interruptible versus committed action windows, mob force and canonical fear effects, while measuring zombie decision/perception/presentation cost. Keep the operation bounded under README_SOPS.md; do not reopen the retired survivor/social runtime.

Save/continue is a required release phase, not optional polish. Parking enrichment, environmental stories and balancing are required scope, not an invitation to restart global world generation.
