# Tick Survival Lab — Current State

Status: **canonical active working state**

## Working model

PROJECT = Tick Survival Lab  
IDENTITY = turn-based open-world zombie survival  
CORE_LOOP = explore -> scavenge -> fight/escape -> craft/heal -> fortify/supply shelter -> survive  
ACTIVE_REWRITE_SLICE = 4 complete / scavenging and inventory  
NEXT_REWRITE_SLICE = 5 / survival  
ROADMAP_CHANGE = true / 2026-09-27

## Authoritative direction

Keep the game; retire the experimental execution architecture.

Canonical play is:

player action -> direct consequence -> relevant local actors each act at most once -> ordinary time/environment advance -> return player control

Shared simulation ticks, generalized simultaneous resolution, universal commitment/interruption and heavyweight WHERE/WHAT/WHEN execution are legacy. They remain temporarily only where still-unmigrated gameplay/source dependencies require them.

## Closed canonical simple-turn routes

### Movement

SimpleTurnController reads terrain/occupancy directly from WorldState and changes placement through narrow authoritative WorldState writes. Canonical movement does not execute SpatialQueryService, WorldMutationService, MovementActionService, TickKernel or simultaneous movement resolution.

### Combat

Player melee/firearm actions resolve directly against authoritative Health/injury/equipment/firearm/corpse state. Nearby infected receive at most one sequential local action; distant infected receive none. Canonical combat does not advance TickKernel or execute CombatActionService, FirearmActionService, timed combat actions or simultaneous consequence batches.

### Scavenging and inventory

Canonical production scavenging/inventory now routes through SimpleTurnController and the existing authoritative loot/item owners.

Current behavior:

- real generated LootState + InventoryContainmentState contents are used; no fake Slice 4 loot source exists;
- LootContainerInspectionQuery is read-only and pure inspection consumes no turn;
- search/opening a reachable initialized loot container is an ordinary one-turn action, matching the established player-facing search rule;
- TAKE moves the same exact item entity from the real source container into authoritative player containment;
- STORE moves the same exact carried item into the reachable real loot container;
- compatible carried items can be equipped through ActorHandEquipmentMutationService without duplicate active-weapon state;
- stow returns the same exact equipped item to player containment;
- drop removes the exact item from containment/equipment and creates real LOOSE_ITEM WorldState placement at the player;
- narrow loose-item pickup restores that same entity to player containment, including items just dropped;
- carry acquisition policy remains authoritative for take/pickup admission;
- failed/rejected actions mutate nothing and consume no turn;
- each successful material inventory/scavenging action consumes one ordinary turn, runs the same bounded local infected phase and returns control;
- the existing LootContainerPanel and EquipmentPlayerShell remain the production presentation/input surfaces and are wired to the simple-turn route;
- equipped items continue to feed the migrated combat route directly;
- canonical Slice 4 actions do not advance TickKernel or execute LootSearchActionService, timed ItemTransferActionService, TimedAction, ScheduledEvent or run_until_stop.

Removed-from-canonical-route legacy does not mean deleted source yet. LootSearchActionService, LootPlayerInteractionController and timed ItemTransferActionService remain noncanonical compatibility debt because older app composition/source dependencies still reference them. Do not extend them for migrated gameplay; remove them when their final legacy dependents migrate.

## Protected behavior

Preserve:

- the real procedural persistent island and streaming;
- exact item identities and existing loot generation;
- authoritative containment/equipment/carry state;
- movement and combat simple-turn semantics;
- bounded 24-cell individual infected actions;
- canonical Health/injury/death/corpse consequences;
- existing darkness/perception presentation;
- contextual actions from things;
- later survival/crafting/doors/windows/fortification/vehicles/utilities/day-night/weather/persistence systems until their roadmap slices migrate.

A base remains an existing building the player fortified and supplied. No colony/freeform-building system.

## Verification lifecycle

Current prompt-local verifier/workflow:

- game/scripts/ci/Slice4ScavengingInventorySmoke.gd
- .github/workflows/slice4-scavenging-inventory.yml

The focused production verifier boots seed 20001 and uses an actual generated bathroom-vanity loot container. It proves read-only inspection, one-turn search with one nearby infected response, distant infected inactivity, exact take/store identity, no loot respawn, rejected-action atomicity, equip/stow/drop/re-pickup identity, zero TickKernel advancement and the protected Slice 3 equipped-item melee regression.

Per SOP, the next code-changing prompt must retire this Slice 4 verifier/workflow before production edits and create fresh Slice 5 verification.

## NEXT

**Rewrite Slice 5 — survival.**

Reconnect hunger, thirst, fatigue, Health/wounds, fear/mood and recovery to ordinary elapsed turns/game time without restoring universal simulation scheduling.

Use the existing authoritative condition/Health/moodlet state and existing player-facing survival content. Ordinary turn completion should advance the relevant survival consequences coherently; no render-frame simulation, per-entity permanent timers, replacement condition framework or resurrection of TickKernel/WHEN as the canonical clock.

Do not migrate contextual doors/windows, crafting/cooking/healing interactions, fortification, vehicles, utilities, day/night/weather or durable persistence beyond narrowly required survival prerequisites.
