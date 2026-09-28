# Tick Survival Lab — Current State

Status: **canonical active working state**

## Working model

PROJECT = Tick Survival Lab  
IDENTITY = turn-based open-world zombie survival  
CORE_LOOP = explore -> scavenge -> fight/escape -> craft/heal -> fortify/supply shelter -> survive  
ACTIVE_REWRITE_SLICE = 3 complete / simple turn-based combat  
NEXT_REWRITE_SLICE = 4 / scavenging and inventory  
ROADMAP_CHANGE = true / 2026-09-27

## Authoritative direction

Keep the game; retire the experimental execution architecture.

Canonical play is:

player action -> direct consequence -> relevant local actors each act at most once -> ordinary time/environment advance -> return player control

Shared simulation ticks, generalized simultaneous resolution, universal commitment/interruption and heavyweight WHERE/WHAT/WHEN execution are legacy. They remain temporarily only where still-unmigrated gameplay/source dependencies require them.

## Slice 1 checkpoint — simple production turn spine

Canonical gameplay.tscn boots TurnBasedGameMain. Unmounted movement routes through SimpleTurnController; one input is one ordinary turn action and only infected within the 24-cell active radius receive individual simple movement.

Procedural infected derive from the real island household/population plan. The temporary player-centered synthetic zombie ring is gone.

## Slice 2 checkpoint — plain movement state/query path

Canonical simple-turn movement reads terrain/occupancy directly from WorldState and changes placement through narrow authoritative WorldState writes. It does not execute SpatialQueryService, WorldMutationService, MovementActionService, TickKernel or simultaneous movement resolution underneath the migrated route.

Player movement resolves first; relevant infected resolve sequentially against resulting current occupancy; distant infected receive no individual turn; streaming focus, perception and presentation follow final player placement.

## Slice 3 checkpoint — simple turn-based combat

Canonical combat now routes through SimpleTurnController on the same ordinary turn spine.

Current combat behavior:

- player.combat_forward is one accepted player action and consumes exactly one ordinary turn;
- if a firearm is equipped, the existing FirearmProfileCatalog / FirearmState exact firearm, magazine and live-round identities are used;
- a firearm discharge consumes the exact chambered round, cycles the next exact round when present and writes the existing firearm damage plus canonical gunshot injury;
- otherwise forward melee uses the existing physical impact profiles and real equipped hand-item mass/profile facts, falling back to the existing unarmed profile;
- damage and injury write directly to canonical ActorHealthState;
- procedurally projected infected are enrolled into canonical Health, hand-equipment and containment state;
- after the player consequence, each living infected inside the 24-cell active radius receives at most one sequential action against current state;
- an adjacent infected attacks; otherwise it may perform the established one-cell greedy movement;
- distant infected receive no individual action;
- lethal Health state transitions through CorpseState / ActorDeathTransitionService to ordinary persistent corpse world state, preserving exact carried/equipped item identity;
- ActorDeathTransitionService no longer depends on TickKernel or WorldMutationService;
- canonical combat does not advance TickKernel and does not execute CombatActionService, FirearmActionService, timed combat actions, simultaneous combat intentions/consequence batches or universal commitment/interruption underneath the migrated route;
- control returns immediately after the bounded local actor phase.

Existing darkness/perception presentation remains authoritative for what the player can perceive. Old fear timing/commitment semantics were not recreated because the simple turn route has no action-duration mechanic and survival/condition migration is a later roadmap slice. Do not invent a combat-only fear shadow state. Crowd danger currently emerges through bounded local sequential attacks and occupancy/congestion; do not restore the retired simultaneous force architecture merely to reproduce its implementation.

## World-state direct-write boundary

WorldState now exposes narrow ordinary create/remove/place/unplace writes in addition to move_entity() for migrated turn routes. These extend the existing authoritative state owner; they are not a replacement mutation framework.

Generation/bootstrap and still-unmigrated routes may continue using WorldMutationService until their roadmap migration.

## Transitional legacy boundary

Legacy CombatGameMain, CombatActionService, CombatPlayerController and FirearmActionService remain source migration debt because older noncanonical app composition still references them. They are not canonical production combat execution and must not be extended for new combat behavior.

Other legacy scheduling/query/mutation systems remain for unmigrated scavenging/contextual interactions, long actions, vehicles, utilities and durable-session migration. Delete them only when their final dependent route has migrated.

## Preserved game

Preserve throughout the rewrite:

- real procedural persistent island and streaming;
- generated roads/buildings/world content;
- scavenging, loot and inventory;
- zombies and canonical combat consequences;
- crowd/fear/darkness/perception pressure as ordinary gameplay rules when their owning systems are active;
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

- game/scripts/ci/Slice3SimpleCombatSmoke.gd
- .github/workflows/slice3-simple-combat.yml

The focused production verifier boots seed 20001 and proves one-turn lethal melee, authoritative corpse transition, one adjacent infected attack, distant infected inactivity, control return, exact-round firearm discharge/damage/injury and zero TickKernel advancement across both combat actions. Static guards reject legacy execution dependencies in the migrated combat/death route.

Per SOP, the next code-changing prompt must retire this verifier/workflow before production edits and create fresh Slice 4 verification.

## NEXT

**Rewrite Slice 4 — scavenging and inventory.**

Reconnect contextual search/take/carry/drop/use/equip through the existing simple turn/world-state spine and existing authoritative loot, exact item identity, containment and equipment state. Each accepted player inventory/scavenging action should have an ordinary direct consequence and ordinary turn cost where appropriate, followed by the same bounded local infected phase and return of control.

Do not migrate survival progression, contextual doors/windows, crafting, fortification, vehicles, utilities, world-time/weather or durable persistence yet unless a concrete scavenging/inventory prerequisite requires a narrowly targeted compatibility repair.
