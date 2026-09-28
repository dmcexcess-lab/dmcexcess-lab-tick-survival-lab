# Tick Survival Lab — Latest Changes

This compact ledger records the newest executable work. CHANGELOG.md remains the historical archive.

## Turn-based rewrite Slice 4 — scavenging and inventory — 2026-09-27

- Canonical SimpleTurnController now owns ordinary search, take, store, equip, stow, drop and narrow loose-item pickup actions in addition to movement/combat.
- Real generated LootState / InventoryContainmentState contents remain authoritative; inspection is read-only and never rerolls or respawns removed loot.
- Exact item identity survives real-container take, player containment, equipment, protected melee use, stow, loose-world drop, re-pickup and store back into the original generated container.
- Carry acquisition limits, interaction reach, authoritative containment mutation and hand-equipment mutation remain the existing domain owners; no second inventory list or active-weapon state was introduced.
- The existing LootContainerPanel and EquipmentPlayerShell were retained and rewired to the simple-turn route. Their canonical path no longer executes timed ItemTransferActionService or LootSearchActionService.
- Search and successful material inventory mutations each consume one ordinary turn and run the bounded local infected phase. Pure inspection and rejected actions consume no turn.
- Dropped items become real LOOSE_ITEM placement and can be picked up again through the narrow production pointer route.
- Focused production run 36362797618: SUCCESS, marker SLICE4_SCAVENGE_INVENTORY_OK seed=20001 turns=8 ... melee_damage=1. It proves real generated loot, read-only inspection, bounded zombie response, exact take/store/equip/stow/drop/pickup identity, no respawn, rejected-action atomicity, zero TickKernel advancement and the protected Slice 3 equipped-item melee regression.
- Static guards reject TickKernel, ItemTransferActionService, LootSearchActionService, TimedAction, ScheduledEvent and run_until_stop dependencies from SimpleTurnController.


## Turn-based rewrite Slice 3 — simple turn-based combat — 2026-09-27

- Canonical SimpleTurnController now accepts player.combat_forward alongside movement; a valid player combat action consumes exactly one ordinary turn before bounded sequential infected actions.
- Forward melee reuses the existing physical impact catalog and real equipped hand-item mass/profile facts, then writes damage and injury directly to canonical ActorHealthState.
- Existing firearm content is retained without the old scheduler: FirearmState still owns exact firearm, magazine and chambered live-round identities; a discharge consumes the exact chambered round, cycles the next round when present and applies the existing firearm damage/gunshot injury.
- Procedurally projected infected are enrolled into canonical Health, hand-equipment and containment state. An adjacent living infected may attack on its one local action; otherwise the existing bounded greedy movement remains. Distant infected receive no individual turn.
- Generic death/corpse transition no longer requires TickKernel or WorldMutationService. Lethal Health state immediately transfers exact equipment/carried items and replaces the living placement with non-blocking persistent corpse state.
- WorldState now exposes narrow ordinary create/remove/place/unplace writes for migrated turn routes, extending the direct authoritative-state direction established by Slice 2 instead of introducing a replacement mutation framework.
- Legacy CombatGameMain / tick-based combat services remain noncanonical migration debt only because older app composition/source dependencies still reference them. The canonical combat route does not call them.
- Focused production run 36361532785: SUCCESS, marker SLICE3_SIMPLE_COMBAT_OK seed=20001 turns=2 ... firearm_damage=34. It proves real procedural boot, one-turn lethal melee, authoritative corpse transition, one adjacent infected attack, distant infected inactivity, control return, exact-round firearm discharge/damage/injury, and zero TickKernel advancement across both combat actions.
- Static guards reject TickKernel, CombatActionService, MovementActionService, SpatialQueryService, WorldMutationService, TimedAction and ScheduledEvent dependencies in the migrated controller, and reject TickKernel/WorldMutationService in the migrated death transition.

## Turn-based rewrite Slice 2 — plain movement state/query path — 2026-09-27

- Canonical `SimpleTurnController` no longer depends on `SpatialQueryService` or `WorldMutationService` for player/zombie movement.
- Movement legality now reads the candidate footprint directly against authoritative `WorldState` terrain/occupancy and the existing collision catalog/override facts.
- `WorldState.move_entity()` is the narrow ordinary placement write for migrated turn movement; rendering/persistence observers continue to receive authoritative world changes.
- Sequential zombie turns resolve against current occupancy; only the established 24-cell active neighborhood receives individual zombie work.
- No TickKernel, WHEN queue, `MovementActionService`, generalized footprint query or simultaneous movement resolver executes underneath the migrated route.
- Production seed 20001 booted and completed consecutive simple turns in the focused Slice 2 verifier; static guards reject reacquiring the retired movement dependencies.
- Legacy query/mutation owners remain for generation/bootstrap and unmigrated combat/interactions/vehicles; that is explicit migration debt.

