# Tick Survival Lab — Turn-Based Rewrite Roadmap

Updated: **2026-09-27**  
Status: **architecture simplification in progress; Slices 1-7 complete**

## Release target

**Scavenge. Fight. Craft. Survive.**

A responsive turn-based open-world zombie survival game on the existing persistent procedural island. The player explores, scavenges, fights or escapes, crafts/cooks/heals, rests, repairs/deconstructs, fortifies existing houses, establishes supplies/utilities and ventures farther. Existing houses are bases; no colony/freeform-building or living-society simulation is required.

## Execution model

Canonical play is deliberately conventional:

player action -> resolve player action -> relevant local actors each get at most one action -> advance ordinary time/environment -> return control

The previous generalized tick/WHERE/WHAT/WHEN execution architecture is legacy and will be removed route by route.

## Migration slices

### Slice 1 — Simple turn spine — DONE
Canonical production movement bypasses TickKernel/WHEN movement execution.

### Slice 2 — Ordinary world state and spatial queries — DONE
Canonical movement reads/writes ordinary WorldState directly and no longer depends on generalized movement execution.

### Slice 3 — Simple turn-based combat — DONE
Canonical melee/firearm combat resolves against existing Health/injury/equipment/firearm/corpse state with bounded sequential infected actions.

### Slice 4 — Scavenging and inventory — DONE
Real generated loot and exact item containment/equipment identity use ordinary simple-turn search/take/store/equip/stow/drop/pickup actions.

### Slice 5 — Survival — DONE
Existing condition/Health/moodlet state advances once from explicit elapsed canonical action time rather than TickKernel. MENU/SAVE/SAVE & MENU was repaired in the same operation.

### Slice 6 — Contextual interaction — DONE
Existing action-from-thing presentation now fronts direct simple-turn EAT/DRINK, REST/SLEEP, door/window OPEN/CLOSE, loot/pickup and later-system entry points without scheduled contextual execution.

### Slice 7 — Craft/cook/heal/repair/deconstruct — DONE

Existing recipe, tool, skill, workstation, Health/injury, object-state and salvage content now executes through direct ordinary actions. Crafting consumes exact selected ingredient entities and creates exact recipe outputs in authoritative containment. First aid consumes the selected medical resource and updates the existing injury record. Repair uses existing repair profiles, tools/materials, Mechanical skill and broken-state ownership. Deconstruction uses existing object profiles, Mechanical skill and salvage semantics, removes the actual world object and creates authoritative salvage.

All accepted completed actions feed the same bounded SimpleTurnController actor phase and explicit survival elapsed-time seam; invalid/rejected actions remain zero-time. The canonical Slice 7 route does not run TickKernel, TimedAction, ScheduledEvent or generalized WHEN execution.

Cooking uses the same real recipe route and existing PoweredCraftingWorkstationAdapter availability. Seed 20001's focused production fixture correctly reports the representative stove unavailable because its existing power rule is not satisfied; Slice 7 does not fake powered cooking or migrate utilities early.

The production composition currently uses a narrow `Slice7GameMain` subclass to hold the explicit migrated domain commits while the legacy superclass chain still supplies persistence and unmigrated owners. This is migration composition debt, not a new action framework, and should fold away during later consolidation/legacy demolition.

### Slice 8 — House fortification and bases — NEXT
Restore the complete existing-building shelter loop: clear a house, board openings, repair, stash supplies, sleep and establish utilities. No freeform construction architecture.

### Slice 9 — Power and water
Reconnect generators, wells, grid state, failures and repairs as ordinary world systems driven by events/elapsed time rather than universal tick participation.

### Slice 10 — Vehicles
Reconnect enter/exit, movement, fuel, damage, cargo and repair using simple turn actions.

### Slice 11 — Day/night, weather and world time
Define ordinary turn-to-world-time advancement and derive day/night/weather from world time without a general action scheduler.

### Slice 12 — Open-world simulation boundary
Only the player's relevant neighborhood receives individual actor turns. Unloaded/far world state remains persistent data; coarse offscreen progression is calculated only when needed.

### Slice 13 — Persistence migration
Adapt durable Continue to simplified state while preserving seed, player/inventory, meaningful zombies/corpses, looted/deconstructed objects, fortifications, vehicles, utilities, time/weather and world deltas. Do not invent a second save architecture.

### Slice 14 — Legacy demolition
Delete obsolete TickKernel/WHEN scheduling, generalized consequence/intention/commitment machinery, obsolete adapters, unused WHERE/WHAT framework pieces and compatibility bridges after all player routes migrate.

### Slice 15 — Balance/performance/release acceptance
Play and tune the real repeated loop on desktop and iPhone/Safari.

## Migration rules

- Migrate vertical player-facing routes, not abstract infrastructure first.
- After each route works, delete legacy code used only by that route.
- Reuse existing procedural world/content/presentation/persistence data where practical.
- Do not build WHERE 2.0, WHAT 2.0, WHEN 2.0, a generalized turn framework, ECS, event bus or speculative replacement architecture.
- Work per player action must be bounded by the active local gameplay situation, not the whole persistent island.
- If deleting an abstraction leaves player experience unchanged, delete it.

## NEXT

**Slice 8 — reconnect existing-house fortification and base use: boarding openings, shelter repair, stashing supplies and established shelter state through ordinary contextual/simple-turn actions, without freeform construction or settlement simulation.**
