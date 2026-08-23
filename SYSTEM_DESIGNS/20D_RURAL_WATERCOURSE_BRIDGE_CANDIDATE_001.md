# Tick Survival Lab — System 20D Rural Watercourse / Bridge Candidate 001

Status: **DRAFT**

Design date: 2026-08-23

## 1. Goal

System 20D turns the already-established **System 00D river corridor and bridge intents into deterministic local physical terrain** without allowing local generation or streaming to reroute hydrology.

The core rule is:

> **System 00D decides where the river and road crossing exist; System 20D only materializes those global facts into local semantic terrain.**

Candidate 001 is intentionally narrow. It proves a partition-independent physical watercourse/bridge generation contract first. A later System 00F Slice 003 may attach stable logical river materialization sources to this contract; 20D itself does not redesign streaming/source ownership.

## 2. Current prerequisite truth

This design assumes these implemented contracts remain authoritative:

- System 00D v6 owns global geography, roads, cardinal river segments, declared odd river widths and exact bridge intents;
- every System 00D bridge intent corresponds to one real perpendicular road/river crossing and includes road/river identity, crossing cell, axis and widths;
- `GlobalHydrologyQuery.segment_corridor_rect()` already exposes the exact physical corridor semantics used by current planning and 00F2 exclusion;
- System 20C `rural.open` v1 generates dry countryside from global facts and deliberately rejects any river/bridge intersection;
- System 00F2 catalog v1 gives stable logical ownership to dry countryside while subtracting exact river corridors;
- `AreaMaterializationCoordinator` can transactionally write semantic ground regions from a valid `GeneratedAreaPlan` into WHAT;
- Movement traversal is semantic-terrain policy and fails closed on unclassified terrain;
- WHAT remains the one authoritative current world after materialization.

20D therefore does not need another global hydrology planner, another road planner, or a new persistent-world model.

## 3. Scope

Candidate 001 should implement:

1. a new `rural.watercourse` System 20 profile v1;
2. a public `System20AreaRequestProjector.project_watercourse_bounds()` seam for caller-assigned logical bounds that are wholly physical river corridor;
3. explicit inherited hydrology records on the System 20 request contract;
4. deterministic local river corridor terrain from the exact System 00D declared river geometry;
5. deterministic bridge-deck terrain only where a matching System 00D bridge intent authorizes it;
6. explicit generated hydrology provenance in `GeneratedAreaPlan`;
7. zero local road invention, zero parcels, zero blocks, zero buildings and zero decorative water props;
8. exact split-vs-combined cell-level terrain equivalence across arbitrary accepted watercourse bounds;
9. direct one-time materialization into WHAT through the existing area materializer;
10. a movement-policy proof that water can be non-traversable while bridge road terrain remains ordinarily traversable, without changing Movement internals;
11. preservation of every existing System 20 profile/version/output contract;
12. no System 00F source-catalog or live System 22 presentation change.

## 4. Non-goals

Candidate 001 does **not** implement:

- new river routing, meanders, widths or bridge placement;
- System 00F river source discovery/activation/materialization orchestration;
- a save/backing store or memory eviction;
- water/bridge art or renderer changes;
- swimming, wading, drowning, depth, current or stamina effects;
- flooding, rainfall response, erosion, tributaries, lakes, ponds or wetlands;
- bridge condition, destruction, repair, ownership or construction;
- bridge weight limits or vehicle traversal;
- fishing, aquatic ecology, reeds/cattails or shoreline dressing;
- local road creation, parcels, addresses, properties or buildings;
- population, AI, outbreak or runtime utilities;
- changes to the live Rural Crossroads Candidate 006 critique target.

Candidate 001 makes the river **physically true in generated semantic terrain**, not feature-complete water gameplay.

## 5. Ownership boundary

### System 00D owns

- river ID and segment ID;
- global centerline geometry;
- declared physical river width;
- segment order;
- road geometry;
- bridge intent identity;
- exact crossing cell;
- bridge axis;
- road and river widths at the crossing.

### System 20D owns

- projection of those facts into one caller-bounded local generation request;
- exact local water cells implied by the supplied global corridor;
- exact bridge-deck cells implied by a valid supplied bridge intent;
- local semantic ground output and hydrology provenance;
- validation that no local morphology contradicts global truth.

### WHAT owns

Once a 20D plan is successfully materialized, WHAT owns the current terrain. Generation does not retain authority to reset it.

### System 00F does not change in 20D

System 00F2 continues to exclude river corridor cells. A later separately approved 00F3 design may introduce a stable logical river-source kind that calls 20D.

