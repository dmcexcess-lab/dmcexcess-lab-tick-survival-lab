# Tick Survival Lab — System 00D5 Global Potable-Water Infrastructure

Status: **IMPLEMENTED — CURRENT SINGLE-FACILITY WATER CONTRACT**

Updated: **2026-09-05**

Parent: `00D_GLOBAL_WORLD_PLANNING.md`

Downstream runtime: `33_POWER_WATER_UTILITIES.md`

## 1. Purpose

System 00D5 owns deterministic global potable-water planning identity. It defines the island's one municipal water facility and the settlement-facing service aliases that reference it before local materialization. System 33 owns current service availability, physical condition, private wells, outages and repair.

The previous plant-node/network model, settlement-radius model and mixed decentralized municipal topology are superseded.

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
- `island_wide = true`;
- no municipal water nodes;
- no municipal water segments;
- no pipe/network topology;
- no positive service radius.

The per-settlement records are aliases to the same island facility. They are not separate plants and they do not imply physical pipes between settlements.

## 3. Municipal availability rule

Municipal water is intentionally simple:

> **If the one municipal facility building is operational, municipal water is available island-wide. If that facility is failed, municipal water is unavailable island-wide.**

Distance from the facility, settlement boundaries and technical streaming regions do not affect service.

There are intentionally no regional municipal mains, parcel pipe routes, pressure zones, storage nodes, flow solvers or radius-based coverage checks.

System 20 may project the lightweight municipal service reference into any settlement window. It must not create water-node geometry, pipe corridors or a local treatment facility merely because that settlement receives water.

## 4. Physical facility boundary

System 33 resolves the 00D5 host identity to the **existing generated building** in the structural local-area manifest and uses that building as the real damageable municipal water asset.

System 33 must not materialize a second treatment shed, tank complex or duplicate municipal plant shell beside it.

The facility building exposes one stable operational component. Failure of that component removes municipal service island-wide; repair restores the same service.

## 5. Power relationship

The municipal facility is **self-contained for this gameplay contract** and does not require external grid power.

Its municipal water binding therefore has no required power-service dependency. A grid blackout alone must not disable municipal water.

This is a deliberate gameplay rule, not a claim about real-world water engineering.

## 6. Rural private wells

Private wells are not global 00D5 settlement intent. They are selected downstream by System 33 from the **actual generated rural-building manifest**, so the game never creates a well for an imaginary property.

Current rule:

- candidates are generated buildings whose owning area site is rural;
- town/non-rural buildings are never candidates;
- the deterministic selected count is within **10–20% of rural buildings** when the rural population is large enough for that range to be meaningful;
- selection is stable from world seed + stable building identity;
- each selected building receives one private well identity/service;
- the private well replaces municipal water for that building rather than acting as a fallback bonus source;
- a private well has no external-grid dependency;
- if that well fails, the owning building has no water until the well is repaired;
- a broken well does **not** silently fall back to municipal water;
- a working private well remains available during a municipal-facility outage.

Non-well rural buildings and all town buildings use the island-wide municipal facility.

## 7. Determinism

For the same world seed/profile version:

- municipal facility identity and host selection are stable;
- settlement municipal-service references are stable;
- all municipal aliases resolve to the same facility;
- System 33's rural-well selection is stable because it consumes stable generated building IDs.

No call-order RNG, renderer state or streaming state defines water truth.

## 8. Validation

`GlobalWaterInfrastructureValidator` proves the current simplified contract:

- municipal service references are present;
- every current settlement has exactly one island-wide municipal service reference;
- all references share one facility identity, host site and host settlement;
- every reference uses the current municipal service/source modes;
- `water_nodes` is empty;
- `water_segments` is empty;
- populated municipal topology is rejected;
- wastewater service/node/segment arrays must remain empty;
- host site/settlement identities are valid.

`GlobalWorldPlanner` fails honestly if this contract is invalid.

## 9. Ownership boundaries

00D5 does not own:

- tactical building art;
- municipal-facility or well condition/repair;
- private-well selection;
- building plumbing, drinking or container filling;
- water quantity, pressure, flow or contamination;
- wastewater/sewer/septic systems.

Those concerns either belong downstream or are not active systems.

## 10. Verification

The current executable contract is covered by `verify/system00d-global-world` and `verify/system33-power-water`.

Verified executable: `4ced86b353d273d54b89e0fb52499f564172364b`.

On that exact executable, `verify/system33-power-water` run `33988514222` succeeded and `verify/pages-deploy` run `33988514204` succeeded.
