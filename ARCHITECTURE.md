# Tick Survival Lab — Settled Architecture Map

Status: **active turn-based migration map**

## Canonical direction

Tick Lab is a conventional turn-based open-world zombie survival game. The persistent procedural island and gameplay content are retained; the generalized tick/WHERE/WHAT/WHEN execution architecture is legacy and is being removed route by route.

Canonical action flow:

`player action -> direct authoritative consequence -> relevant local actors each act at most once -> ordinary time/environment advance -> player control`

Do not create a replacement simulation framework.

## Current production spine

- `gameplay.tscn -> TurnBasedGameMain` is canonical.
- `ProductionWorldBootstrap` owns real procedural generation/materialization/streaming; production never depends on demo fixtures.
- `SimpleTurnController` owns the migrated unmounted movement route only.
- One movement input changes the player placement at most once.
- Only infected within the bounded active radius receive individual simple movement after a successful player movement action.
- Canonical movement does not execute `TickKernel`, `MovementActionService`, WHEN queues or simultaneous resolution.
- Streaming focus, perception and rendering follow authoritative placement after the simple turn.

## Transitional boundary

The old runtime remains temporarily instantiated because combat, contextual interactions, long actions and durable persistence still depend on portions of it. This is migration debt, not protected architecture.

Rules while migrating:

- no new dependency on TickKernel/WHEN for migrated routes;
- no WHERE 2.0 / WHAT 2.0 / WHEN 2.0;
- plain world state and direct spatial queries are preferred;
- delete legacy owners/adapters once their final player-facing route migrates;
- do not preserve architecture-only behavior at the expense of responsiveness;
- only locally relevant actors receive individual turns;
- far/unloaded world remains persistent data, not an always-running simulation.

## Game systems to preserve

- open procedural persistent island, generated roads/buildings and streaming;
- scavenging, inventory/equipment and loot;
- zombies, weapons, damage, injury and death;
- crowd pressure, fear and darkness/perception pressure as ordinary gameplay rules;
- contextual interactions originating from the thing acted upon;
- crafting/cooking/healing, rest/sleep, repair/deconstruction;
- existing-building fortification and shelter/base use;
- vehicles;
- power/water, generators/wells and failures/repairs;
- day/night and weather;
- durable New Game / Continue.

## Stable non-execution boundaries

- Generation creates the procedural world; persistent state owns subsequent player-caused changes.
- Rendering/UI own presentation and input only, never gameplay consequences.
- Production identity is `actor.player`; demo actor/world IDs are not canonical.
- A base is an existing building the player fortifies and supplies; no settlement management or freeform construction engine.
- Persistence should serialize ordinary authoritative state conventionally; do not create duplicate gameplay truth.

## Explicitly retired direction

The following are no longer project identity and should disappear as migration permits:

- shared simulation ticks as the universal execution model;
- multiple movement phases per player action;
- generalized simultaneous intention/consequence resolution;
- universal commitment/interruption machinery;
- generalized WHEN scheduling for ordinary actions;
- WHERE/WHAT as heavyweight runtime frameworks rather than ordinary state/query responsibilities;
- living survivor/raider/follower/social simulation;
- colony/settlement management;
- freeform base construction;
- demo/fixture-owned production startup.

See `ROADMAP.md` for migration order and `CURRENT.md` for the exact next operation.