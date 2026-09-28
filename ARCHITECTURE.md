# Tick Survival Lab — Settled Architecture Map

Status: **active turn-based migration map; Slices 1-4 complete**

## Canonical direction

Tick Lab is a conventional turn-based open-world zombie survival game. The persistent procedural island and gameplay content are retained; the generalized tick/WHERE/WHAT/WHEN execution architecture is legacy and is being removed route by route.

Canonical action flow:

player action -> direct authoritative consequence -> relevant local actors each act at most once -> ordinary time/environment advance -> player control

Do not create a replacement simulation framework.

## Current production spine

- gameplay.tscn -> TurnBasedGameMain is canonical.
- ProductionWorldBootstrap owns real procedural generation/materialization/streaming; production never depends on demo fixtures.
- SimpleTurnController owns migrated unmounted movement, combat, scavenging and ordinary inventory actions.
- WorldState owns authoritative entities/placements and exposes narrow ordinary direct writes used by migrated turn routes.
- Movement legality reads candidate cells directly from WorldState terrain/occupancy plus existing collision facts; canonical movement does not call SpatialQueryService, WorldMutationService or MovementActionService.
- A player movement or combat input resolves at most once, consumes one ordinary turn when accepted, then relevant infected resolve sequentially against the resulting current state.
- Only infected within the bounded 24-cell active radius receive individual actions. An adjacent living infected attacks; otherwise a relevant infected may make one ordinary movement. Distant infected receive no individual turn.
- Canonical forward melee reuses existing physical item impact profiles and writes damage/injury directly to canonical ActorHealthState.
- Canonical firearm use reuses existing FirearmProfileCatalog / FirearmState: exact firearm, magazine and live-round identities remain authoritative; a discharge consumes the exact chambered round and writes canonical gunshot damage/injury.
- CorpseState plus ActorDeathTransitionService own lethal actor transition. The migrated death path no longer requires TickKernel or WorldMutationService; it transfers exact equipment/inventory and creates ordinary persistent corpse world state.
- Procedurally projected infected are enrolled into the existing Health, hand-equipment and containment owners before taking simple combat turns.
- Canonical movement/combat does not execute TickKernel, WHEN queues, timed combat actions, simultaneous intention/consequence batches or universal commitment/interruption machinery underneath the migrated route.
- Streaming focus, player perception and presentation follow final authoritative state after each simple turn.
- Real generated loot remains owned by LootState + InventoryContainmentState; inspection is read-only and never rerolls contents.
- Search/take/store/equip/stow/drop/loose-item pickup validate against current WorldState, containment, equipment, carry capacity and interaction reach, mutate those existing owners directly, then commit one ordinary turn.
- Exact item entity identity is preserved across loot container -> player containment -> equipment -> world drop -> pickup -> container transitions.
- The existing LootContainerPanel and inventory/equipment shell remain presentation/input surfaces. Canonical mutations route to SimpleTurnController; they do not run ItemTransferActionService, LootSearchActionService or TickKernel.


## Transitional boundary

The old runtime remains temporarily instantiated or referenced because bootstrap plus later roadmap routes such as survival/contextual actions, long actions, vehicles, utilities and durable-session migration still depend on portions of it. This is migration debt, not protected architecture.

Legacy CombatGameMain, CombatActionService, CombatPlayerController, FirearmActionService, LootSearchActionService, LootPlayerInteractionController and timed ItemTransferActionService are not canonical movement/combat/scavenging/inventory execution. They remain only because older noncanonical app composition/source dependencies have not yet been demolished. Do not extend them for migrated gameplay. Delete them when their remaining legacy dependents are migrated safely.

SpatialQueryService and WorldMutationService likewise remain for unmigrated routes/bootstrap but are not dependencies of canonical simple-turn movement/combat/scavenging/inventory.

Rules while migrating:

- no new dependency on TickKernel/WHEN for migrated routes;
- no WHERE 2.0 / WHAT 2.0 / WHEN 2.0;
- plain world state and direct local spatial questions are preferred;
- delete legacy owners/adapters once their final dependent route migrates;
- do not preserve architecture-only behavior at the expense of responsiveness;
- only locally relevant actors receive individual turns;
- far/unloaded world remains persistent data, not an always-running simulation.

## Game systems to preserve

- open procedural persistent island, generated roads/buildings and streaming;
- scavenging, inventory/equipment and loot;
- zombies, weapons, damage, injury, death and corpses;
- crowd congestion/pressure, fear and darkness/perception pressure as ordinary gameplay rules where their owning systems are active;
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
- Production identity is actor.player; demo actor/world IDs are not canonical.
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

See ROADMAP.md for migration order and CURRENT.md for the exact next operation.
