# Tick Survival Lab — System 00D Global World Planning

Status: **IMPLEMENTED — CURRENT PROCEDURAL ISLAND**

Updated: **2026-09-05**

## 1. Authority

System 00D owns deterministic large-scale semantic world truth before local generation/materialization/runtime simulation.

Current canonical direction:

`world seed -> geography/island surface -> settlements/sites -> roads -> regional power + municipal-water service identity -> planning regions -> System 20 local areas -> System 19 buildings -> WHAT materialization -> runtime mutation`

System 00D is pure generation-time planning. It does not own runtime utility condition, rendering, player movement, building interiors, streaming activation or simulation clocks.

## 2. Current island model

`temperate.island.region` v9 uses a 3072×3072 procedural island envelope with:

- deterministic `LAND`, `SHORE` and `OCEAN` surface truth;
- coastline/ocean geometry derived from world seed;
- two 512×512 small-town anchors;
- three compact rural crossroads;
- thirty distributed sparse rural home/farm sites;
- non-overlapping settlement envelopes with managed countryside between them;
- ordinary road connectivity derived from geography and settlement topology;
- regional power planning/provenance;
- one island municipal-water facility identity plus lightweight service aliases;
- a retained compact local-area manifest used by startup population/utility consumers.

Reference-island verification requires roughly 550–650 real generated buildings rather than a population multiplier or fake resident count. The actual resident population is derived from generated residential capacity.

## 3. Retired generated infrastructure

The following former planning layers are **not active contracts** and their implementation sources are physically absent:

- global hydrology / generated river planning and queries;
- river-only bridge-intent planning;
- System 20 hydrology/watercourse projection;
- local river/watercourse generation, projection and streaming sources;
- wastewater/sewer/septic planning/query/validation;
- municipal-water node/segment/pipe topology compatibility fields.

`00D3_GLOBAL_HYDROLOGY_BRIDGE_INTENT.md` and `00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md` remain historical documents only.

Retiring generated river/watercourse systems **does not retire coastline, shore or ocean generation**.

## 4. Geography / settlement / road invariants

- island surface classification is world-generation truth;
- settlements remain on legal land and do not overlap;
- settlement envelopes leave substantial countryside outside settlement cores;
- current road planners route from geography and settlement topology without a hidden river argument;
- ordinary power and road generation remain intact;
- local-area boundaries do not reset deterministic ecology/land-use phase;
- future rivers or bridges require a new explicit design rather than compatibility shims for the retired model.

## 5. Power planning boundary

00D4 retains deterministic regional electrical provenance and stable source/network facts.

The current playable System-33 composition derives **local substations from actual generated buildings**, targeting roughly ten buildings per substation. Regional source -> local substation remains a logical/non-physical runtime link. Downstream System 33 owns visible roadside feeder trees, service drops, condition, outages and repair.

## 6. Potable-water planning boundary

00D5 defines the intentionally simple current water contract:

- one stable island municipal-water facility identity hosted by one existing generated real building;
- one lightweight municipal service alias per settlement;
- every alias resolves to the same facility;
- `service_mode = island_wide_municipal`;
- `source_type = treated_municipal`;
- no regional mains, parcel pipe routes, municipal water nodes/segments, pressure zones or service radii.

The municipal facility is intentionally independent of external grid power in the current gameplay contract.

System 33 selects deterministic private wells for **10–20% of generated rural buildings**. Private wells also have no external-grid dependency; a failed well leaves its owning building dry until repaired and does not silently fall back to municipal service.

## 7. Wastewater retirement

Wastewater/sewer/septic is retired. Live global planning, generated-plan validity, System 20 projection, runtime utilities and active CI do not require wastewater topology or compatibility arrays.

## 8. System 20 projection

`System20AreaRequestProjector` is the read-only bridge from global planning to local-area requests.

Current projection includes:

- ordinary road constraints;
- relevant power facts;
- the settlement-facing island-wide municipal-water service alias;
- geography/planning facts needed by current rural-open generation.

It does **not** project hydrology, river/watercourse geometry, bridge intents, municipal pipe geometry or wastewater facts.

## 9. Determinism and failure behavior

The same legal request/profile version/seed must replay the same current global signature. Invalid geography, settlement, road, power or water contracts fail honestly rather than being patched during presentation.

Planning uses stable deterministic domains and semantic IDs, not Godot Node identity, render state or streaming state.

## 10. Performance

Global planning is bounded generation-time work. It introduces no recurring render-frame or simulation-tick work. Startup consumers should reuse the retained structural local-area manifest rather than synchronously regenerating the whole island for each subsystem.

## 11. Verification

The active `global-world-planning` workflow verifies:

- current System 00D source boundaries and physical absence of retired hydrology/bridge/wastewater sources;
- Godot project import/parse;
- current rural global planning, deterministic replay and alternate-seed legality;
- power and simplified municipal-water validation;
- System 20 projection/local generation without retired hydrology seams;
- complete island planning and roughly-six-hundred-building reference density;
- physical absence of retired river/watercourse generator/streaming sources;
- absence of the legacy crossroads seam;
- canonical startup.

Exact terminal verification for the current executable is recorded in `README_CONTEXT.md`.
