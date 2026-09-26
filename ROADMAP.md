# Tick Survival Lab — Release Roadmap

Updated: **2026-09-26**  
Status: **finite release order; current phase = 3**

This file owns **order and definitions of done**, not implementation history. Detailed chronology remains in Git/changelogs. Discussion of a future idea does not reorder this roadmap; roadmap priority changes only by explicit user direction.

## Release target

**Scavenge. Fight. Craft. Survive.**

Persistent sprite-based zombie survival with day/night, weather, useful buildings, vehicles, power/water and a complete repeated-day loop. Existing houses are fortified; no colony/freeform-building or living-society simulation is required.

## Phase status

### Phase 0 — Establish release contract — DONE

Scope reset around the finite survival game and retired broader society/freeform-construction ambitions.

### Phase 1 — Retire live survivor/society dependencies — DONE

Production no longer requires living survivor cohorts/social runtime. Shared player/zombie systems remain.

### Phase 2 — Shared-tick combat foundation — DONE (engineering)

Closed release foundation:

- commitment/interruption windows;
- simultaneous due-tick melee consequences;
- deterministic contested movement/shove;
- causal mob-force propagation;
- canonical fear through condition/CALM;
- bounded eight-infected perception/callback path;
- coherent overlapping consequence presentation;
- production crowded-fight technical acceptance.

Do not reopen this phase without a concrete play-visible defect. Real mobile/Safari acceptance remains part of final release acceptance rather than blocking Phase 3 engineering.

### Phase 3 — Durable save, leave and continue — ACTIVE

Use existing authoritative stores/snapshots to implement a versioned durable session format. Do not create duplicate gameplay truth.

Required continuity includes release-relevant player position/state, inventory/equipment, world mutations/loot, actors/zombies/corpses, conditions/skills, vehicles, structures/fortifications, utilities, day/weather and necessary WHEN/action state.

Provide truthful New Game/Continue behavior, explicit durable saving and safe automatic checkpoints. Do not rely only on browser unload. Restore pending committed actions without cancellation, duplicated consumption or duplicated rewards. Detect incompatible/invalid saves and preserve the last valid save. Surface browser-storage failure honestly.

**Done when:** mutate meaningful state -> save -> leave/close -> reopen -> Continue restores the same game; repeated save/load and region transitions do not duplicate/reset state; hard pause/backgrounding cannot exploit pending commitments.

### Phase 4 — Finish expedition + fortified-house loop — QUEUED

Wire/finish ordinary scavenging, carrying, item use, crafting/cooking, first aid, sleep/rest, repairs, deconstruction, doors/windows and existing-building fortification through natural contextual controls.

Crafting is treated coherently here: recipes, tools/materials, item actions and practical survival objects belong to the system rather than being added as unrelated one-offs. Portable camping/rest equipment may be considered here if it serves the loop; it is not an active Phase 3 feature.

Power/water must have readable service/failure/repair paths. Generator/well work is site-specific survival interaction, not a general construction engine.

**Done when:** the player can supply and fortify an existing shelter, recover/craft/repair through ordinary controls, use practical independent utilities and recover from a real infrastructure failure.

### Phase 5 — Contextual vehicles/parking — QUEUED

Deterministically enrich appropriate existing sites with driveways, carports, garages/lots and plausible vehicle placement without regenerating buildings or changing established identity/player modifications.

**Done when:** representative residential/commercial/farm sites have believable usable parking; moving/stripping vehicles persists; revisit/reload never duplicates or respawns them.

### Phase 6 — Persistent environmental stories — QUEUED

Bounded scenes made from real objects/mechanics: crashes, failed/fortified refuges, dead/turned occupants, salvage/repair opportunities. Scene choice occurs once and persists.

**Done when:** scenes make spatial/mechanical sense, offer real choices and remain changed after interaction/save/load without resurrecting living quest/NPC society systems.

### Phase 7 — Balance repeated days — QUEUED

Integrated tuning after required content exists:

- building-specific loot quantity/rarity;
- hunger/thirst/fatigue/injury/fear rates and recovery;
- weapon duration/reach/cost/damage and crowd danger;
- crafting/shelter inputs, yields, durability/upkeep;
- vehicle/utility availability and maintenance;
- day/night/weather/travel pacing.

Do not invent respawn/economy systems merely to hide bad distribution.

**Done when:** a first-day and multi-day campaign exercise the complete loop without debug grants, unavoidable deterioration loops or trivial surplus; tuning follows observed play evidence.

### Phase 8 — Release acceptance — QUEUED

Bounded end-to-end candidate play:

1. new game -> scavenge -> eat/drink -> craft/treat -> fortify -> sleep -> next-day expedition;
2. small/crowd combat demonstrating commitment, interruption, simultaneous outcomes, force, fear and escape/death;
3. vehicle use/move/repair across save/continue;
4. generator/well use, real damage and repair;
5. day/night/weather during ordinary and long actions;
6. persistent environmental stories;
7. streaming boundaries with persistent changes and acceptable responsiveness;
8. desktop + real mobile/Safari controls, input lock, hard pause/backgrounding and durable Continue.

**Finished means:** the survival loop works, stays saved, remains responsive and is enjoyable across repeated days. No optional new system is required to explain why release has not happened.

## Execution rule

One operation = one coherent vertical player/system outcome. The user chooses the slice; the AI chooses internal implementation steps. Use `CURRENT.md` for the exact active operation and `ARCHITECTURE.md` for settled ownership. Do not convert internal engineering steps into repeated approval gates.

## NEXT

**Phase 3 — durable save / leave / reopen / Continue.**
