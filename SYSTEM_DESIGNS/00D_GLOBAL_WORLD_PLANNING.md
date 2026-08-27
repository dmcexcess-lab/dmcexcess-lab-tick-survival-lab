# Tick Survival Lab — System 00D Global World Planning

Status: **IMPLEMENTED — rural v6 + complete island v2**

Updated: **2026-08-27**

## 1. Goal

System 00D owns deterministic large-scale semantic world truth before local generation, materialization, population, outbreak simulation or streaming.

Canonical hierarchy:

`world seed -> geography -> hydrology -> settlements/regions -> major roads + bridge intent -> regional infrastructure -> System 20 local areas -> System 19 buildings -> initial WHAT -> persistent runtime mutation`

System 00D is pure planning. It does not materialize WHAT and does not own rendering, tactical movement, local building interiors, streaming partitions or runtime utility state.

## 2. Implemented profiles

### `temperate.rural.region` v6

The mature regional planning profile remains protected and provides:

- deterministic 128-cell geography lattice with lowland/rolling/upland/ridge classes;
- five settlement anchors/sites;
- connected primary/secondary regional road graph;
- one deterministic primary river;
- explicit bridge intent for every real road/river crossing;
- regional electrical planning;
- potable-water planning;
- historical wastewater/septic planning data;
- broad planning regions.

Canonical fixture bounds remain `Rect2i(232,1232,1792,1792)`, seed `20001`.

### `temperate.island.region` v2

The complete-island profile remains an additive composition over the proven rural-v6 world-planning skeleton, but v2 removes the accidental dependency that made the playable island's central 256×256 site regenerate the historical standalone Rural Crossroads critique map.

Island-v2 rules include:

- deterministic `LAND`, `SHORE` and surrounding `OCEAN` truth;
- deterministic coast wobble derived from the world seed;
- regional roads clipped where they would enter ocean;
- bridge intents recomputed from the final physical road/river graph;
- power ingress/feeders adapted to the shoreline-clipped road graph;
- one `island_surface` planning region covering the world bounds;
- the central settlement site **does not reuse the raw world seed**; its local System-20 seed is derived from world seed + site identity like the other island sites;
- island-only settlement spacing is more compact than the protected rural-v6 regional profile, removing the former several-hundred-cell empty band between the mature 256×256 site rectangles;
- the world seed may be projected as an **environmental ecology context** to bounded island settlement materialization so natural land-cover noise remains coherent across logical area ownership boundaries without reseeding roads, parcels or buildings.

The regional `temperate.rural.region` v6 profile retains its historical seed/spacing behavior. Island corrections are profile-specific rather than silent global changes.

Candidate coastline parameters remain:

- ocean margin: 24 cells;
- shore width: 8 cells;
- coast wobble: 8 cells;
- coast scale: 96 cells.

The island keeps five connected settlement identities:

- `area.rural.crossroads.001` -> `rural.crossroads`;
- `area.smalltown.center.001` -> `smalltown.center`;
- three `rural.scattered` hamlet sites.

The IDs and central world location remain stable, but the central area's generated local identity no longer aliases the old seed-20001 standalone critique fixture.

System 20 already contains tested `suburban.neighborhood`, `urban.mixed`, `commercial.corridor`, `industrial.district` and `civic.campus` profiles. Island v2 deliberately does **not** force those profiles into unsuitable global sites merely to demonstrate that they exist. A later global-world profile may place those district types where its own geometry authorizes them.

## 3. Geography / coast truth

`IslandSurfaceMath` classifies cells from authoritative world bounds + seed. Coastline shape is world-generation truth, not a renderer mask and not a technical streaming boundary.

The island remains one logically continuous world. Ocean bounds the playable land naturally instead of using an invisible arbitrary map wall.

The coarse `geography_cells` records retain their normal elevation/landform information and, for the island profile, also expose `surface_kind` for large-scale planning/validation.

Fine physical coastline terrain is produced downstream by the island-surface materialization source; the coarse geography lattice is not treated as tactical shoreline resolution.

## 4. Hydrology and bridges

The existing System 00D primary river remains authoritative hydrology.

Rules remain:

- river routing is global truth;
- settlements require river clearance;
- roads do not silently erase water;
- every authorized road/river crossing has explicit bridge intent;
- a road crossing without bridge intent does not become traversable merely because art draws over it.

For the island profile, bridge intents are recomputed after coastal clipping so bridge truth describes the actual final island road graph.

## 5. Settlements and local-area profiles

System 00D owns **where** settlement/local-area sites exist and which System 20 profile they request. System 20 owns the local morphology.

Island v2 preserves the five proven connected settlement identities while changing island-only composition inputs that were visually exposing the former fixture boundary:

- central local generation uses a derived site seed rather than raw world seed `20001`;
- compact island-only spacing reduces the oversized countryside gap;
- a shared world ecology seed is available to local environmental dressing, while local site seed remains authoritative for site-specific roads/parcels/buildings.

Current System 20 profile library is broader than the first island composition. In particular, all of these already exist and are independently tested:

- `smalltown.center`;
- `suburban.neighborhood`;
- `urban.mixed`;
- `commercial.corridor`;
- `industrial.district`;
- `civic.campus`.

The absence of a profile from island placement is therefore not a missing local generator.

## 6. Roads and connected land

Island regional roads derive from the proven rural regional graph and are clipped to the longest contiguous cross-section that remains off ocean.

Validation requires:

- every retained road cell/cross-section is non-ocean;
- all five settlement centers remain on the connected retained road graph;
- bridge intent remains present where the river crosses a retained road;
- settlement sites remain fully on island land and clear of river corridors.

The local `rural.scattered` road planner uses deterministic finite fallback candidates rather than unbounded rerolls. A legal seed may try alternate lane-side/tail orientations while preserving the same requested road dimensions, inherited-road truth and deterministic output.

## 7. Cross-area ecology context

Natural ecology is cross-region visual/environmental coherence, not technical streaming identity.

For globally projected island settlement sites, System 00D's world seed is passed through the existing 00D -> System-20 projection as an optional inherited ecology seed. This does **not** change the site's own generation seed and does not move local morphology ownership into System 00D.

The downstream natural field is evaluated from:

- authoritative environment vocabulary;
- world seed;
- absolute/global tactical cell.

Therefore splitting the same land into different logical area rectangles cannot restart the ecology phase at each rectangle origin. Technical streaming-region size remains irrelevant to geography and ecology identity.

Standalone System-20 fixtures that do not receive this upstream context keep their historical local request-seed behavior for compatibility.

## 8. Infrastructure boundary

The island retains current regional power/water planning facts so world planning remains coherent.

Power ingress/feeders are adapted to shoreline-clipped roads. Potable-water and historical wastewater/septic records remain planning data.

Roadmap Phase 3 still owns the requested final runtime three-tier Power + Water system. Island generation does not pre-implement energized state, failures, pumps, lines, pressure or repair gameplay.

Standalone wastewater gameplay remains removed from the active roadmap; existing 00D wastewater data is historical/inert planning truth until deliberate cleanup or migration.

## 9. Public plan contract

`GeneratedGlobalWorldPlan` continues to expose:

- world/profile provenance;
- geography cells;
- river segments;
- regions;
- settlements;
- road segments;
- bridge intents;
- power nodes/segments;
- water services/nodes/segments;
- wastewater services/nodes/segments;
- area sites;
- deterministic `signature()` and failure reason.

The island profile uses the same contract rather than creating a parallel world representation.

## 10. Ownership and replacement boundaries

System 00D does not own:

- local road/block/parcel morphology;
- building internals;
- physical WHAT materialization;
- tactical terrain traversal;
- water/coast drawing;
- streaming activation;
- WHEN;
- population/AI/outbreak;
- runtime utility behavior.

Changing streaming-region size may not change island geography, coastline, roads, settlement IDs, natural ecology identity or source identity.

## 11. Verification

`CompleteIslandWorldPlanningSmoke.gd` remains part of `verify/system00d-global-world` and proves the complete island generates through real global/local projection, retains legal connected settlements/roads/hydrology/bridges, and partitions into non-overlapping logical materialization sources.

`IslandLegacySeamSmoke.gd` additionally locks the island-v2 correction:

- central island site does not reuse the legacy fixture seed;
- the generated central-area signature differs from the standalone old 256×256 Rural Crossroads fixture;
- central-to-small-town edge gap stays compact;
- island interior uses the same rural environment vocabulary as settlement sites;
- island surface v3 does not reintroduce `ground.forest_floor` as a rectangular interior palette break;
- globally projected island settlements inherit the world ecology seed;
- the same world-space natural dressing yields the exact same `(cell, semantic)` set whether a probe is generated as one rectangle or split into adjacent logical rectangles.

Verified executable `d33c69d6bd05f4c8fdbba62c6bd51bb16aad26ad` passed all **17 required exact-head contexts**, including `verify/system00d-global-world`, `verify/system00f-streaming-materialization`, `verify/system20-local-area`, `verify/performance-architecture`, and `verify/pages-deploy`.

## 12. North-star fit

The complete island is a bounded implementation of the persistent-open-world North Star: world-spanning geography, roads, river, bridges and coast are decided globally; local places consume those facts; environmental fields that must remain continuous use world identity rather than technical partition origin; streaming only decides what is active/materialized nearby; and persistent WHAT becomes authoritative after virgin creation.
