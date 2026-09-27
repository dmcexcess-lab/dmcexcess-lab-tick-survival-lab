# Tick Survival Lab — Latest Changes

This compact ledger records the newest executable work. `CHANGELOG.md` remains the historical archive.

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