# Tick Survival Lab — Turn-Based Rewrite Roadmap

Updated: **2026-09-27**  
Status: **architecture simplification in progress; Slices 1-2 complete**

## Release target

**Scavenge. Fight. Craft. Survive.**

A responsive turn-based open-world zombie survival game on the existing persistent procedural island. The player explores, scavenges, fights or escapes, crafts/cooks/heals, rests, repairs/deconstructs, fortifies existing houses, establishes supplies/utilities and ventures farther. Existing houses are bases; no colony/freeform-building or living-society simulation is required.

## Execution model

Canonical play is deliberately conventional:

`player action -> resolve player action -> relevant local actors each get at most one action -> advance ordinary time/environment -> return control`

The previous generalized tick/WHERE/WHAT/WHEN execution architecture is legacy and will be removed route by route. Distinctive gameplay such as crowd pressure, fear, darkness, fortification and survival pressure remains as ordinary game rules rather than reasons to preserve the old architecture.

## Migration slices

### Slice 1 — Simple turn spine — DONE

Canonical production movement bypasses TickKernel/WHEN movement execution. One movement input performs one ordinary placement change; only infected within the active local radius receive at most one simple movement; control returns immediately.

### Slice 2 — Ordinary world state and spatial queries — DONE

Canonical simple-turn movement now reads terrain/occupancy directly from `WorldState`, applies existing collision facts locally, and writes movement directly through `WorldState.move_entity()`. `SimpleTurnController` no longer depends on `SpatialQueryService`, `WorldMutationService`, `MovementActionService`, TickKernel or generalized movement consequence execution. Legacy query/mutation services remain only for bootstrap and unmigrated gameplay routes.

### Slice 3 — Simple turn-based combat — NEXT

Reconnect existing weapons/damage/injury/death to the turn loop. Player attack consumes one action; relevant zombies attack on their actions. Preserve crowd/fear/mob/darkness pressure as ordinary calculations. Remove simultaneous melee/intention/commitment machinery from the migrated route.

### Slice 4 — Scavenging and inventory

Reconnect contextual search/take/carry/drop/use/equip through direct authoritative state changes and turn costs.

### Slice 5 — Survival

Reconnect hunger, thirst, fatigue, health, wounds, fear/mood and recovery to elapsed turns/game time without universal simulation scheduling.

### Slice 6 — Contextual interaction

Preserve actions-from-things: food EAT, drink DRINK, beds SLEEP, furniture REST, windows/doors opening actions, furniture DECONSTRUCT, stove COOK, vehicles contextual actions. Replace generalized action routing where migrated.

### Slice 7 — Craft/cook/heal/repair/deconstruct

Reconnect existing content using ordinary turn costs. Long actions may consume multiple turns; interruption exists only where it materially improves gameplay.

### Slice 8 — House fortification and bases

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

Delete the obsolete TickKernel/WHEN scheduler, generalized consequence/intention/commitment machinery, obsolete movement/combat adapters, unused WHERE/WHAT framework pieces, compatibility bridges and architecture-only tests after all player routes have migrated.

### Slice 15 — Balance/performance/release acceptance

Play and tune the real repeated loop on desktop and iPhone/Safari. Acceptance is a responsive enjoyable survival game, not preservation of an architecture.

## Migration rules

- Migrate vertical player-facing routes, not abstract infrastructure first.
- After each route works, delete legacy code used only by that route.
- Reuse existing procedural world/content/presentation/persistence data where practical.
- Do not build WHERE 2.0, WHAT 2.0, WHEN 2.0, a generalized turn framework, ECS, event bus or speculative replacement architecture.
- Work per player action must be bounded by the active local gameplay situation, not the whole persistent island.
- If deleting an abstraction leaves player experience unchanged, delete it.

## NEXT

**Slice 3 — reconnect combat as ordinary turn-based gameplay on the now-simple movement/world-state spine, then remove combat-side tick/simultaneous-resolution dependencies that become obsolete.**