Technical stream-region geometry never defines river identity or shape.

## 6. New System 20 profile

New profile ID:

`rural.watercourse`

Candidate version:

`1`

Environment remains:

`temperate.rural` **v3**

The new area profile should declare:

- `road_layout = inherit_only`;
- `inherited_roads_required = false`;
- zero local-road spurs;
- zero commercial/residential/farmstead targets;
- empty building archetype pools;
- river ground semantic `ground.water_river`.

The environment profile does not need to bump merely to add this new profile because existing same-seed area outputs do not change. Bridge deck road surface may reuse the existing `temperate.rural` road semantic.

## 7. Request contract revision

`AreaGenerationRequest` gains one optional field:

`inherited_hydrology: Array[Dictionary]`

It defaults empty so all existing callers remain source-compatible.

Only `rural.watercourse` consumes this field in Candidate 001.

### 7.1 River record

A projected river record should contain at minimum:

- `kind = &"river_segment"`;
- `segment_id`;
- `river_id`;
- original global cardinal `start` / `end`;
- odd positive `width`;
- `ordinal`;
- `corridor_rect` — the exact physical corridor rectangle clipped to request bounds.

The original global centerline is retained so the local record can be independently checked against System 00D truth. `corridor_rect` is a projection convenience, not a second hydrology definition.

### 7.2 Bridge record

A projected bridge record should contain at minimum:

- `kind = &"bridge_intent"`;
- bridge `id`;
- `road_id`;
- `route_id`;
- `river_id`;
- `river_segment_id`;
- global crossing `cell`;
- `bridge_axis`;
- odd positive `road_width`;
- odd positive `river_width`;
- `deck_rect` — exact physical bridge-deck geometry clipped to request bounds.

All IDs remain the System 00D IDs. System 20D does not synthesize replacement bridge identity.

## 8. Pure hydrology geometry seam

`GlobalHydrologyQuery` may gain one read-only helper:

`bridge_deck_rect(bridge_intent: Dictionary) -> Rect2i`

Candidate 001 deck geometry is deliberately minimal and deterministic.

For a horizontal bridge axis:

- deck length along X = `river_width`;
- deck thickness along Y = `road_width`.

For a vertical bridge axis:

- deck thickness along X = `road_width`;
- deck length along Y = `river_width`.

The rectangle is centered on the exact global bridge crossing cell.

No arbitrary extra approach/abutment cells are added in Candidate 001. Any later bridge archetype with longer approaches is a new approved content/geometry rule.

This helper changes no System 00D plan data, profile version, signature, routing or bridge placement.

## 9. Projection seam

New public integration method:

`System20AreaRequestProjector.project_watercourse_bounds(plan, area_id, bounds) -> Dictionary`

It should:

1. require a generated System 00D plan, valid area ID and positive bounds wholly inside global bounds;
2. require the broad current rural-open planning context to contain the bounds;
3. reject positive overlap with any settlement `area_site` as a defensive ownership invariant;
4. derive physical river corridor intersections using `GlobalHydrologyQuery.segment_corridor_rect()` rather than merely centerline clipping;
5. require **every request cell** to be covered by the union of real river corridor geometry;
6. project all overlapping river segments needed to explain that physical coverage;
7. project bridge intents by physical `deck_rect` overlap, not only whether the crossing center happens to lie inside the request;
8. project any actual inherited regional road centerline that enters the bounds through the existing road-projection seam;
9. clip inherited geography for provenance/context if the generic request contract continues to require it for this profile;
10. use the global world seed;
11. create `rural.watercourse + temperate.rural` request data;
12. never reroute a river, choose a bridge, widen water, or invent a crossing.

### Why corridor overlap matters

00F3 may later split the physical river corridor into stable logical source rectangles. A fragment can intersect the **edge of a wide river** without containing its centerline. Therefore centerline-only source discovery would create holes and make partition shape affect physical truth.

The projector must reason from the same physical corridor geometry used by 00F2's current exclusion.

## 10. Full-request water coverage rule

Candidate 001 watercourse requests are **water-domain requests**, not mixed dry-land requests.

Every cell in `request.bounds` must be inside at least one real System 00D river corridor rectangle.

If a requested rectangle includes even one unsupported dry cell, projection fails rather than painting that dry cell as water or invoking Rural Open as an implicit second owner.

This gives future 00F3 a simple, provable source contract: river sources can be rectangle fragments of the exact physical corridor, while dry countryside remains owned by existing catalog-v1 `system20_rural_open` sources.

