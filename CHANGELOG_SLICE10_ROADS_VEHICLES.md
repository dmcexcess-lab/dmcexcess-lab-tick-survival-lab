# Slice 10 — Road Hierarchy + Vehicles — 2026-09-29

## Outcome

Slice 10 closes the road/vehicle dependency as one production change: virgin island generation now establishes a believable transportation hierarchy before vehicle gameplay uses that world, and canonical vehicle actions no longer execute through the generalized timed scheduler.

## Roads

- Replaced settlement-first major-road routing with a sparse backbone-first island network.
- Four terrain-routed cross-island four-lane arterial routes form the major transportation backbone.
- Small towns and rural crossroads attach through paved two-lane access roads.
- Rural settlement access uses gravel.
- Local rural/scattered/farm/home lanes and spurs use dirt.
- Paved road surface materialization now uses asphalt rather than the visually gravel-like legacy road tile.
- Paved routes keep markings; gravel and dirt routes remain unpainted.
- Existing terrain-aware routing, procedural island ownership, projection, streaming and deterministic generation remain in place.
- Utility span support search was widened only enough to remain compatible with the wider corrected arterial geometry; utility topology/state ownership did not change.

## Vehicles

Production now composes:

`gameplay.tscn -> VehicleSimpleGameMain -> UtilitySimpleGameMain -> FortificationGameMain -> Slice7GameMain -> TurnBasedGameMain`

Canonical vehicle input bypasses the legacy VehiclePlayerController/TickKernel timed route. Existing VehicleState, VehicleProfileCatalog, VehicleHeading, VehicleCargoService, placements, collision queries and consequence adapters remain authoritative.

Direct simple-turn vehicle actions cover:

- enter / exit;
- start / hotwire;
- forward / turn / reverse / brake;
- fuel consumption / refuel;
- repair / cargo-rack modification;
- cargo store / take;
- collision consequences.

Each accepted action commits authoritative state directly, supplies explicit elapsed survival time, allows each relevant local infected at most one ordinary response, then returns control.

Established car/truck footprints, three-cell vehicle turns, reverse behavior, fuel/condition/cargo/key state, dedicated presentation and durable vehicle snapshots remain intact. A start with zero nearby vehicles remains valid.

## Verification

Fresh prompt-local verification:

- `game/scripts/ci/verify_slice10.gd`
- `.github/workflows/slice10.yml`

The verifier exercises real island generation across explicit seeds, production-facing road materialization, rural local dirt roads, actual production gameplay boot, and generated vehicle enter/start/move/turn/reverse/repair/refuel/cargo/exit through the direct simple-turn route. It also guards against canonical vehicle movement returning to TickKernel scheduling.

The first production integration run exposed a utility-support placement assumption around the wider road geometry; that dependency was repaired. The focused Slice 10 run and Pages then passed on the same code lineage.
