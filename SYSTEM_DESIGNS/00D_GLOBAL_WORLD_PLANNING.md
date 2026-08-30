# Tick Survival Lab — System 00D Global World Planning

Status: **IMPLEMENTED — rural v7 + complete island v4**

Updated: **2026-08-30**

## 1. Authority

System 00D owns deterministic large-scale semantic world truth before local generation/materialization/runtime simulation.

Canonical direction:

`world seed -> geography -> hydrology -> settlements/sites -> roads/bridge intent -> regional power + potable water planning -> planning regions -> System 20 local areas -> System 19 buildings -> WHAT materialization -> runtime mutation`

System 00D is pure planning. It does not own runtime utility condition, rendering, player movement, building interiors, streaming activation or simulation clocks.

## 2. Current profiles

### `temperate.rural.region` v7

Current regional planning includes:

- deterministic geography/elevation/landform lattice;
- five settlement/site identities;
- connected major-road graph;
- one deterministic river and explicit bridge intent;
- regional electrical planning/provenance;
- the current island-wide potable-water plant/service contract;
- broad planning regions.

Wastewater/septic is **not** an active planning stage or validity requirement.

### `temperate.island.region` v4

The playable island composes the proven regional owners with island-specific compact settlement spacing, coastline/ocean truth and local-seed/ecology continuity rules.

Current island rules include:

- deterministic `LAND`, `SHORE` and `OCEAN` truth;
- coast geometry derived from world seed rather than renderer masks;
- regional roads clipped away from ocean;
- bridge intents recomputed from final retained road/river geometry;
- compact settlement spacing so the island reads as one continuous place;
- derived site seeds rather than aliasing the old standalone crossroads fixture;
- inherited world ecology seed for cross-area natural-field continuity;
- five connected settlement/local-area identities.

## 3. Geography / hydrology / road invariants

- island surface classification is world-generation truth;
- settlements remain on legal land and respect river-clearance rules;
- roads do not erase water;
- every authorized road/river crossing has explicit bridge intent;
- retained island roads remain connected between settlement centers;
- local-area boundaries do not reset natural ecology phase.

## 4. Power planning boundary

00D4 retains deterministic regional electrical provenance and a stable regional ingress/source identity.

The current playable System-33 composition derives **local substations from actual generated buildings**, targeting about ten buildings per substation. Regional source -> local substation is a logical runtime link and is not materialized as a long-distance transmission wire. Local customer distribution is physicalized downstream by System 33.

Therefore old 00D substation/service coordinates must not be treated as proof that a final tactical substation building or service drop exists at that point.

## 5. Potable-water planning boundary

00D5 now plans one compact near-shore municipal treatment facility and island-wide municipal service:

- one raw-water source node;
- one treatment-plant node;
- one island service anchor;
- two short plant-internal segments;
- one island-wide municipal service record per settlement;
- no service radius;
- no simulated regional/parcel pipe network.

Private rural wells are selected later by System 33 from the real generated rural-home manifest, not predeclared globally.

The municipal plant is intentionally independent of external grid power in the current gameplay contract.

## 6. Wastewater retirement

The former Slice 006 wastewater/septic design is retired. Live `GlobalWorldPlanner` does not invoke wastewater planning/validation, `GeneratedGlobalWorldPlan.is_generated()` does not require wastewater arrays, System 20 does not require wastewater projection, and active CI does not validate wastewater topology.

`00D6_GLOBAL_WASTEWATER_SEPTIC_INFRASTRUCTURE.md` is historical only.

## 7. System 20 projection

`System20AreaRequestProjector` is the read-only bridge from global planning to local-area requests/constraints.

Current utility projection rules:

- power projection exposes relevant planned power facts needed by local planning;
- water projection exposes the settlement's one island-wide municipal service;
- plant nodes/segments are projected only where their physical compact plant geometry intersects the requested bounds;
- local planners must not recreate old municipal-radius or wastewater assumptions.

## 8. Determinism and failure behavior

Same legal request/profile version/seed must replay identical global signatures. Invalid geography, hydrology, road, power or water contracts fail honestly rather than being patched during local generation or presentation.

Planning uses named/stable deterministic domains and stable semantic IDs, not Godot Node identity or render/stream state.

## 9. Performance

Global planning is generation-time work over bounded world-scale collections. It introduces no recurring render-frame or simulation-tick work.

Local runtime utilities may consume these stable facts but must preserve their own event/day-boundary performance contracts.

## 10. Verification

The active `global-world-planning` workflow proves:

- System 00D source boundaries;
- project import/parse;
- profile v7 global planning and island-wide water validation;
- deterministic replay + alternate-seed legality;
- System 20 projection/local generation;
- complete island planning;
- absence of the legacy crossroads seam;
- canonical startup.

Verified executable: `a0299a14d21fb907bdd363ddadb00cc3403b48f1`.