## 11. Local water/bridge planner

New focused owner:

`game/scripts/generation/areas/LocalRiverBridgePlanner.gd`

Responsibilities:

- consume only the validated watercourse request + profile/environment data;
- validate hydrology record coherence;
- derive final local hydrology feature descriptors;
- emit semantic ground regions for water and bridge decks;
- never mutate WHAT;
- never import System 00F, rendering, Movement, player, UI or runtime simulation owners;
- contain no random reroll or morphology selection.

### 11.1 Water ground

Candidate 001 uses:

`ground.water_river`

as the base semantic ground over the complete accepted request bounds.

Because request bounds are guaranteed wholly inside real river corridor geometry, a base full-rect water region is legal and partition-independent.

### 11.2 Bridge deck ground

A matching bridge intent may overwrite water only inside its exact `deck_rect` intersection with request bounds.

Candidate 001 bridge deck ground reuses the existing environment road surface semantic:

`ground.road_plain`

This is intentionally physical/traversal truth, not visual bridge identity. The bridge itself remains explicitly represented in generated hydrology provenance by the global bridge-intent ID.

Only explicit bridge intent authorizes this overwrite. A regional road corridor overlapping water without a corresponding bridge intent must **never** silently become dry road/bridge terrain.

### 11.3 Road centerline paint

Candidate 001 should not require centerline paint to prove bridge physics. If centerline semantics can be derived solely from the matching global road/bridge axis without introducing partial-deck ambiguity, they may be emitted at ordinary higher ground priority. Otherwise Candidate 001 may leave the deck as `ground.road_plain` only.

Bridge traversability must not depend on decorative centerline paint.

## 12. Generated plan contract revision

`GeneratedAreaPlan` gains:

`hydrology_features: Array[Dictionary]`

and includes those features in deterministic plan signatures.

Candidate 001 feature kinds:

- `river_segment`;
- `bridge_intent`.

This provides explicit generated provenance and independent validation instead of abusing infrastructure reservations as finished water geometry.

`AreaMaterializationCoordinator` does not need to interpret this field. Physical terrain is already represented in ordinary semantic `ground_regions`.

`GeneratedAreaPlan.is_generated()` must allow a valid roadless `rural.watercourse` plan, just as `rural.open` may be roadless.

## 13. LocalAreaGenerator branch

`LocalAreaGenerator` should branch to a focused `rural.watercourse` path before the settlement parcel/building pipeline.

A valid Candidate 001 plan contains:

- zero reservations;
- zero local roads;
- zero blocks;
- zero parcels;
- zero building requests;
- zero outdoor props;
- zero or more exact inherited regional roads for provenance only;
- non-empty hydrology features;
- full semantic water ground;
- zero or more bridge-deck ground overlays authorized by bridge intents.

No existing settlement or Rural Open planning code should need semantic rewrites.

## 14. Bridge authorization invariant

For every bridge-deck cell emitted by 20D:

1. one System 00D bridge intent must authorize it;
2. that bridge must reference a projected river segment/river identity;
3. its axis and widths must match the global intent;
4. its crossing must correspond to the global road/river crossing already validated by System 00D;
5. the deck cell must lie inside the physical river corridor and request bounds.

Conversely, any projected bridge-intent deck overlap inside the request must be represented physically.

A road alone is insufficient authorization.

## 15. Split-vs-combined invariance

Candidate 001 must establish the same seam guarantee already proven by Rural Open:

> For the same System 00D global plan, evaluating adjacent accepted watercourse rectangles separately produces the same final semantic terrain at every global cell as evaluating their accepted combined rectangle.

This includes bridge-deck fragments.

Stable physical truth may depend on:

- global plan facts;
- global coordinates;
- profile version.

It may not depend on:

- request-local origin;
- caller area ID;
- 00F technical stream-region coordinates;
- later 00F river-source partition size.

## 16. Materialization boundary

The existing `AreaMaterializationCoordinator` should remain unchanged unless implementation uncovers a genuine generic-plan validation defect.

A valid 20D plan can already be materialized through ordinary ground-region writes:

1. water ground writes into WHAT;
2. higher-priority bridge-deck road ground overwrites the intended water cells;
3. no buildings/doors/props are required;
4. existing WHAT/Door snapshot rollback semantics remain available.

This design does not add a second hydrology state store.

## 17. Traversal semantics

Water is **terrain**, not a fake blocking object.

Candidate 001 does not implement swimming/wading. The existing Movement terrain policy already gives the correct architectural behavior:

