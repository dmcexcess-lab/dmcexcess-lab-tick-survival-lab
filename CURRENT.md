# Tick Survival Lab — Current State

Status: **canonical active working state**

## Working model

```text
PROJECT = Tick Survival Lab
IDENTITY = turn-based open-world zombie survival
CORE_LOOP = explore -> scavenge -> fight/escape -> craft/heal -> fortify/supply shelter -> survive
ACTIVE_REWRITE_SLICE = 1 complete / simple turn spine
NEXT_REWRITE_SLICE = 2 / ordinary world state and spatial queries
ROADMAP_CHANGE = true / 2026-09-27
```

## New authoritative direction

Keep the game; retire the experimental execution architecture.

Canonical play is now:

`player action -> direct consequence -> relevant local actors each act at most once -> ordinary time/environment advance -> return player control`

Shared simulation ticks, generalized simultaneous resolution, universal commitment/interruption and heavyweight WHERE/WHAT/WHEN execution are legacy. They remain temporarily only where unmigrated gameplay still depends on them. Do not optimize or extend them as architecture.

## Slice 1 checkpoint — simple production turn spine

Canonical `gameplay.tscn` now boots `TurnBasedGameMain`.

For an unmounted survivor, movement intents route to `SimpleTurnController` rather than `PlayerActionController` / `MovementActionService` / TickKernel execution.

Current migrated movement behavior:

- one legal movement input changes player placement exactly once;
- forward/back/run-forward are one-tile attempts; turns are one ordinary turn action;
- illegal movement is rejected without creating a simulation queue;
- after a successful player action, only infected within the 24-cell active radius are considered for one simple adjacent pursuit step;
- distant infected receive no individual turn;
- streaming focus, perception and presentation refresh from the resulting authoritative placement;
- control returns immediately for the next player action;
- the legacy TickKernel world tick does not advance anywhere under this movement route.

The focused production verifier proves two consecutive turns, exact one-tile movement, bounded infected work, distant-infected inactivity, zero TickKernel advancement, and durable snapshot -> Continue restoring the moved player into simple-turn control.

## Transitional legacy boundary

Legacy systems are still instantiated because combat, vehicles, contextual interactions, long actions and the existing durable-session format have not yet migrated. This is temporary migration debt.

Do not create adapters that reproduce old semantics around `SimpleTurnController`.

Do not delete legacy owners still required by unmigrated routes until their owning slice replaces them.

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

- `game/scripts/ci/SimpleTurnSpineSmoke.gd`
- `.github/workflows/simple-turn-spine.yml`

Per SOP, the next code-changing prompt must retire these before production edits and create fresh Slice 2 verification.

## NEXT

**Rewrite Slice 2 — simplify the world-state/spatial-query path used by canonical movement.**

Start from the working simple-turn movement route. Replace only the minimum movement-facing WHERE/WHAT responsibilities with conventional plain world state/spatial queries, then delete movement-specific legacy ownership that becomes unused.

Do not migrate combat yet. Do not create a replacement framework. Keep the real procedural world, rendering/perception, bounded local actor work and durable Continue working while the code underneath movement becomes smaller and more conventional.