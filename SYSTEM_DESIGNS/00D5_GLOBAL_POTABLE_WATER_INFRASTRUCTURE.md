# Tick Survival Lab — System 00D5 Global Potable-Water Infrastructure

Status: **IMPLEMENTED — CURRENT SINGLE-FACILITY WATER CONTRACT**

Updated: **2026-09-05**

Parent: `00D_GLOBAL_WORLD_PLANNING.md`

Downstream runtime: `33_POWER_WATER_UTILITIES.md`

## 1. Purpose

System 00D5 owns deterministic global potable-water planning identity. It defines the island's one municipal water facility and settlement-facing service aliases that reference it before local materialization. System 33 owns current service availability, physical condition, private wells, outages and repair.

The previous plant-node/network, service-radius and decentralized municipal topology are retired. They are not empty versions of the current contract; they are outside the active contract.

## 2. Current canonical model

The island has **one authoritative municipal water facility represented by one already-generated real building**.

Global planning records:

- one stable facility identity: `water.facility.island`;
- one stable host site and host settlement;
- a preferred existing host-building archetype, currently `civic.post_office.small`, with deterministic fallback to another generated building at the host site if needed;
- one lightweight municipal service reference for each settlement so local projection/runtime consumers can resolve water without inventing another facility;
- every service reference points to the same facility identity, host site and host settlement;
- `service_mode = island_wide_municipal`;
- `source_type = treated_municipal`;
- `island_wide = true`.

There is **no active municipal node/segment/pipe topology**. The per-settlement records are aliases to the same island facility, not separate plants or implied physical pipes.

## 3. Municipal availability rule

> **If the one municipal facility building is operational, municipal water is available island-wide. If that facility is failed, municipal water is unavailable island-wide.**

Distance, settlement boundaries and technical streaming regions do not affect service. There are intentionally no regional mains, parcel pipe routes, pressure zones, storage nodes, flow solvers or radius-based coverage checks.

System 20 may project the lightweight municipal service reference into a settlement window. It must not create water-node geometry, pipe corridors or another local treatment facility.

## 4. Physical facility boundary

System 33 resolves the 00D5 host identity to the **existing generated building** in the structural local-area manifest and uses that building as the real damageable municipal water asset.

System 33 must not materialize a second treatment shed, tank complex or duplicate municipal plant shell. Failure removes municipal service island-wide; repair restores the same service.

## 5. Power relationship

The municipal facility is **self-contained for this gameplay contract** and does not require external grid power. A grid blackout alone must not disable municipal water.

This is a deliberate gameplay rule, not a claim about real-world water engineering.

## 6. Rural private wells

Private wells are selected downstream by System 33 from the **actual generated rural-building manifest**.

Current rule:

- candidates are generated buildings on `rural.*` sites;
- town/non-rural buildings are never candidates;
- deterministic selection covers **10–20% of rural buildings** when the candidate count is sufficient;
- selection is stable from world seed + stable building identity;
- one well maximum per selected building;
- the private well replaces municipal water for that building;
- private wells have no external-grid dependency;
- a failed private well leaves the owning building dry until repaired;
- a failed well does **not** fall back to municipal water;
- a healthy private well remains available during a municipal-facility outage.

Non-well rural buildings and all town buildings use the island-wide municipal facility.

## 7. Determinism

For the same world seed/profile version:

- municipal facility identity and host selection are stable;
- settlement municipal-service references are stable;
- all aliases resolve to the same facility;
- System 33 rural-well selection is stable because it consumes stable generated building IDs.

No call-order RNG, renderer state or streaming state defines water truth.

## 8. Validation

`GlobalWaterInfrastructureValidator` validates the current behavior directly:

- municipal service references are present;
- every current settlement has exactly one island-wide municipal service reference;
- all references share one facility identity, host site and host settlement;
- every reference uses the current municipal service/source modes;
- host site/settlement identities are valid.

Retired `water_nodes`, `water_segments` and wastewater arrays are **not** required to exist or be empty for current water validity. Part one of the generator cleanup removed those compatibility assertions from active planning/runtime/CI contracts.

`GlobalWorldPlanner` fails honestly if the current municipal-service contract is invalid.

## 9. Ownership boundaries

00D5 does not own:

- tactical building art;
- municipal-facility or well condition/repair;
- private-well selection;
- building plumbing, drinking or container filling;
- water quantity, pressure, flow or contamination;
- wastewater/sewer/septic systems;
- retired hydrology/river/bridge topology.

## 10. Verification

Part-one contract cleanup executable: `90a919ac367f9cf247c8915f065135f2f1592d79` (`Align System 20 CI with retired hydrology contract`).

On that exact head:

- `verify/system33-power-water` run `33992117806` — **SUCCESS**;
- `verify/system20-local-area` run `33992117847` — **SUCCESS**;
- `verify/system00d-global-world` run `33992117848` — **SUCCESS**;
- `verify/pages-deploy` run `33992117751` — **SUCCESS**.

The broader suite still contains unrelated pre-existing red checks; this document does not claim otherwise.
