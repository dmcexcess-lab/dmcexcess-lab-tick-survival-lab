# Tick Survival Lab — Turn-Based Rewrite Roadmap

Updated: **2026-09-28**  
Status: **architecture simplification in progress; Slices 1-8 complete**

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
Existing recipe, tool, skill, workstation, Health/injury, object-state and salvage content executes through direct ordinary actions. Cooking retains real utility availability rather than faking power.

### Slice 8 — Existing-house fortification — DONE
Real generated doors/windows expose existing BOARD/REMOVE BOARD contextually. BOARD validates existing opening state, Mechanical skill, hammer, exact wood-plank and nails-box entities, consumes exact materials and increments the existing persistent 0-3 board count. REMOVE BOARD uses the same authoritative state, accepts the existing hammer/crowbar rule and recovers one real plank entity. Existing opening pressure consumes boards before opening damage/breakage. Fortification uses the canonical bounded simple-turn/survival seam and durable Continue restores installed boards and exact consumed-material consequences. No freeform construction/base ownership/build-job architecture was introduced; existing stash/sleep/repair behavior remains supplied by already-closed inventory/contextual/repair routes.

### Slice 9 — Power and water — NEXT
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

**Slice 9 — reconnect power and water: existing generators, wells, grid/network state, failures and repairs through ordinary authoritative world state and explicit elapsed time, without restoring universal tick scheduling.**