- missing/unclassified terrain fails closed;
- `ground.water_river` can be explicitly registered as non-traversable by a composition/test fixture;
- `ground.road_plain` can remain traversable using the existing road rule;
- therefore the bridge deck can be walkable while adjacent water is blocked without modifying MovementActionService.

20D must not import Movement or set runtime movement rules itself.

A future swimming system may add actor capability/policy around water without changing 20D generation geometry.

## 18. Art / presentation boundary

Current recovered Art Catalog has no canonical dedicated river/bridge surface mapping established for this new semantic water terrain.

Candidate 001 therefore makes **semantic physical truth only**.

Do not:

- modify preserved atlases;
- substitute arbitrary blue debug art and call river rendering complete;
- teach generation atlas coordinates;
- switch System 22 to an unfinished river view.

A later explicit art/render slice can map `ground.water_river` and bridge presentation without changing physical generation or source identity.

## 19. Validation / failure behavior

20D fails honestly on:

- invalid global plan/bounds/area ID;
- bounds outside the broad rural-open planning context;
- settlement overlap;
- request cells not fully covered by real physical river corridor;
- malformed/non-cardinal/invalid-width river records;
- malformed/duplicate bridge records;
- bridge identity/river identity mismatch;
- bridge deck geometry inconsistent with the global bridge intent;
- bridge deck outside river/request bounds;
- unauthorized road terrain inside water;
- local road, parcel, block, building or prop creation;
- incomplete/overlapping final terrain coverage;
- generic final-plan validation failure.

No reroll, widening, dry-ground substitution or fake bridge is allowed.

## 20. Expected implementation surface

Expected new files after approval:

- `game/scripts/generation/areas/LocalRiverBridgePlanner.gd`;
- `game/scripts/ci/RuralWatercourseGenerationSmoke.gd`.

Expected narrow edits:

- `game/scripts/generation/areas/AreaProfileCatalog.gd`;
- `game/scripts/generation/areas/AreaGenerationRequest.gd`;
- `game/scripts/generation/areas/GeneratedAreaPlan.gd`;
- `game/scripts/generation/areas/LocalAreaGenerator.gd`;
- `game/scripts/generation/areas/GeneratedAreaValidator.gd`;
- `game/scripts/generation/integration/System20AreaRequestProjector.gd`;
- `game/scripts/generation/world/GlobalHydrologyQuery.gd` — read-only deck geometry helper only;
- `.github/workflows/local-area-generation.yml` — add 20D regression.

Preferred verification remains the existing exact-head context:

`verify/system20-local-area`

No new top-level CI context is needed unless implementation proves a separate owner contract cannot be expressed cleanly there.

## 21. Protected neighbors

Implementation must not change semantics in:

- System 00D v6 planner/profile/generated signature;
- System 00D river routing or bridge-intent generation;
- System 19 building grammar/archetypes;
- `rural.crossroads` v5;
- `smalltown.center` v1;
- `rural.scattered` v1;
- `rural.open` v1;
- `temperate.rural` v3 outputs for existing profiles;
- 00F / 00F2 source catalog, source IDs, registry or streaming behavior;
- WHAT / WHEN foundation contracts;
- collision, movement, doors, inventory, health/needs/carry;
- Art Catalog, renderers, camera, player, input or UI;
- System 22 live Rural Crossroads critique composition.

`project_rural_open_bounds()` must continue to reject river/bridge intersection in Candidate 001. 20D adds a new explicit watercourse path rather than silently broadening Rural Open semantics.

## 22. Acceptance tests

Dedicated Candidate 001 verification should prove at minimum:

1. System 00D v6 canonical signature remains exact;
2. a real canonical river-only physical rectangle can be discovered from the global plan and projected;
3. a real canonical bridge rectangle can be discovered from the global plan and projected;
4. watercourse projection accepts bounds wholly covered by real river corridor;
5. projection rejects a mixed dry/water rectangle rather than painting dry land as water;
6. projected river IDs, widths, ordinals and global geometry match System 00D exactly;
7. projected bridge ID/road/river/axis/width facts match System 00D exactly;
8. `bridge_deck_rect()` is deterministic and centered on the global crossing;
9. a river-only plan contains water ground and no invented road/deck;
10. a bridge plan contains water everywhere except explicit authorized bridge-deck cells;
11. every deck cell is backed by one bridge intent;
12. a road overlap without bridge authorization cannot produce deck ground;
13. watercourse creates no local roads/parcels/blocks/buildings/outdoor props;
14. split-vs-combined accepted river rectangles produce identical cell-level final semantic terrain;
15. split-vs-combined bridge rectangles preserve identical deck cells;
16. exact replay produces identical plan signature;
17. direct existing `AreaMaterializationCoordinator` writes the 20D semantic terrain to WHAT transactionally;
18. direct `MovementTraversalPolicy` can classify `ground.water_river` blocked and existing bridge road ground traversable without changes to Movement source;
19. `project_rural_open_bounds()` still rejects the same river/bridge windows;
20. the 00F2 countryside catalog/source keys remain exact and continue excluding river corridor cells;
21. Crossroads, Small-Town, Rural-Scattered and Rural-Open System 20 smokes remain green;
22. protected 00D/00F/19/21/22 and Pages contexts remain green on the exact implementation and final documentation SHAs;
23. live Web presentation remains Rural Crossroads Candidate 006.

