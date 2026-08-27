# Tick Survival Lab — System 20 Local Area Generation

Status: **IMPLEMENTED — ten area profiles / seven environment palettes + live island watercourse use + island-surface continuity v2**

Updated: **2026-08-27**

## 1. Core rule

> **System 00D decides large-scale world truth; System 20 preserves that truth while adding profile-authorized local physical detail.**

System 20 turns bounded global planning facts into deterministic local physical area plans. It owns local roads/blocks/parcels/access/property dressing where the selected profile authorizes them, but it never owns global geography, regional road routing, river routing, streaming identity, rendering or building interiors.

## 2. Current profile library

### Area profiles

- `rural.crossroads` v5;
- `smalltown.center` v1;
- `rural.scattered` v1;
- `rural.open` v1;
- `rural.watercourse` v1;
- `suburban.neighborhood` v1;
- `urban.mixed` v1;
- `commercial.corridor` v1;
- `industrial.district` v1;
- `civic.campus` v1.

### Environment palettes

- `temperate.rural` v3;
- `temperate.suburban` v1;
- `temperate.urban` v1;
- `temperate.industrial` v1;
- `temperate.woodland` v1;
- `temperate.coastal` v1;
- `temperate.marsh` v1.

The small-town, suburban and urban/city-style local profiles are therefore already implemented content. A global world profile may choose among them only where its own site geometry supports them.

## 3. Ownership

System 20 owns:

- interpretation of local area requests;
- inherited-road installation inside local bounds;
- profile-authorized local roads;
- infrastructure reservations used to protect planning space;
- blocks/parcels/land use where applicable;
- deterministic System 19 building selection from legal fits;
- real frontage-to-primary-entry access;
- parking/driveway integration;
- environmental/property dressing;
- dry rural-open generation;
- physical river/bridge terrain from upstream hydrology;
- deterministic generated-area validation.

System 20 reads System 00D/19/WHERE contracts but does not own:

- global world shape/roads/hydrology;
- WHAT after materialization;
- WHEN;
- 00F source identity/activation;
- art/rendering/camera/UI;
- population/AI/outbreak;
- runtime utilities;
- swimming/wading/flood simulation.

## 4. Settlement pipeline

Settlement-style profiles use the common deterministic pipeline:

1. validate request/profile;
2. reserve inherited infrastructure where relevant;
3. install inherited roads exactly;
4. add profile-authorized local roads;
5. derive intersections/blocks/parcels;
6. classify land use;
7. filter System 19 archetypes to physical parcel fits;
8. generate/validate the chosen building;
9. align access to the actual primary exterior door;
10. emit parking/driveway extensions only where physically supported;
11. add profile/environment dressing;
12. validate the completed area.

No unbounded reroll or building clipping is permitted.

## 5. Protected rural profiles

### `rural.crossroads` v5

The live historical reference retains the regional road crossing, two gravel local roads, gas station/diner opportunities, residential/farm frontage, real entry approaches and majority unbuilt rural land.

### `smalltown.center` v1

The island's real small-town site uses this profile. It consumes inherited roads and regional infrastructure planning facts, adds paved local-town streets, creates compact commercial/residential opportunities and protects real access to generated entries.

### `rural.scattered` v1

The three current island hamlets use this profile: sparse residential/farm occupation, two gravel local lanes, no fake commercial center and high unbuilt-land fraction.

## 6. `rural.open` v1

Arbitrary dry countryside inside the rural planning context.

Rules include:

- no positive overlap with settlement sites or physical river corridor;
- globally coherent inherited road clipping;
- no local settlement road/parcels/buildings;
- geography-aware agricultural/natural dressing;
- stable global-cell natural prop identity;
- split-vs-combined accepted bounds produce the same cell-level result.

This remains used by the protected rural-region 00F countryside path.

## 7. `rural.watercourse` v1

Physical river/bridge terrain from System 00D hydrology.

Rules:

- request bounds are covered by real physical river-corridor geometry;
- river ground is `ground.water_river`;
- water is not traversable by ordinary movement;
- only a matching explicit System 00D bridge intent may overwrite river water with bridge-deck road terrain;
- bridge deck currently uses `ground.road_plain`, so ordinary movement can traverse the authorized crossing;
- a road crossing water without bridge intent never becomes a bridge;
- no buildings/parcels/fake decorative water are invented;
- split-vs-combined accepted watercourse bounds are deterministic.

