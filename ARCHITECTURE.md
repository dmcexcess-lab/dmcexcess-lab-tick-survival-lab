# Tick Survival Lab — Settled Architecture Map

Status: **active turn-based migration map; Slices 1-6 complete**

## Canonical direction

Tick Lab is a conventional turn-based open-world zombie survival game. The persistent procedural island and gameplay content are retained; the generalized tick/WHERE/WHAT/WHEN execution architecture is legacy and is being removed route by route.

Canonical action flow:

player action -> direct authoritative consequence -> relevant local actors each act at most once -> ordinary time/environment advance -> player control

Do not create a replacement simulation framework.

## Current production spine

- gameplay.tscn -> TurnBasedGameMain is canonical.
- ProductionWorldBootstrap owns real procedural generation/materialization/streaming; production never depends on demo fixtures.
- SimpleTurnController owns migrated unmounted movement, combat, scavenging and ordinary inventory turn completion; its single turn-completion signal is the canonical survival-time advancement seam.
- WorldState owns authoritative entities/placements and exposes narrow ordinary direct writes used by migrated turn routes.
- Movement legality reads candidate cells directly from WorldState terrain/occupancy plus existing collision facts; canonical movement does not call SpatialQueryService, WorldMutationService or MovementActionService.
- A player movement or combat input resolves at most once, consumes one ordinary turn when accepted, then relevant infected resolve sequentially against the resulting current state.
- Only infected within the bounded 24-cell active radius receive individual actions. Distant infected receive no individual turn.
- Canonical melee/firearm combat writes existing Health/injury/firearm/corpse state directly and does not execute TickKernel/WHEN/simultaneous combat machinery.
- Streaming focus, player perception and presentation follow final authoritative state after each simple turn.
- Real generated loot remains owned by LootState + InventoryContainmentState; inspection is read-only and never rerolls contents.
- Search/take/store/equip/stow/drop/loose-item pickup validate against current authoritative state, mutate existing owners directly, then commit one ordinary turn. Exact item identity is preserved.
- Existing ActorConditionState / ActorConditionService / ActorConditionModifierQuery remain authoritative survival state. The canonical route advances explicit elapsed survival time once per accepted action and never from render frames.
- Existing need rates, fatigue math, condition modifiers, Health pressure and moodlet presentation are reused. Running applies existing fatigue pressure; nearby perceived infected and actual injury feed existing Calm/fear state.
- Contextual interaction remains action-from-thing: the existing InteractionAffordanceQuery and WorldInteractionPanel discover/present actions belonging to the selected real entity, while TurnBasedGameMain dispatches migrated contextual consequences directly to existing domain owners and completes through the same SimpleTurnController turn seam.
- Inventory EAT/DRINK uses exact carried item identity plus existing SurvivorSustainmentProfileCatalog values. The item is lawfully released, freshness state removed where present, the exact WorldState entity consumed, canonical condition gains applied, and existing profile duration becomes explicit elapsed survival time.
- World potable fixtures DRINK into canonical hydration. Beds/furniture expose REST/SLEEP from existing sustainment offers; REST advances one hour and SLEEP eight hours through the manual survival clock without scheduled long actions.
- Doors use existing DoorPhysicalTransitionService and authoritative door/collision state. Windows OPEN/CLOSE use existing WorldInteractableState. Contextual UI browsing/rejection is zero-time.
- Loot SEARCH/pickup contextual offers delegate to the already-migrated Slice 4 simple-turn methods. Crafting workstation discovery remains an entry point to the existing crafting UI; crafting execution itself remains Slice 7.
- The canonical phone shell is TurnBasedPlayerShell -> EquipmentPlayerShell. It changes only EAT/DRINK execution delegation; existing inventory/equipment presentation remains intact.
- The canonical phone header has one unobstructed MENU control. SAVE and SAVE & MENU use the existing DurableSessionStore and Continue lifecycle.

## Transitional boundary

The old runtime remains temporarily instantiated or referenced because bootstrap, the existing durable-session owner chain, and later roadmap routes such as crafting/healing/repair/deconstruction, vehicles and utilities still depend on portions of it. TurnBasedGameMain currently inherits the established durable/condition owner chain as a compatibility bridge, while migrated player action execution remains on the simple-turn route. This is migration debt, not protected architecture.

Legacy WorldInteractionPlayerController scheduled execution is disconnected from the canonical pointer/panel route. WorldInteractionActionService and SurvivorSustainmentActionService remain useful as read-only offer/profile compatibility sources and for still-unmigrated callers, but their timed action execution is not canonical contextual gameplay.

Legacy CombatGameMain, CombatActionService, CombatPlayerController, FirearmActionService, LootSearchActionService, LootPlayerInteractionController, timed ItemTransferActionService and TickKernel-driven condition/fear adapters are not canonical migrated execution. Do not extend them for migrated gameplay. Delete them when remaining legacy dependents migrate safely.

SpatialQueryService and WorldMutationService likewise remain for unmigrated routes/bootstrap but are not dependencies of canonical simple-turn movement/combat/scavenging/inventory/survival/contextual execution.

Rules while migrating:

- no new dependency on TickKernel/WHEN for migrated routes;
- no WHERE 2.0 / WHAT 2.0 / WHEN 2.0;
- plain world state and direct local spatial questions are preferred;
- delete legacy owners/adapters once their final dependent route migrates;
- only locally relevant actors receive individual turns;
- far/unloaded world remains persistent data, not an always-running simulation.

## Game systems to preserve

- open procedural persistent island, generated roads/buildings and streaming;
- scavenging, inventory/equipment and loot;
- zombies, weapons, damage, injury, death and corpses;
- crowd congestion/pressure, fear and darkness/perception pressure;
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
