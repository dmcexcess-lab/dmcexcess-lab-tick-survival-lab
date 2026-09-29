# Tick Survival Lab — Settled Architecture Map

Status: **active turn-based production map; Slices 1-15 complete / rewrite complete**

## Canonical direction

Tick Lab is a conventional turn-based open-world zombie survival game. The persistent procedural island and gameplay content are retained; the generalized tick/WHERE/WHAT/WHEN execution architecture is legacy and is being removed route by route.

Canonical action flow:

player action -> direct authoritative consequence -> relevant local actors each act at most once -> ordinary time/environment advance -> player control

Do not create a replacement simulation framework.

## Current production spine

- `gameplay.tscn -> ProductionGameMain -> VehicleSimpleGameMain -> UtilitySimpleGameMain -> FortificationGameMain -> Slice7GameMain -> TurnBasedGameMain` is the canonical production composition. `ProductionGameMain` now owns the previously separate Slice 11-13 time/weather, streaming-boundary and persistence seams.
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
- Existing VehicleState, VehicleProfileCatalog, VehicleCargoService, VehicleHeading and world placements remain vehicle truth. Canonical enter/exit/start/drive/turn/reverse/brake/hotwire/repair/modify/refuel/cargo actions commit those owners directly through VehicleSimpleGameMain and complete through SimpleTurnController with explicit survival time. The former VehiclePlayerController route is deleted.
- `WorldTimeService` is now the authoritative scenario clock in canonical play. It advances explicitly from the same elapsed-tick value already consumed by survival, never from render frames or wall time. `OutdoorAmbientLightService` derives dawn/day/dusk/night continuously from that clock.
- Existing `WeatherService` / `WeatherState` / `WeatherProfile` remain weather truth, but canonical play advances weather coarsely to the authoritative world-time tick rather than scheduling physical weather through TickKernel. Existing atmospheric optics, acoustics, GPU weather presentation and lighting/perception consumers remain downstream.
- Durable session schema 2 persists canonical gameplay facts and no longer requires TickKernel queues, perception-memory caches or combat runtime snapshots. Durable truth includes world/materialization identity, player/domain state, exact containment/equipment, Health/conditions, loot/world interactions, infected/corpses, vehicles, utilities, weather/world time and refrigeration exposure state.
- DurableSessionStore keeps the same canonical session schema but compresses the file-envelope payload with DEFLATE when beneficial. Existing pre-Slice-15 uncompressed envelopes remain readable; compression is storage representation only and creates no second persistence truth.
- Streaming membership, the Slice 12 active infected roster, perception memory, controller state, HUD/render state and other runtime caches are reconstructed after restore rather than persisted as parallel truth.
- Schema 1 remains loadable for the current save lineage. Its legacy runtime dictionaries are ignored by canonical restore; world time is derived exactly from restored condition anchors when `world_time` is absent, and legacy refrigeration resumes from a safe non-regressing exposure baseline before the next schema-2 save.
- Freshness queries and refrigeration exposure clocks use authoritative `WorldTimeService` in canonical play rather than restored TickKernel time.
- Canonical infected simulation uses the existing streaming coordinator as the first eligibility boundary and the existing SimpleTurnController active radius as the second. Only infected whose authoritative placement is in an active streamed region are placed in the response roster; far/unloaded infected remain persistent WorldState/Health state but receive no pathfinding/attack/individual turn work.
- Procedural infected resident records are projected once and cached for Slice 12 activation. Boundary changes hydrate only resident homes that have entered active streaming space; ordinary same-region actions do not rescan the island population.
- SimpleTurnController refreshes that active roster immediately before local infected responses, so entering a new streamed neighborhood makes its eligible infected available without waking the rest of the island. Long elapsed-time actions still create only one ordinary local response boundary.
- Vehicle footprints and geometry remain established content: cars use the existing 1x3 footprint, trucks 2x3, ordinary vehicle turns use the existing three-cell 90-degree path, and reverse remains supported. Zero nearby vehicles is valid world content and never a boot requirement.

## Remaining compatibility boundary

Slice 14 physically removed the obsolete player-facing scheduled execution graph rather than merely bypassing it. Deleted production/runtime branches include the old player, door, loot, crafting, vehicle, world-interaction and combat controllers; scheduled crafting/item-transfer/loot/door/firearm player execution; old consequence presentation; the legacy world-resolution indicator; and condition event adapters that canonical survival immediately disconnected.

The Slice 11, Slice 12 and Slice 13 migration subclasses were folded into `ProductionGameMain` and deleted.

TickKernel still exists as a **noncanonical compatibility remnant**. Current production still passes it to a small set of older systems whose player-visible behavior was not redesigned in Slice 14:

- ForageNearbyActionService still performs the FORAGE action through its existing timed route.
- Utility generator/power/flashlight/lighting code still uses the old tick callback/clock API.
- Spatial sound, perception and some phone-panel pause/status APIs still accept TickKernel.
- The legacy infected cohort remains because ActorOpeningPressureActionService still supplies the existing zombie pressure/barricade behavior through that cohort; its movement/combat helper path still expects TickKernel.

Canonical movement, melee/firearm player combat, inventory/loot transfer, contextual interaction, craft/cook/heal/repair/deconstruct/fortification, vehicle actions, survival/world-time advancement and durable Continue do **not** advance TickKernel. The Slice 14 verifier explicitly guards that boundary.

Useful foundations remain canonical and are not legacy merely because they originated during earlier architecture work: WorldState, WorldMutationService, SpatialQueryService, placements/footprints/layers, collision, generation/materialization/streaming and typed domain state all remain ordinary game infrastructure.

No replacement scheduler, event bus, ECS or generic action framework was introduced.

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

The rewrite is complete. See ROADMAP.md for the closed migration sequence and CURRENT.md for release-maintenance direction.