## Turn-based rewrite Slice 1 — simple production turn spine — 2026-09-27

- Project direction changed deliberately: preserve the open procedural zombie-survival game while retiring the experimental tick/WHERE/WHAT/WHEN execution architecture route by route.
- Canonical `gameplay.tscn` now boots through `TurnBasedGameMain`.
- Unmounted player movement bypasses `PlayerActionController`, `MovementActionService` and `TickKernel` execution. One movement input performs one ordinary placement mutation.
- `SimpleTurnController` gives only infected within a 24-cell active radius at most one ordinary adjacent movement after a successful player action, then immediately returns control.
- Distant infected receive no individual turn. The persistent procedural world is not iterated as a simulation.
- Production streaming focus, perception and visual flush follow the completed simple turn.
- Legacy systems remain temporarily booted for unmigrated combat/interactions/persistence; they are not executed underneath the new movement route.
- Focused run `36352629634`: **SUCCESS**. It proves two consecutive player turns, exact one-tile movement, bounded infected work, distant infected inactivity and `TickKernel` world-tick delta `0` across the simple movement route.

## Production infrastructure reservation repair — 2026-09-27

- Real iPhone/Safari NEW GAME reached production generation and exposed `generation_failed:area.smalltown.center.001:infrastructure_reservation_unresolved...`.
- Root cause: a legitimate global infrastructure node could land near an area/road edge where the reservation planner tested only the two perpendicular facility rectangles at that exact source cell. A legal substation frontage farther along the same inherited road was ignored, causing an otherwise valid generated small-town center to fail.
- `InfrastructureReservationPlanner` now keeps the global node as semantic source truth but searches deterministically along its same inherited road for the nearest legal roadside facility footprint. It does not reroll the world, invent a fallback town, or move the infrastructure to an unrelated road.
- Added focused edge-source recovery verification plus the existing procedural-island seed matrix as the bounded protected regression.
- Focused run `36350128246`: **SUCCESS**; both reservation recovery and the procedural island seed matrix passed.
- Real iPhone/Safari NEW GAME remains the final acceptance gate for production bootstrap.

## Production world bootstrap separation — 2026-09-27

- Confirmed the canonical playable game was incorrectly booting through `scripts/demo/GeneratedIslandCritiqueFixture.gd`; production identity, spawn, map UI and downstream app composition still inherited demo-era ownership.
- Added `generation/integration/ProductionWorldBootstrap.gd` and promoted generated-world collision/traversal rule installation into production integration code.
- Canonical app chain now uses `_boot_production_world()` and `WorldBootstrapClass`; production player identity is `actor.player`.
- Production spawn is selected from actual generated area sites/roads near world center rather than requiring `area.rural.crossroads.001`, `dev.rural_crossroads`, the diner fixture or `actor.player.demo`.
- Utility runtime binds initial service truth to the actual production player cell rather than the demo central-settlement constant.
- `PlayerMapBootstrap` now reads the production global plan/player identity directly.
- NEW GAME only retries failures classified as genuine procedural generation/spawn invalidity; deterministic bootstrap/materialization/configuration failures are surfaced with their production reason instead of being mislabeled as bad seeds.
- The focused verifier statically rejects demo dependencies anywhere in canonical app scripts, boots the real gameplay scene, verifies generated spawn/render/one-region materialization, crosses a streaming-region boundary, snapshots the durable session, and proves Continue restores the same seed/player/world identity.
- Focused run `36348729521`: **SUCCESS**, marker `PRODUCTION_WORLD_BOOTSTRAP_OK ... demo_free=true save_continue=true`.
- The previous rejected-seed recovery was symptom treatment and is superseded by this production ownership repair.

## Mobile/Safari rejected-seed recovery — 2026-09-26 (superseded)

- The bounded retry exposed that the canonical runtime still depended on demo bootstrap ownership. Its prompt-local verifier/workflow has been retired.

## Mobile/Safari bootstrap footprint repair — 2026-09-26

- Initial streaming was bounded from a 3x3 128x128 neighborhood to the single 128x128 focus region while preserving the procedural world and streaming identity.
- Focused run `36286982875`: **SUCCESS**.

## Mobile/Safari new-game bootstrap repair — 2026-09-26

- Removed duplicate disposable initial-neighborhood materialization before authoritative world materialization.
- Focused production run `36281756339`: **SUCCESS**.