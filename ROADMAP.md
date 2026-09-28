# Tick Survival Lab — Turn-Based Rewrite Roadmap

Updated: **2026-09-27**  
Status: **architecture simplification in progress; Slices 1-5 complete**

## Release target

**Scavenge. Fight. Craft. Survive.**

A responsive turn-based open-world zombie survival game on the existing persistent procedural island. The player explores, scavenges, fights or escapes, crafts/cooks/heals, rests, repairs/deconstructs, fortifies existing houses, establishes supplies/utilities and ventures farther. Existing houses are bases; no colony/freeform-building or living-society simulation is required.

## Execution model

Canonical play is deliberately conventional:

player action -> resolve player action -> relevant local actors each get at most one action -> advance ordinary time/environment -> return control

The previous generalized tick/WHERE/WHAT/WHEN execution architecture is legacy and will be removed route by route. Distinctive gameplay such as crowd pressure, fear, darkness, fortification and survival pressure remains as ordinary game rules rather than reasons to preserve the old architecture.

## Migration slices

### Slice 1 — Simple turn spine — DONE

Canonical production movement bypasses TickKernel/WHEN movement execution. One movement input performs one ordinary placement change; only infected within the active local radius receive at most one simple movement; control returns immediately.

### Slice 2 — Ordinary world state and spatial queries — DONE

Canonical simple-turn movement now reads terrain/occupancy directly from WorldState, applies existing collision facts locally, and writes movement directly through WorldState.move_entity(). SimpleTurnController no longer depends on SpatialQueryService, WorldMutationService, MovementActionService, TickKernel or generalized movement consequence execution. Legacy query/mutation services remain only for bootstrap and unmigrated gameplay routes.

### Slice 3 — Simple turn-based combat — DONE

Canonical production combat now runs inside the simple turn spine. Forward melee reuses existing physical item impact profiles; forward firearm use preserves exact firearm/magazine/live-round state; Health/injury and corpse consequences remain canonical authoritative state. Player combat consumes one action, nearby infected may attack on their one sequential action, distant infected receive no individual turn, and the migrated route does not advance TickKernel or use simultaneous combat intention/consequence resolution.

Legacy tick-based combat classes remain noncanonical source migration debt only where older app composition still references them; they are not extended by the production route.

### Slice 4 — Scavenging and inventory — DONE

Canonical production scavenging/inventory now runs through the simple turn spine using real generated loot and existing authoritative item/containment/equipment owners. Inspection is read-only. Search, take, store, equip, stow, drop and narrow loose-item pickup preserve exact item identity and use ordinary one-turn costs; rejected actions cost no turn. The existing loot panel and inventory/equipment shell route to this migrated path. TickKernel, timed transfer scheduling and LootSearchActionService do not execute underneath canonical Slice 4 actions.

### Slice 5 — Survival — DONE

Existing authoritative condition/Health/moodlet state now advances from the canonical ordinary-turn seam rather than TickKernel. Each successful migrated turn advances one second of existing survival-time math exactly once; rejected actions, pure UI and inspection advance none. Satiety/hydration/rest/engagement/comfort/calm and fatigue keep their existing rates/modifiers; running applies existing fatigue pressure; bounded visible-infected/injury danger updates existing Calm/fear state. No render-frame survival loop or generalized scheduler was introduced.

The production save/menu regression was repaired in the same operation: the duplicate high-layer SessionControls strip that covered MENU was removed, SAVE and SAVE & MENU now live inside the canonical phone MENU, and TurnBasedGameMain reconnects the existing DurableSessionStore/Continue lifecycle. SAVE & MENU completes the real durable save before returning to res://main.tscn.

### Slice 6 — Contextual interaction — NEXT

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

**Slice 6 — reconnect contextual world/item interactions to the simple-turn model, preserving actions-from-things without restoring generalized scheduling.**
