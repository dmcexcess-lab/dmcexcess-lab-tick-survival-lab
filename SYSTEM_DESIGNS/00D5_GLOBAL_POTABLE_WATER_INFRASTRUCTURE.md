# Tick Survival Lab — System 00D5 Global Potable-Water Infrastructure

Status: **IMPLEMENTED — CURRENT v7 WATER CONTRACT**

Updated: **2026-08-30**

Parent: `00D_GLOBAL_WORLD_PLANNING.md`

Downstream runtime: `33_POWER_WATER_UTILITIES.md`

## 1. Purpose

System 00D5 owns deterministic global potable-water planning identity. It defines the island's municipal source/treatment/service relationship before local materialization, while System 33 owns physical assets, operational condition, private wells, outages and repair.

The previous mixed municipal/decentralized settlement-radius design is superseded.

## 2. Current canonical model

The island has **one municipal treatment facility** near the shoreline and **island-wide municipal service**.

Global planning records:

- one stable plant/network identity;
- one `raw_water_source` planning node;
- one `treatment_plant` planning node;
- one `island_service_anchor` planning node;
- two short `plant_internal` planning segments joining those three nodes;
- one municipal service record for every settlement, all referencing the same plant/network;
- `service_mode = island_wide_municipal`;
- `source_type = treated_municipal`;
- `island_wide = true`;
- no positive service radius.

The three planning nodes describe the compact plant itself. They are **not** a simulated island pipe network.

## 3. No long-distance hydraulic simulation

There are intentionally no regional municipal mains, parcel pipe routes, pressure zones, water-flow solvers or radius-based coverage checks.

A settlement or building does not lose municipal service because it is geographically far from the plant. Municipal availability is a causal runtime fact derived from the shared plant's condition.

System 20 may project the one municipal service into any settlement window. Plant nodes/segments appear only where their actual compact plant geometry intersects that window; downstream code must not invent local trunk geometry merely because a settlement receives water.

## 4. Physical plant boundary

System 33 materializes the real plant from the stable 00D5 identity. Current physical presentation is a small fenced utility facility containing a shed/plant body, tank-like storage, industrial machinery and a utility box.

The treatment plant exposes one stable critical physical asset identity. Failure of that critical asset removes island-wide municipal service; repair restores it through the same authoritative runtime state.

## 5. Power relationship

The municipal plant is **self-contained for this gameplay contract** and does not require external grid power.

Its municipal water binding therefore has no required power-service dependency. A grid blackout alone must not disable the municipal plant.

This is a deliberate gameplay rule, not a claim about real-world treatment-plant engineering.

## 6. Rural private wells

Private wells are **not global 00D5 settlement intent anymore**. They are selected downstream from the actual generated rural-home manifest so the game never creates a well for an imaginary property.

System 33 currently targets 15% of generated rural residential buildings, bounded to 10–20% whenever the rural-home population is large enough for that range to be meaningful. Selection is deterministic from world seed + stable building identity.

Each selected well becomes a real persistent physical asset and a private water service for its building. Unlike the municipal plant, the current private well is electrically pumped and depends on that building group's real power service.

## 7. Determinism

For the same world seed/profile version:

- plant identity and compact plant topology are stable;
- settlement municipal-service records are stable;
- the plant stays near the shoreline under the validator's bounded shore-distance rule;
- System 33's later rural-well selection is stable because it consumes stable generated building IDs.

No call-order RNG or render/stream state defines water truth.

## 8. Validation

`GlobalWaterInfrastructureValidator` proves:

- exactly one plant/network;
- exactly three plant nodes with the required roles;
- exactly two non-zero `plant_internal` segments;
- every current settlement has one island-wide municipal service record;
- every service references the same source, treatment, service anchor, plant, network and critical asset;
- no positive radius is present;
- the treatment plant lies inside world bounds, off the regional road surface and within the allowed shoreline distance;
- IDs are unique and the compact source -> treatment -> service-anchor chain is connected.

`GlobalWorldPlanner` fails honestly if this contract is invalid.

## 9. Ownership boundaries

00D5 does not own:

- tactical plant art/materialization;
- plant/well condition or repair;
- private-well selection;
- building plumbing, drinking or container filling;
- water quantity, pressure, flow or contamination;
- wastewater/sewer/septic systems.

Those concerns either belong downstream or are not active systems.

## 10. Verification

The current executable contract is covered by the global-world-planning v7 smoke and `verify/system33-power-water`.

Verified executable: `a0299a14d21fb907bdd363ddadb00cc3403b48f1`.
