# Tick Survival Lab — Settled Architecture Map

Status: **active turn-based migration map; Slices 1-11 complete**

## Canonical direction

Tick Lab is a conventional turn-based open-world zombie survival game. The persistent procedural island and gameplay content are retained; the generalized tick/WHERE/WHAT/WHEN execution architecture is legacy and is being removed route by route.

Canonical action flow:

player action -> direct authoritative consequence -> relevant local actors each act at most once -> ordinary time/environment advance -> player control

Do not create a replacement simulation framework.

## Current production spine

- `gameplay.tscn -> VehicleSimpleGameMain -> UtilitySimpleGameMain -> FortificationGameMain -> Slice7GameMain -> TurnBasedGameMain` is the current canonical production composition. These narrow migration subclasses contain explicit domain commits only; none is a generalized action layer.
- ProductionWorldBootstrap owns procedural generation/materialization/streaming.
- SimpleTurnController owns migrated turn completion and bounded local infected actions. Its completion signal remains the single survival elapsed-time seam.
- WorldState owns authoritative entities/placements and narrow direct writes.
- Canonical movement, combat, scavenging, inventory, survival and contextual interaction retain the Slice 1-6 ownership recorded previously.
- Existing CraftingRecipeCatalog/CraftingPlanQuery remain recipe/ingredient/tool/workstation truth. Canonical CRAFT validates the existing plan and skill check, removes exact consumed entities, creates exact recipe outputs and places them in existing authoritative containment.
- Existing PoweredCraftingWorkstationAdapter remains cooking availability truth. Cooking uses the same canonical recipe execution only when the real workstation is available/powered; Slice 7 does not fake utility state.
- Existing SurvivorFirstAidActionService remains treatment-offer/content truth while canonical treatment commit now consumes the exact selected medical resources and writes ActorHealthState injury state directly before ordinary turn completion.
- Existing WorldInteractionCatalog repair/deconstruction profiles remain object/tool/material/difficulty/salvage truth. Canonical repair writes existing broken state and consumes exact materials. Canonical deconstruction removes the actual world object and creates existing salvage semantics in inventory or lawful loose placement.
- Existing WorldInteractableState board counts remain fortification truth. Canonical BOARD/REMOVE BOARD validate real doors/windows, existing Mechanical/tool/material rules, consume/recover exact entities, and mutate the same persistent 0-3 board count used by opening pressure and rendering.
- Craft/heal/repair/deconstruct/fortification durations become explicit elapsed survival ticks through the same Slice 5 seam; no per-action timer or scheduler runs.
- Contextual action-from-thing remains canonical: workstation CRAFT/COOK, broken-object REPAIR, deconstructable-object DECONSTRUCT, and real opening BOARD/REMOVE BOARD use the existing interaction presentation. First aid remains item/injury driven through the existing phone inventory UI.
- Existing ActorOpeningPressureActionService continues to consume installed boards before damaging/breaking an opening; Slice 8 adds no second barricade or siege state.
- The canonical phone shell remains TurnBasedPlayerShell -> EquipmentPlayerShell; Slice 7 adds only first-aid delegation to the canonical owner.
- MENU, SAVE, SAVE & MENU and Continue retain the existing DurableSessionStore lifecycle. `world_interactions` plus ordinary world/inventory snapshots persist fortification and exact material consequences.
- Island road generation is backbone-first: four terrain-routed cross-island four-lane arterial routes establish the sparse major network; developed settlements attach by paved two-lane access, rural settlement access is gravel, and generated local rural lanes/spurs are dirt. Paved production surfaces materialize as asphalt; gravel/dirt carry no painted centerline.
- Existing VehicleState, VehicleProfileCatalog, VehicleCargoService, VehicleHeading and world placements remain vehicle truth. Canonical enter/exit/start/drive/turn/reverse/brake/hotwire/repair/modify/refuel/cargo actions commit those owners directly through VehicleSimpleGameMain and complete through SimpleTurnController with explicit survival time. Legacy TickKernel vehicle scheduling is not canonical player execution.
- `WorldTimeService` is now the authoritative scenario clock in canonical play. It advances explicitly from the same elapsed-tick value already consumed by survival, never from render frames or wall time. `OutdoorAmbientLightService` derives dawn/day/dusk/night continuously from that clock.
- Existing `WeatherService` / `WeatherState` / `WeatherProfile` remain weather truth, but canonical play advances weather coarsely to the authoritative world-time tick rather than scheduling physical weather through TickKernel. Existing atmospheric optics, acoustics, GPU weather presentation and lighting/perception consumers remain downstream.
- Durable sessions persist optional canonical `world_time` state alongside existing weather state. Older saves without that owner migrate from the restored survival clock instead of failing.
- Vehicle footprints and geometry remain established content: cars use the existing 1x3 footprint, trucks 2x3, ordinary vehicle turns use the existing three-cell 90-degree path, and reverse remains supported. Zero nearby vehicles is valid world content and never a boot requirement.

## Transitional boundary

The old runtime remains temporarily instantiated/referenced because bootstrap, durable-session compatibility, utilities and later routes still depend on portions of it. Legacy vehicle services may remain instantiated as compatibility/content owners, but their timed execution path is no longer canonical. This is migration debt, not protected architecture.

`Slice7GameMain` and `FortificationGameMain` are explicit migration debt: they keep migrated domain commits readable while the older inheritance chain still supplies legacy owners. They must not grow into generalized action frameworks and should be folded away during later consolidation/legacy demolition.

Legacy CraftingActionService timed execution, SurvivorFirstAidActionService scheduled execution, WorldObjectRepairActionService scheduling, and WorldInteractionActionService scheduling for migrated deconstruction/fortification actions are no longer canonical player execution. Their catalogs/offer queries may remain useful until remaining dependents migrate.

Legacy WorldInteractionPlayerController scheduled execution, combat action services, loot timed services, TickKernel-driven condition/fear adapters, SpatialQueryService and WorldMutationService remain noncanonical migration dependencies where still required.

Rules while migrating:

- no new dependency on TickKernel/WHEN for migrated routes;
- no WHERE 2.0 / WHAT 2.0 / WHEN 2.0;
- no generalized craft/job/action/build replacement layer;
- plain authoritative state and narrow domain owners are preferred;
- delete legacy owners/adapters once their final dependent route migrates;
- only locally relevant actors receive individual turns;
- far/unloaded world remains persistent data, not an always-running simulation.

## Game systems to preserve

- open procedural persistent island, generated roads/buildings and streaming;
- scavenging, inventory/equipment and loot;
- zombies, weapons, damage, injury, death and corpses;
- crowd pressure, fear and darkness/perception pressure;
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
- Production identity is actor.player.
- A base is an existing building the player fortifies and supplies; no settlement management or freeform construction engine.
- Persistence serializes ordinary authoritative state; do not create duplicate gameplay truth.

## Explicitly retired direction

Shared universal simulation ticks, generalized simultaneous resolution, universal commitment/interruption, generalized WHEN scheduling, heavyweight WHERE/WHAT runtime frameworks, living survivor social simulation, colony management, freeform base construction and demo-owned production startup remain retired.

See ROADMAP.md for migration order and CURRENT.md for the exact next operation.