This profile is now consumed **live** by System 00F `WatercourseMaterializationSource` in the complete island. The former “river source deferred” boundary is superseded.

## 8. Baseline settlement/district library

### `suburban.neighborhood` v1

Recommended palette `temperate.suburban`. Uses the established paved-grid morphology with small commercial, residential, horizontal townhome and civic opportunities.

### `urban.mixed` v1

Recommended palette `temperate.urban`. Uses denser one-story townhome/multi-unit rows plus small commercial/civic opportunities; no fake upper floors.

### `commercial.corridor` v1

Roadside commercial emphasis including motel, grocery, hardware, pharmacy, convenience and office archetypes, with parcel-fit filtering before placement.

### `industrial.district` v1

Warehouse/workshop emphasis with the same real frontage-to-primary-entry access invariant as every occupied property.

### `civic.campus` v1

School/fire/police/clinic/church emphasis with real finalized approaches.

These profiles are callable and tested independently. The first complete island deliberately uses only globally authorized sites from its proven settlement graph; not every available local profile must appear in every global-world profile.

## 9. Complete-island surface integration

Fine coastline/ocean generation is a focused extension alongside normal System 20 profile generation:

- `IslandSurfaceRequestProjection` derives bounded requests from the System 00D island plan;
- `IslandSurfaceAreaGenerator` v2 emits ordinary island land, shore transitions, ocean and authorized inherited roads for non-settlement/non-river source bounds;
- ordinary LAND is no longer an intentionally blank grass sheet: broad globally anchored land-cover variation and deterministic temperate-coastal natural dressing give the between-site countryside physical texture while preserving source-split invariance;
- island-surface natural prop identity is anchored to global cell coordinates and maintains a clearance halo around real road corridors;
- inherited painted regional roads retain both their road surface and centerline presentation when they leave a settlement rectangle, so a logical road does not visually disappear at the System-20/00F handoff;
- settlement sites continue through normal System 20 area profiles;
- river corridors continue through `rural.watercourse`;
- the logical source partition remains non-overlapping: this revision adds local physical detail inside the existing ownership partition rather than hiding seams with overlapping sources.

This keeps the coastline globally determined while allowing 00F to materialize the bounded world through ordinary deterministic local plans.

## 10. Materialization boundary

`AreaMaterializationCoordinator` writes valid generated areas into WHAT + Door State through existing mutation contracts.

Generation relinquishes authority after successful materialization. Revisiting may not regenerate/reset current world truth.

Ground writes remain coalesced for materialization performance.

## 11. Water/coast presentation boundary

System 20 emits semantic terrain only. It does not own art.

The complete-island presentation uses an additive `WaterCoastArtCatalog` + `water_coast_atlas.svg` for:

- ocean;
- river water;
- sand/shore;
- cardinal/corner/T/all-around shoreline transition variants.

`GroundLayerRenderer` resolves those dedicated water/coast semantics before falling back to the existing recovered Art Catalog. Art does not decide traversal.

## 12. Verification

`verify/system20-local-area` continues to cover all ten area profiles and seven environment palettes, deterministic replay, real System 19 fit/access invariants, rural-open invariance and rural-watercourse bridge authorization.

`verify/system00d-global-world` additionally runs every globally placed complete-island area site through the real projector + System 20 generator. Its complete-island smoke now also proves that the playable spawn is not the diner entrance, ordinary island LAND receives real deterministic natural dressing, natural dressing avoids road cells, and painted inherited road centerlines survive island-surface materialization.

Playable-island continuity executable `505535ea7fab555f7a1871afb9f2d1e2ff92331b` passed all **17 required exact-head contexts**, including `verify/system00d-global-world`, `verify/system20-local-area`, `verify/system00f-streaming-materialization`, `verify/performance-architecture`, and `verify/pages-deploy`.

## 13. Replacement boundaries

A System 20 rewrite must not require changes to System 00D world identity/routing, System 19 internals, WHAT/WHEN, renderer/art, player/input/UI or technical streaming geometry. Likewise, changing technical stream-region size must not change a System 20 plan for the same logical request.
