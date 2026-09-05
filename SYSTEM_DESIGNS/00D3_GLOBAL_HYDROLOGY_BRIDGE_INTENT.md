# Tick Survival Lab — System 00D Slice 003 Global Hydrology / Bridge Intent

Status: **RETIRED / HISTORICAL ONLY**

Originally implemented: 2026-08-21
Retired: 2026-09-05

## 1. Historical purpose

This slice previously defined generated global river routes, hydrology-aware settlement/road constraints, explicit road/river bridge intents, and a System 20 hydrology projection seam.

That model is no longer part of the active procedural island.

## 2. Current canonical truth

The retired implementation has been physically removed:

- no `GlobalHydrologyPlanner` or `GlobalHydrologyQuery`;
- no `GlobalBridgeIntentPlanner` or river-only bridge-intent planning;
- no generated `river_segments` / `bridge_intents` compatibility fields on `GeneratedGlobalWorldPlan`;
- no System 20 hydrology/watercourse projection seam;
- no local river/watercourse generation or streaming source/catalog.

Generic settlement and road planning now operate from geography and the current road network without hidden empty-river arguments.

**Coastline, shore and ocean generation remain active island-surface truth.** Retiring this slice does not remove the coast or ocean.

## 3. Why this file remains

This file is retained only as historical design provenance so old commits, changelog entries and implementation references remain understandable. It is not an active dependency and must not be used as justification to recreate river, bridge-intent or watercourse compatibility surfaces.

Any future rivers, streams, crossings or bridge gameplay require a new explicit design approved against the current island generator rather than resurrection of this retired slice.

## 4. Anti-regression contract

Current focused generator verification asserts that the retired hydrology, bridge-intent, wastewater and watercourse generator source files remain physically absent. Active global-planning CI must validate their absence, not require them to exist.