## 23. Performance / mobile requirements

- No per-frame hydrology generation.
- Projection and local planning operate only on bounded caller-requested rectangles and the finite global river/bridge record sets.
- No full-world raster cache is required.
- Split-safe deterministic geometry must be derived from global facts rather than request-local procedural noise.
- Materialization remains synchronous in this slice; do not fake worker/background behavior.
- No WHEN ticks are consumed by generation/materialization.
- Safari/browser lifecycle behavior is unchanged.

## 24. Future extension seams

### System 00F Slice 003 — river logical sources

After 20D is implemented and verified, a separate 00F3 design can give the excluded river corridor stable logical source identity and call this watercourse profile on demand.

Preferred migration direction:

- keep existing `system20_rural_open` catalog-v1 source IDs unchanged;
- add a distinct river/watercourse source kind rather than silently redefining dry-countryside v1;
- derive river source identity from global hydrology facts/global rectangles, never stream-region coordinates;
- preserve 20D split-vs-combined terrain semantics.

### Water gameplay

Swimming, wading, drowning, current, depth and equipment/capability effects should attach through Movement/actor-state policy without moving those mechanics into generation.

### Bridge state

Condition, destruction, repair, collapse, barricades and vehicle weight rules may later require persistent bridge entities/typed state. The System 00D bridge intent ID gives that future state a stable planning identity, but Candidate 001 does not pre-decide the entity representation.

### Presentation

A future water/bridge art slice may map semantic water/deck truth through the Art Catalog/renderers without changing System 20D generation.

## 25. North-star fit

The project promises a globally coherent persistent open world where rivers are real physical constraints rather than decorative lines or streaming-boundary artifacts.

Candidate 001 advances that promise with the smallest causal model that matters now:

- global hydrology remains globally planned;
- local generation makes that plan physically true;
- bridge crossings exist only because a real global road/river crossing authorized them;
- water is an actual semantic terrain obstacle rather than an invisible reservation;
- future streaming can partition/materialize the result without changing what river cells mean;
- future swimming, bridge damage and presentation can attach through their own owners.

## 26. Proposed decisions requiring approval

1. Name this bounded slice **System 20D Rural Watercourse / Bridge Candidate 001** and implement it before any 00F river-source work.
2. Add `rural.watercourse` profile v1 while keeping `temperate.rural` v3 and all existing System 20 profile versions unchanged.
3. Add optional `inherited_hydrology` to `AreaGenerationRequest` rather than overloading reservations or dry-countryside geography.
4. Require watercourse request bounds to be **fully covered by real System 00D river corridor geometry**; mixed dry/water requests fail.
5. Select river facts by physical corridor overlap, not centerline-only overlap.
6. Add pure `GlobalHydrologyQuery.bridge_deck_rect()` geometry using exact road width × river width centered on the global bridge crossing.
7. Only an explicit System 00D bridge intent may overwrite water with bridge-deck road terrain; road overlap alone never creates a bridge.
8. Use semantic `ground.water_river` for water and existing `ground.road_plain` for Candidate 001 bridge deck traversal surface.
9. Add explicit `hydrology_features` provenance to `GeneratedAreaPlan`; the existing area materializer continues to consume ordinary ground regions and should remain unchanged.
10. Treat water as terrain, not a blocking object. Candidate 001 adds no swimming; Movement remains unchanged and can fail closed/block water through its existing terrain policy.
11. Require exact split-vs-combined river/bridge terrain equivalence so a later 00F3 source partition cannot change physical truth.
12. Leave the current 00F2 countryside catalog/source IDs unchanged and keep the river corridor source-free until a separately approved **00F Slice 003**.
13. Do not add water/bridge art or switch the live System 22 view in this slice.
