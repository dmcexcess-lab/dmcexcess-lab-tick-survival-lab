# Tick Survival Lab — Turn-Based Rewrite Roadmap

Updated: **2026-09-29**  
Status: **architecture simplification complete; Slices 1-14 complete**

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

### Slice 9 — Power and water — DONE
Existing generator/grid/water state remains authoritative while canonical generator and failed-distribution repair actions execute directly through the simple-turn/survival seam without generalized timed scheduling.

### Slice 10 — Road hierarchy correction + vehicles — DONE
Virgin island generation now establishes a sparse backbone of four terrain-routed cross-island four-lane arterials. Developed settlements attach by two-lane paved roads, rural settlement access is gravel, and local rural/farm/home lanes are dirt. Paved roads materialize as asphalt with markings while gravel/dirt remain unpainted.

Existing vehicle entities/state/profiles/footprints/cargo/fuel/condition/keys/presentation/persistence remain authoritative. Enter/exit/start/drive/turn/reverse/brake/hotwire/repair/modify/refuel/cargo now resolve as direct simple-turn actions with explicit elapsed survival time and bounded local infected responses; canonical player vehicle execution no longer advances TickKernel timed actions.

### Slice 11 — Day/night, weather and world time — DONE
Canonical actions advance one authoritative world-time clock from their existing explicit elapsed ticks. Dawn/day/dusk/night derive continuously from that clock; existing weather profiles/state advance coarsely from the same clock without TickKernel scheduling. Existing lighting, perception, optics, acoustics and GPU weather presentation remain downstream. Time/weather persist through durable Continue, including migration for older saves without a dedicated world-time owner.

### Slice 12 — Open-world simulation boundary — DONE
The existing streaming coordinator now defines the first infected-eligibility boundary and SimpleTurnController's established local radius remains the second. Only infected currently placed in active streamed regions are supplied to canonical local-turn execution. Far/unloaded infected remain persistent authoritative entities/state but receive no ordinary pathfinding, attacks or individual turns. Procedural infected resident records are projected once and cached; hydration occurs only on streaming-boundary changes rather than scanning the island every action. Long world-time jumps still produce only one bounded local actor-response boundary.

### Slice 13 — Persistence migration — DONE
DurableSessionStore schema 2 now saves canonical gameplay facts without requiring TickKernel execution queues, perception caches or combat runtime state. Continue restores authoritative world/domain owners, exact world time/weather and refrigeration exposure state, then reconstructs streaming/local infected/perception/presentation runtime from restored facts. Current schema-1 saves remain accepted: retired runtime payloads are ignored, world time derives from restored condition anchors and refrigeration establishes a safe non-regressing baseline before the next schema-2 save. Repeated production save -> Continue -> save -> Continue preserves representative player, item, loot, fortification, infected/corpse, vehicle, utility and time/weather consequences without duplication/reset.

### Slice 14 — Legacy demolition — DONE
Production no longer constructs the superseded player/door/loot/crafting/vehicle/world-interaction/combat controller graph or the scheduled crafting, item-transfer, loot, door and firearm player-execution services behind it. Those implementations were physically deleted along with obsolete consequence/debug presentation and disconnected condition adapters. Slice 11-13 migration layers were consolidated into ProductionGameMain. TickKernel remains only as a documented compatibility remnant for the existing forage route, utility/sound/perception/UI clock APIs, and the infected cohort/opening-pressure seam; canonical direct gameplay and durable persistence do not advance or serialize it.

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

**Slice 15 — balance, performance and release acceptance: play and tune the real repeated loop on desktop and iPhone/Safari, fix release-blocking gameplay/performance defects, and close the rewrite as a shippable focused zombie survival game.**
