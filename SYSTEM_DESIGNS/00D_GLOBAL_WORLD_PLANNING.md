# Tick Survival Lab — System 00D Global World Planning

Status: **IMPLEMENTED — rural v6 + complete island v1**

Updated: **2026-08-24**

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

### `temperate.island.region` v1

The complete-island profile is an additive composition over the proven rural v6 skeleton.

It preserves the accepted settlement/road/hydrology identities while adding deterministic island-surface truth:

- `LAND` interior;
- `SHORE` transition band;
- surrounding `OCEAN`;
- deterministic coast wobble derived from world seed;
- regional roads clipped where they would enter ocean;
- bridge intents recomputed from the resulting physical road/river graph;
- power ingress/feeders adapted to the shoreline-clipped road graph;
- one `island_surface` planning region covering the world bounds.

Candidate v1 surface parameters are:

- ocean margin: 24 cells;
- shore width: 8 cells;
- coast wobble: 8 cells;
- coast scale: 96 cells.

The mature five-site settlement graph remains the first complete island's settlement set:

- `area.rural.crossroads.001` -> `rural.crossroads`;
- `area.smalltown.center.001` -> `smalltown.center`;
- three `rural.scattered` hamlet sites.

System 20 already contains tested `suburban.neighborhood`, `urban.mixed`, `commercial.corridor`, `industrial.district` and `civic.campus` profiles. Island v1 deliberately does **not** force those profiles into unsuitable global sites merely to demonstrate that they exist. A later global-world profile may place those district types where its own geometry authorizes them.

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

The first island keeps the five proven connected settlement sites so the complete-world milestone does not destabilize accepted town access/road/infrastructure geometry.

Current System 20 profile library is broader than the first island composition. In particular, all of these already exist and are independently tested:

- `smalltown.center`;
- `suburban.neighborhood`;
- `urban.mixed`;
- `commercial.corridor`;
- `industrial.district`;
- `civic.campus`.

The absence of a profile from island-v1 placement is therefore not a missing local generator.

## 6. Roads and connected land

Island-v1 regional roads derive from the proven rural regional graph and are clipped to the longest contiguous cross-section that remains off ocean.

Validation requires:

- every retained road cell/cross-section is non-ocean;
- all five settlement centers remain on the connected retained road graph;
- bridge intent remains present where the river crosses a retained road;
- settlement sites remain fully on island land and clear of river corridors.

This produces a bounded island whose ordinary land settlements remain reachable by the existing movement/road network while ocean and river water remain physical barriers except at bridge decks.

## 7. Infrastructure boundary

The island retains current regional power/water planning facts so world planning remains coherent.

Power ingress/feeders are adapted to shoreline-clipped roads. Potable-water and historical wastewater/septic records remain planning data.

Roadmap Phase 3 still owns the requested final runtime three-tier Power + Water system. Island generation does not pre-implement energized state, failures, pumps, lines, pressure or repair gameplay.

Standalone wastewater gameplay remains removed from the active roadmap; existing 00D wastewater data is historical/inert planning truth until deliberate cleanup or migration.

## 8. Public plan contract

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

## 9. Ownership and replacement boundaries

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

Changing streaming-region size may not change island geography, coastline, roads, settlement IDs or source identity.

## 10. Verification

`CompleteIslandWorldPlanningSmoke.gd` is part of `verify/system00d-global-world` and proves:

- `temperate.island.region` generates deterministically;
- the mature five settlement sites remain legal/connected;
- real `smalltown.center`, `suburban.neighborhood` and `urban.mixed` System 20 profiles exist;
- every globally placed island site projects and generates through real System 20;
- river and bridge intents remain present;
- island-surface, watercourse and area-site source rectangles form a non-overlapping complete sampled partition;
- sampled island surface contains LAND, SHORE and OCEAN;
- the land interior remains substantially larger than ocean in Candidate v1.

The clean generator checkpoint `41b243501acffa480ddde61b498d743a4e4e1d97` passed all 13 required exact-head contexts including Pages.

The canonical playable island composition head `3f1a98c3daea879cf7ffdbea717d88461e39438f` also passed all 13 exact-head contexts including Pages.

## 11. North-star fit

The complete island is a bounded implementation of the persistent-open-world North Star: world-spanning geography, roads, river, bridges and coast are decided globally; local places consume those facts; streaming only decides what is active/materialized nearby; and persistent WHAT becomes authoritative after virgin creation.
