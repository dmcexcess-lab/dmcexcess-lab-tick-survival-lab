# Tick Survival Lab — Project Context / Routing Index

> **MANDATORY:** At the start of every prompt requesting repository/code changes, read current `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, this file, `DESIGN_WORKFLOW.md`, `DESIGN_DECISIONS.md`, and the active system design(s). Read `MODULAR_REBUILD_MASTER_DESIGN.md` for architecture work, but where its older static-raid assumptions conflict with the newer North Star/decision log, the newer documents win. Inspect current relevant code/history when applicable.

## 1. Game identity

Primary shorthand:

> **Ultima-style turn-based mini Zomboid.**

Canonical identity/philosophy: `PROJECT_NORTH_STAR.md`.

Core principle:

> **Mini means reduced complexity, not reduced consequence or mood.**

The target is a readable top-down tile/grid survival world with persistent systemic consequences, variable-duration tick actions, strong atmosphere, simplified-but-meaningful survival mechanics, and extraction-style expedition risk inside a persistent open world.

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

## 2. Current architectural phase

The project remains in **Phase 0: modular design / architecture freeze**.

The currently deployed runtime under `game/scripts/reboot/` is **frozen/deprecated reference code**. Do not extend it as the target architecture.

The last mature pre-clean-rewrite visual/system baseline remains golden recovery commit:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

Use that commit to recover exact solved behavior/art semantics where relevant. Do not restore its monolithic presentation inheritance architecture wholesale.

No new modular runtime system has yet been approved for implementation.

## 3. Major direction change now in force

The earlier design centered on:

**static strategic map -> generated tactical raid -> extraction -> staging**.

That is **no longer the long-term physical-world foundation**.

Current direction:

- logically continuous **persistent open world**;
- world may stream/load partitions internally, but partitions are implementation/storage details;
- roads, utilities, parcels and other large structures are planned globally so local chunk boundaries cannot invent mismatched geometry;
- generation creates/materializes world data, then persistent world state owns changes;
- extraction-shooter influence survives as expedition risk/reward: leave safety with gear at risk, scavenge/explore, decide when to return, get home alive, keep what you recovered;
- a base is fundamentally a physical location in the same world, not a disconnected stash universe.

Cross-system decisions and rationale: `DESIGN_DECISIONS.md`.

## 4. Persistent world / outbreak direction

Long-term world planning should be top-down:

**world seed -> geography -> towns/rural districts -> roads -> utilities -> parcels/addresses -> building footprints/types -> households/businesses/population -> local detail/materialization**.

A local streaming region must not independently decide how a world-spanning road connects. It asks the global plan what exists at those coordinates.

The world should eventually support a **causal outbreak simulation**:

- pre-collapse population and households;
- homes/jobs/workplaces/schedules/relationships;
- infection/spread;
- awareness/emergency response;
- evacuation/population movement;
- infrastructure degradation/collapse.

Simulation resolution may become coarser at distance for performance. Persistent causality matters more than calculating every invisible footstep.

## 5. Player story direction

The player character should eventually be a real person embedded in that generated pre-outbreak world.

Customizable/derived starting context may include:

- identity/appearance;
- occupation and actual workplace;
- home/property;
- spouse/partner, children, parents, roommates or other household members;
- friends/coworkers/important relationships;
- pets;
- vehicle/resources consistent with the story;
- skills/traits/background;
- outbreak start timing/scenario.

Family/known people should be persistent actors whose situation comes from the outbreak simulation, not only scripted quest markers.

## 6. Current spatial direction

The project currently favors an **invisible authoritative tactical grid** for simplicity and determinism.

Current cross-system decisions:

- actors move cell-to-cell;
- grid lines need not be visible;
- props/fixtures occupy one or more whole cells;
- directional objects carry N/E/S/W orientation;
- renderer may rotate suitable art in 90-degree increments or use explicit facing variants when rotation looks wrong;
- generation/world data stores semantic object + facing, never atlas-specific orientation assumptions;
- four-way actor facing is the simple baseline for graphics, vision, vulnerability and interactions;
- sub-cell/free movement is rejected unless a concrete gameplay need later justifies the extra complexity.

**Still unresolved:** wall/door/window representation as occupied cells versus cell-edge structures. This must be decided in the Spatial Model design before implementation.

## 7. Tick/action / pause direction

The core gameplay remains **turn-based through authoritative variable-duration ticks/actions**.

Intent:

1. simulation pauses while the player is choosing;
2. player commits one action;
3. action consumes explicit world ticks;
4. other scheduled actors/systems may act during those elapsed ticks;
5. when the player is ready for another choice, simulation automatically pauses again.

Slow actions create exposure. Injuries, fatigue, equipment and skill can change action duration/capability.

Held movement may repeatedly request discrete movement actions; releasing input means no further action is queued and the game returns to auto-pause.

### Real-life interruption requirement

The user must be able to put the game down immediately if work/customer attention is required.

A hard application pause must freeze simulation safely and must not count as a tactical failure. Explicit pause/menu and mobile/browser lifecycle handling should be designed around that requirement.

## 8. Mini-Zomboid simplification rule

For every survival system ask:

> What meaningful player decision does the deeper simulation create?

Implement the smallest causal model that preserves that decision, its consequence and its mood.

Current health example:

- injury type;
- body region;
- coarse severity (minor/serious/critical concept; exact labels TBD);
- treatment/stabilization required by type/severity;
- healing/worsening state;
- derived action/mobility/use penalties.

Do not simulate blood volume merely because a deeper game does if severity/treatment consequences preserve the important decision.

Systems likely deserving comparatively more depth because they define the game include tick/action timing, persistence, perception/vision, lighting, spatial sound, coherent world generation and outbreak/population simulation.

## 9. Extraction/base direction

Extraction-shooter influence is now a **gameplay loop layered over the open world**, not proof that the world must be instanced.

Typical loop:

**physical safety/base -> choose gear/objective -> leave into persistent world -> scavenge/explore/avoid/fight -> accumulate risk/loot -> return alive -> unload/use recovered resources**.

A base may start as the player's actual home and later become any physical location the player secures and develops.

Higher-level base/community screens may summarize physical facts later, but storage/workspaces/power/water/vehicles/residents/etc. should remain grounded in world state.

## 10. Modularity / development process

Canonical process: `DESIGN_WORKFLOW.md`.

> **DESCRIBE -> USER APPROVES -> IMPLEMENT -> VERIFY.**

Global invariants:

1. Main/root is composition/wiring only.
2. Every independently replaceable system has a focused owner/public contract.
3. One major system per implementation slice by default.
4. Push back when scope spans too many systems.
5. No placeholder/fake systems presented as complete.
6. Ask targeted clarification when material ambiguity remains after inspection.
7. Generator is an input to world state, not owner of persistent reality.
8. Rendering never owns simulation truth.
9. Input requests actions; it does not implement world rules.
10. Art is not physics.
11. Phone/Safari remains first-class.
12. Important decisions/lessons do not live only in chat.

## 11. Documentation ownership / anti-drift structure

- `PROJECT_NORTH_STAR.md` — short permanent game identity/philosophy; read frequently.
- `DESIGN_DECISIONS.md` — cross-system decisions and rationale; append/supersede rather than erase history.
- `README_CONTEXT.md` — current phase/status/routing index only.
- `README_SOPS.md` — how GPT works on this repo; living coding/GitHub/Godot/Safari lessons.
- `DESIGN_WORKFLOW.md` — approval/scope/clarification process.
- `MODULAR_REBUILD_MASTER_DESIGN.md` — broad architecture inventory; currently contains some older raid/static-map assumptions and must yield to newer North Star/decision entries where conflicts exist.
- `SYSTEM_DESIGNS/*.md` — detailed canonical design for each subsystem.
- `SYSTEM_DESIGNS/README.md` — approval/status ledger.
- `CHANGELOG.md` — repository change history.

The goal is that future work can recover **why**, **what**, **current status**, and **implementation contract** without reading thousands of unrelated lines.

## 12. Current design sequence

The earlier `RaidMapSpec` draft started too far up the stack and is now a recovery/reference draft, not the next foundation.

Recommended foundational design sequence before new runtime code:

1. **00A Spatial Model** — grid/cells, facing, footprints, structures/openings, global coordinates.
2. **00B Tick / Action / Pause Kernel** — variable action time, scheduling, auto-pause, hard real-life pause.
3. **00C Persistent World Identity / State** — persistent entities/changes, generation vs world ownership, streaming boundaries as implementation detail.
4. **00D Population / Household / Outbreak / Player-Story foundations** — persistent people, homes/jobs/relationships, coarse-vs-detailed simulation seams.
5. Then define the generalized local world/map data contract that rendering, collision and generation consume.

No runtime implementation begins merely because this sequence exists. Each major system is discussed and approved separately.

## 13. Graphics recovery truth

The richer pre-rewrite artwork remains intact. The mature visual stack came from golden `TacticalTiles.gd` combining six atlases plus four directional player sprites.

Golden semantic renderer blob:

`3d8a0a70ac983408bb48f58fc659dfb07e216ed3`.

When art/rendering is designed, recover exact semantic selection behavior into standalone catalog/render modules. Directional clutter/furniture support should allow semantic N/E/S/W orientation with renderer-owned rotation or explicit alternate-facing images.

## 14. Source-of-truth order

1. Newest explicit user instruction
2. `PROJECT_NORTH_STAR.md`
3. `DESIGN_DECISIONS.md` (newer entries supersede older ones)
4. Current repository state
5. `README_SOPS.md`
6. `DESIGN_WORKFLOW.md`
7. This context index
8. APPROVED active `SYSTEM_DESIGNS/*.md`
9. `MODULAR_REBUILD_MASTER_DESIGN.md` where compatible with newer direction
10. Golden recovery commit for exact historical behavior
11. Older design documents where compatible

## 15. Current next action

**Design only. Do not code the new runtime yet.**

Next recommended discussion: **00A Spatial Model**, beginning with the already-favored invisible tactical grid and explicitly resolving wall/door/window representation before anything depends on it.
