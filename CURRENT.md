# Tick Survival Lab — Current State

Status: **canonical active working state**

## Working model

```text
PROJECT = Tick Survival Lab
IDENTITY = turn-based open-world zombie survival
CORE_LOOP = explore -> scavenge -> fight/escape -> craft/heal -> fortify/supply shelter -> survive
ACTIVE_REWRITE_SLICE = 2 complete / plain movement world-state + spatial queries
NEXT_REWRITE_SLICE = 3 / simple turn-based combat
ROADMAP_CHANGE = true / 2026-09-27
```

## Authoritative direction

Keep the game; retire the experimental execution architecture.

Canonical play is:

`player action -> direct consequence -> relevant local actors each act at most once -> ordinary time/environment advance -> return player control`

Shared simulation ticks, generalized simultaneous resolution, universal commitment/interruption and heavyweight WHERE/WHAT/WHEN execution are legacy. They remain temporarily only where unmigrated gameplay still depends on them.

## Slice 1 checkpoint — simple production turn spine

Canonical `gameplay.tscn` boots `TurnBasedGameMain`. Unmounted movement routes through `SimpleTurnController`; one input is one ordinary turn action and only infected within the 24-cell active radius receive individual simple movement.

Procedural infected now derive from the real island household/population plan. The temporary player-centered synthetic zombie ring is gone.

## Slice 2 checkpoint — plain movement state/query path

Canonical simple-turn movement no longer depends on `SpatialQueryService`, `WorldMutationService`, `MovementActionService`, TickKernel or generalized footprint-query execution.

Current movement behavior:

- `WorldState` is the authoritative owner of entity placement;
- `SimpleTurnController` reads terrain and occupancy directly from `WorldState`;
- existing collision catalog/override facts are consulted locally for blocking semantics;
- `WorldState.move_entity()` performs the narrow authoritative placement change and emits the ordinary world change consumed by presentation/persistence observers;
- player movement resolves first;
- relevant infected resolve sequentially against the resulting current occupancy;
- distant infected receive no individual turn;
- streaming focus, perception and presentation follow the resulting authoritative player placement;
- no legacy simulation tick or simultaneous movement consequence phase executes underneath this route.

Focused Slice 2 verification on production seed `20001` booted the real procedural world, performed a real legal adjacent move, completed a second ordinary turn, returned control after each action and passed static guards preventing the migrated controller from reacquiring `SpatialQueryService`, `WorldMutationService`, TickKernel, `MovementActionService` or `query_entity_footprint`.

## Transitional legacy boundary

Legacy query/mutation/scheduling systems still exist because generation/bootstrap, combat, vehicles, contextual interactions, long actions and the durable-session implementation have not all migrated. This is migration debt, not protected architecture.

Do not create adapters that reproduce old semantics around `SimpleTurnController`.

Delete legacy owners only when their final production consumer has migrated.

## Preserved game

Preserve throughout the rewrite:

- real procedural persistent island and streaming;
- generated roads/buildings/world content;
- scavenging, loot and inventory;
- zombies and combat content;
- crowd/fear/darkness/perception pressure;
- contextual actions originating from world objects/items;
- survival, crafting/cooking/healing, rest, repair and deconstruction;
- existing-building fortification/base use;
- vehicles;
- power/water and independent shelter utilities;
- day/night/weather;
- durable New Game / Continue.

A base remains an existing building the player fortified and supplied. No colony/freeform-building system.

## Verification lifecycle

Current prompt-local verifier/workflow:

- `game/scripts/ci/Slice2PlainMovementSmoke.gd`
- `.github/workflows/slice2-plain-movement.yml`

Per SOP, the next code-changing prompt must retire these before production edits and create fresh Slice 3 verification.

## NEXT

**Rewrite Slice 3 — simple turn-based combat.**

Start from the working simple movement/world-state spine. Reconnect the existing combat content as ordinary turn actions: a player attack is one action; relevant zombies may attack on their action when in range; damage/injury/death remain authoritative game state. Preserve crowd/fear/mob/darkness pressure as ordinary calculations where they materially affect combat.

Remove combat-side tick/simultaneous-intention/commitment dependencies that become obsolete after the migrated production combat route works. Do not migrate scavenging, survival, contextual doors/windows, crafting, fortification, vehicles or utilities yet unless a concrete combat prerequisite requires a narrowly targeted compatibility repair.