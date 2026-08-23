# Changelog

## System 00D Global World Planning — Wastewater / Septic Infrastructure Slice 006 — 2026-08-22

- Implemented the approved **System 00D Wastewater / Septic Infrastructure Slice 006** and bumped `temperate.rural.region` from **v5 to v6**.
- Added focused pure owners `GlobalWastewaterInfrastructurePlanner.gd`, `GlobalWastewaterInfrastructureQuery.gd` and `GlobalWastewaterInfrastructureValidator.gd` under `game/scripts/generation/world/`.
- Extended `GeneratedGlobalWorldPlan`, completeness checks and deterministic signatures with `wastewater_services`, `wastewater_nodes` and `wastewater_segments`.
- Added one wastewater-service record for each current settlement: the small town uses municipal treatment, while the rural crossroads and three hamlets use `decentralized_septic` / `onsite_septic` intent.
- Every rural septic service now carries `potable_source_clearance_required`, preserving the future well/septic safety constraint without inventing parcel-scale tank, drain-field or well coordinates before those local owners exist.
- Added exactly two small-town municipal wastewater planning anchors: `settlement_collection` at the small-town center and `treatment_disposal` at a bounded 64-cell offset on legal major-road geometry inside the small-town planning site.
- Added exactly one `municipal_collection_trunk` with stable source-road/source-route provenance. Wastewater planning runs after potable-water planning, reads the groundwater-source direction, excludes that direction for treatment placement, and rejects positive-length overlap with the potable-water municipal trunk.
- Added independent validation for complete service classification, rural potable-source-clearance policy, exact two-node/one-trunk topology, road/site containment, ridge/boundary discipline, potable-water separation, ID uniqueness and exact collection-to-treatment connectivity.
- Added read-only `System20AreaRequestProjector.wastewater_constraints_for_bounds()`. Candidate 006 exposes only its decentralized-septic intent and receives no fake septic tank, drain field or municipal sewer geometry; the future small-town window already exposes municipal wastewater service plus its two anchors and trunk.
- Preserved `project_site()` exactly. Candidate 006 still receives the same inherited-road request and produces the exact accepted System 20 semantic output; `smalltown.center` remains honestly unsupported until its dedicated System 20 profile is designed.
- Added `GlobalWorldPlanningV6Smoke.gd` and extended the System 00D workflow to prove v6 generation, same-seed replay, alternate-seed legality, potable-water/wastewater separation, all read-only infrastructure seams and Candidate 006 regression through Godot 4.7.1.
- The first integrated Slice 006 code head `d3eaab10a522c371a98b6059846acb34220cac7e` passed `verify/system00d-global-world` (run `32610287488`) plus protected System 19, System 20, System 22 and Pages checks before final documentation promotion.
- No physical sewer pipes, septic tanks, drain fields, manholes, treatment buildings, toilets/drains, sewage flow/backups, contamination/health mechanics, WHAT/WHEN state, streaming, population or outbreak behavior was faked into this slice.
- With potable water and wastewater/septic topology now established, the next default development step is the real System 20 `smalltown.center` local profile rather than another global utility slice.

## System 00D Global World Planning — Potable Water Infrastructure Slice 005 — 2026-08-22

- Implemented the approved **System 00D Potable Water Infrastructure Slice 005** and bumped `temperate.rural.region` from **v4 to v5**.
- Added a mixed rural potable-water service model instead of copying the electrical grid: `settlement.smalltown.001` has municipal groundwater service, while the rural crossroads and three rural hamlets have decentralized groundwater-source intent for later local/private or shared wells.
- Added focused pure owners `GlobalWaterInfrastructurePlanner.gd`, `GlobalWaterInfrastructureQuery.gd` and `GlobalWaterInfrastructureValidator.gd` under `game/scripts/generation/world/`.
- Extended `GeneratedGlobalWorldPlan`, `is_generated()` completeness and deterministic signatures with `water_services`, `water_nodes` and `water_segments`.
- The small-town municipal network records exactly three **planning connection anchors** — `groundwater_source`, `treatment_storage`, `settlement_service` — rather than pretending those cells are final wellhead/tower/waterworks footprints.
- Added profile-bounded source/treatment offsets of 48/24 cells. The municipal source corridor is chosen deterministically from legal major-road geometry incident to the small-town center, stays inside the existing small-town planning site, and prefers a primary-road corridor where available.
- Added exactly two contiguous `municipal_trunk` segments from source -> treatment/storage -> service. Each retains stable source-road/source-route provenance and remains fully contained in real major-road geometry.
- Added independent validation for one service per settlement, exact municipal/decentralized classification, groundwater source type, three municipal node roles, two trunk edges, small-town site containment, road containment, ridge/boundary discipline, ID uniqueness and source-to-service reachability.
- Added read-only `System20AreaRequestProjector.water_constraints_for_bounds()`. Candidate 006 exposes only its `decentralized_source` groundwater service intent; it receives no fake well, municipal nodes or pipe trunk. The future small-town planning window already exposes its municipal service, three anchors and two trunk segments.
- Preserved the existing `project_site()` contract exactly. Candidate 006 still produces the same inherited-road request and exact accepted System 20 semantic output; unsupported `smalltown.center` / `rural.scattered` local profiles still fail honestly.
- Preserved all geography, hydrology, bridge-intent and regional-power regressions. Same-seed replay now includes water identity, and the alternate global seed passes base, power and water validation.
- No tactical wells, pumps, towers, tanks, pipes, building plumbing, pressure/flow, water quantity/quality, drinking/container mechanics, power-to-pump coupling, rain collection, wastewater/sewer/septic, WHAT/WHEN state, streaming, population or outbreak behavior was faked into this slice.
- The first integrated code head `415cca449acb598c517434bfc7b48ba07fb62340` passed `verify/system00d-global-world` (run `32600102767`) and protected Systems 19–22 before final documentation promotion. Final exact-head verification still requires System 00D, Systems 19–22 and Pages all green together.

## System 00D Global World Planning — Regional Electrical Infrastructure Slice 004 — 2026-08-21

- Implemented the approved **System 00D Regional Electrical Infrastructure Slice 004** and bumped `temperate.rural.region` from **v3 to v4**.
- Added focused pure owners `GlobalPowerInfrastructurePlanner.gd`, `GlobalPowerInfrastructureQuery.gd` and `GlobalPowerInfrastructureValidator.gd` under `game/scripts/generation/world/`.
- Extended `GeneratedGlobalWorldPlan` and its deterministic signature with `power_nodes` and `power_segments` while keeping System 00D free of System 19/20 ownership, WHAT mutation, renderer/art, camera/player and streaming dependencies.
- The canonical regional fixture now has exactly one deterministic electrical-grid ingress at a real major-road boundary gateway, one small-town-associated substation, and one settlement-service node for each of the five current settlements.
- Built the regional feeder network from the already connected major-road graph instead of inventing a second cross-country routing truth. Existing road endpoints, intersections, settlement centers and gateways become graph vertices; required ingress-to-service paths are unioned into one connected network.
- Feeder segments retain stable source-road and source-route provenance. Primary road corridors are mildly preferred over secondary corridors when legal alternatives exist, but every feeder segment remains fully contained by actual major-road geometry.
- Ridge avoidance remains inherited from global roads and is independently rechecked by the power validator. Only the selected regional ingress may terminate at the world boundary.
- Added independent validation for one ingress, one small-town substation, complete five-settlement service coverage, valid node locations, unique IDs, road containment, ridge avoidance, boundary discipline, feeder connectivity and ingress reachability.
- Added read-only `System20AreaRequestProjector.power_constraints_for_bounds()`, returning clipped feeder segments and power nodes without changing `AreaGenerationRequest` or silently materializing tactical infrastructure.
- Proved the accepted Candidate 006 `project_site()` request and generated System 20 semantic output remain unchanged. Candidate 006 can expose its global crossroads service/feed facts through the new query, but the playable map still has no new tactical utility poles or wires.
- Same-seed replay now includes stable power identity; alternate seeds retain legal power topology while allowing deterministic variation through regional ingress and existing global geography/road variation.
- Preserved Slice 003 hydrology/bridge projection regressions, adjacent-road continuity, unsupported future local-profile failure, System 20 local generation and canonical startup behavior.
- No energized/de-energized runtime state, outages, transformers, house service drops, tactical utility poles, tactical wire rendering, local building wiring, generators/batteries, electrical hazards, water/sewer, streaming, population or outbreak behavior was faked into this slice.
- Exact-head verification remains `verify/system00d-global-world`; protected Systems 19–22 and Pages deployment remain required on the final head.

## System 00D Global World Planning — Hydrology / Bridge Intent Slice 003 — 2026-08-21

- Implemented the approved **System 00D Hydrology / Rivers + Bridge Intent Slice 003** and bumped `temperate.rural.region` to **v3**.
- Added focused pure owners `GlobalHydrologyPlanner.gd`, `GlobalHydrologyQuery.gd` and `GlobalBridgeIntentPlanner.gd` under `game/scripts/generation/world/`; pure 00D still imports no System 19/20, WHAT mutation, renderer, camera, player or streaming owner.
- Extended `GeneratedGlobalWorldPlan` and deterministic signatures with ordered global `river_segments` plus explicit `bridge_intents`.
- The canonical regional fixture now creates one deterministic **boundary-to-boundary primary river** on the coarse 128-cell geography lattice. Seeded routing chooses a legal west/east side outside the protected central corridor, prefers lower geography and strongly penalizes uphill movement without pretending to simulate fluid dynamics.
- Kept the accepted Candidate 006 center and its immediately adjacent 256×256 windows hydrology-free. The protected central integration corridor remains a hard no-river region.
- Non-central settlement/site placement now requires both legal lowland/rolling geography and a profile-defined river-clearance margin. If bounded snapping cannot satisfy both, global generation fails rather than placing a site across water.
- Major-road routing keeps Slice 002 geography costs, adds a high river-crossing cost, and refuses to follow consecutive river-centerline coarse cells. This favors avoiding water while still permitting topologically necessary crossings.
- Added explicit bridge-intent planning **after** road and river geometry exists. Every real perpendicular route/river/cell crossing produces exactly one intent containing road/route IDs, river/segment IDs, crossing cell, bridge axis and widths.
- Independent `GeneratedGlobalWorldValidator` recomputes the crossings itself and rejects collinear road/river overlap, missing bridge intent, duplicate intent, orphan intent, bad references, incorrect crossing cell/axis/width, disconnected river order or illegal river endpoints.
- Added read-only `System20AreaRequestProjector.hydrology_constraints_for_bounds()`. It exposes clipped river centerlines and bridge intents to future local hydrology work without changing the current `AreaGenerationRequest` or silently materializing water.
- Proved the central global `project_site()` request remains semantically identical to the accepted System 20 Candidate 006 request and still produces the exact accepted local semantic output.
- Added regression that protected center/adjacent windows expose no hydrology while an outer 256×256 window around a canonical bridge exposes both the global river and its bridge intent.
- Same-seed global replay now includes hydrology/bridge identity; alternate seeds vary legal river geometry while retaining geography, settlement, ridge-avoidance, crossing and bridge-intent validity.
- No tactical water surface, swimming, drowning, bridge art/collision/destruction, flooding, utilities, streaming, population or outbreak behavior was faked into this slice.
- Exact-head verification remains `verify/system00d-global-world` and continues to rerun System 20 plus canonical startup regressions.

## System 00D Global World Planning — Geography / Landform Slice 002 — 2026-08-21

- Implemented the approved **System 00D Geography / Landform Slice 002** and bumped `temperate.rural.region` to **v2**.
- Added a deterministic 128-cell coarse geography lattice to the canonical 1792×1792 regional fixture: **14×14 = 196 geography records** covering the complete global planning bounds.
- Added planning elevation `0..100` and semantic `lowland`, `rolling`, `upland`, and `ridge` classes using deterministic mixed-coordinate value noise, bounded detail noise and seeded peak boosts.
- Added `GlobalGeographyPlanner.gd` and read-only `GlobalGeographyQuery.gd`; pure System 00D remains independent of System 20, WHAT, renderer, camera, player and streaming owners.
- Geography now exists **before settlements and major roads**. The central rural-crossroads anchor remains fixed, while non-central smalltown/hamlet anchors use bounded deterministic snapping to legal lowland/rolling geography.
- Reworked outer major-road planning into deterministic four-neighbor geography routing: lowland is cheapest, rolling mildly penalized, upland strongly penalized, and ridge cells are forbidden. Generated named routes remain composed from cardinal global segments.
- Added independent validation that geography fully tiles the world, settlements use legal landform, the major-road network remains connected, boundary gateways exist, and no major-road centerline crosses ridge geography.
- Preserved `road.region.primary.001` and `road.region.secondary.001` as the stable protected central inherited-road IDs used by the Rural Crossroads System 20 fixture.
- During integration, found that the original 384-cell protected half-span allowed the first coarse geography bend to begin inside an immediately adjacent 256×256 local window. Fixed the **global planner**, not the downstream adapter, by extending the protected straight-road half-span to **640 cells**. Geography-aware bends now begin beyond the center, all four adjacent critique windows, and one additional local-area width of safety.
- Kept `System20AreaRequestProjector` strict: zero-length tangent contacts are ignored because no road actually enters the area, while substantial unsupported internal inherited-road geometry still fails honestly.
- Proved the central global site still projects to the current Rural Crossroads inherited-road request; current System 20 Candidate 006 generates successfully from it, and west/east/north/south adjacent windows retain continuous shared primary/secondary road segments.
- Preserved honest failure for future unsupported `smalltown.center` / `rural.scattered` local profiles rather than fabricating local content.
- Slice 002 adds **no hydrology, bridges/tunnels, streaming, population, utilities, tactical elevation or world-map renderer**. Rivers/hydrology remain the next natural design extension rather than a placeholder hidden inside this slice.
- Exact-head verification remains `verify/system00d-global-world`.

## System 20 Rural Crossroads Candidate 006 — Road-Flush Commercial Paved Frontage — 2026-08-21

- Responded to the live critique that the existing gas-station parking/forecourt was separated from the road by an unpaved strip, and generalized the user's rule: **a store with a real parking lot/forecourt frontage should have that pavement meet the road directly**.
- Bumped `rural.crossroads` from v4 to **v5** because same-seed local property-ground output intentionally changed. `temperate.rural` remains v3.
- Preserved Candidate 005 roads, parcel allocation, farms, close facade setbacks, primary-door alignment, straight frontage-normal approaches, fields and mixed-coordinate ecological noise.
- Kept every finalized System 19 prefab source unchanged. There is **no gas-station archetype hardcode** in the new rule.
- `BuildingPlacementPlanner` now reads public generated System 19 ground entries and recognizes `ground.parking*` only when those cells lie on the generated building/property footprint's actual road-facing edge.
- Added standalone `CommercialPavedFrontagePlanner.gd`, which extends each qualifying parking edge straight to the road and uses the **same building-owned parking semantic** for the new apron cells.
- The current gas station therefore extends its existing `ground.parking_faded` forecourt directly to the frontage road.
- Diner, houses and other buildings without a qualifying road-facing parking semantic receive **no invented parking apron**. Candidate 004's earlier rule remains true: empty setback grass is not implicit parking.
- Added real `parking_cells` only for generated paved frontage, reserved those cells from natural obstruction, and included the matching parking ground regions in normal System 20 materialization.
- Expanded `LocalAreaGenerationSmoke.gd` across the critique seed plus twelve consecutive seeds to verify real parking exists where declared, every declared paved frontage reaches road edge continuously, no building without parking frontage gets an apron, and every apron is covered by its building-owned ground semantic.
- No System 19 room/wall/door/archetype source, art asset/catalog, renderer, camera, player movement or door mechanic changed.

## System 00D Global World Planning — Regional Skeleton Slice 001 — 2026-08-20

- Added the user-approved **System 00D Global World Planning** regional-skeleton slice before streaming/population work.
- Added pure global-planning owners under `game/scripts/generation/world/`: stable global sub-seeds, request/plan/profile contracts, settlement planning, major-road planning, broad planning regions, independent validation and a coordinator-only `GlobalWorldPlanner`.
- Added `temperate.rural.region` v1 and `GlobalWorldPlanFixture.gd` with global bounds `Rect2i(232,1232,1792,1792)` and seed `20001`.
- Slice 001 creates five stable settlement anchors: one central rural crossroads, one smalltown and three rural hamlets.
- Added one connected regional road network containing a boundary-to-boundary primary corridor, a boundary-to-boundary secondary corridor and two secondary settlement branches with real regional boundary gateways.
- Added one broad rural-open planning region plus five settlement influence regions. These are semantic planning regions, **not streaming/storage chunks**.
- Added five local-area site records. Future profile hints such as `smalltown.center` and `rural.scattered` remain honest planning intent and are not silently substituted with the existing rural-crossroads profile.
- Added separate `System20AreaRequestProjector.gd`; pure 00D source does not import System 20. The adapter clips global cardinal road segments into the existing `AreaGenerationRequest` contract and preserves global road IDs/classes/widths.
- Preserved the accepted Candidate 005 local area as a hard integration anchor. The central global site projects to the exact existing `area.rural.crossroads.001` bounds, seed, primary/secondary road IDs and local profile/environment selection.
- Proved the projected System 20 request is semantically identical to `RuralCrossroadsPlanFixture.request(20001)` and that System 20 produces the **exact same Candidate 005 semantic plan signature** from the global facts.
- Added adjacent-window road continuity checks: arbitrary west/east/north/south projection windows preserve contiguous cells and the same stable global primary/secondary road IDs across shared boundaries.
- Added honest failure for unsupported future local profiles rather than fabricating small-town or scattered-rural content.
- Added `.github/workflows/global-world-planning.yml` and exact-head status `verify/system00d-global-world`; the workflow also reruns System 20 and canonical startup regressions.
- Updated the exact-head status publisher for System 00D.
- The live Web demo intentionally remains Candidate 005; no fake strategic/world viewer or streaming layer was added merely to make the new pure world plan visible.

## System 20 Rural Crossroads Candidate 005 — 2026-08-20

- Fixed the live property-access critique where some generated approaches reached a building facade and then turned sideways to an off-center front door.
- Bumped `rural.crossroads` from v3 to **v4** because same-seed property-access output intentionally changed. `temperate.rural` remains v3.
- Preserved Candidate 004 roads, local-road frontage, parcel allocation, farm layout, building envelopes, facade setbacks, fields, vegetation and zero-fake-parking behavior.
- Kept every finalized System 19 prefab source unchanged. System 20 still learns the primary entrance only by generating the building through the public contract and reading its `door.exterior.primary` cell from `GeneratedBuildingPlan`.
- After normal legal building placement, System 20 now slides the parcel-side and road-side property-access anchors **along the frontage axis** until they align with the actual generated primary door.
- Final approaches therefore run straight and perpendicular from the road edge to the real primary door instead of making a last-second lateral hook along the facade.
- If a shifted parcel-side access anchor would leave its legal parcel, generation fails rather than restoring a crooked presentation workaround.
- Expanded `LocalAreaGenerationSmoke.gd` so every occupied residential, farmstead and small-commercial approach must begin at its road-access anchor, end at the actual primary door, and remain on one frontage-normal axis.
- The alignment regression runs across the critique seed plus twelve consecutive System 20 seeds while preserving Candidate 004 building counts, local-road majority, setback, road, farm and environmental-noise requirements.
- No renderer/art, camera, movement, door-mechanics or System 19 building source changed.

## System 20 Rural Crossroads Candidate 004 — 2026-08-20

- Responded to the live morphology critique that development still hugged the inherited center road and that buildings were offset too far behind purposeless open space.
- Bumped `rural.crossroads` from v2 to **v3**. `temperate.rural` remains **v3**, preserving Candidate 003's mixed-coordinate 2D vegetation-noise correction unchanged.
- Replaced the single non-frontage farm-access branch with **two internal 3-cell bent gravel `local_rural` roads** extending into opposite portions of the countryside. Both remain local-only, create no area-boundary exit, and join the inherited primary road through ordinary uncontrolled junctions.
- Local rural roads are now real **parcel-frontage authorities**. `ParcelPlanner` can create parcels along usable straight spans of local polylines while keeping safety margins around bends/ends and rejecting overlap with every road corridor.
- Added an explicit local-frontage capacity requirement: if the profile cannot produce enough legal local-road parcels, generation fails rather than silently falling back to lining all occupied properties along inherited roads.
- Preserved the 3-commercial / 6-residential / 4-farmstead / 12-building content target using only the finalized System 19 library.
- Commercial opportunities remain on inherited primary-road frontage near the tiny center. At least **6 of the 10 residential/farmstead properties** now use local-road frontage, including at least 3 residential properties and 3 farmsteads.
- Tightened the actual visible building setback. Regression now measures **road edge -> building facade**, not total driveway length to an off-center primary door. Residential and small-commercial average facade setbacks are <=5 cells; farmsteads remain farther back but <=8 cells.
- Candidate 004 generates **zero parking cells**. Empty grass is not treated as implicit parking; any future parking lot must be explicit physical property geometry/surface.
- Changed driveway routing so access enters the parcel **perpendicular to the frontage road first**, then turns near the building toward the actual generated System 19 primary entry. This removes unnatural shoulder-parallel driveway runs and preserves mailbox frontage.
- Kept the inherited wide-road presentation fix unchanged: plain paved carriageways, one center-path yellow line per inherited road, and unpainted gravel local roads.
- Preserved Candidate 003's tree/shrub/rock noise distribution and anti-diagonal regressions.
- Expanded `LocalAreaGenerationSmoke.gd` across twelve consecutive seeds to lock two local roads, local frontage authority, the 6-of-10 local-road majority, close facade setbacks, zero fake parking, mailbox/field/access integrity, existing prefab coverage and environmental-noise distribution.
- No System 19 building source, renderer/art source, camera source, movement source or door source changed.

## System 20 Rural Crossroads Candidate 003 — 2026-08-20

- Fixed the reported natural-prop **diagonal-line artifact** while preserving Candidate 002 roads, parcels, buildings, camera and renderer behavior.
- Root cause: Candidate 002 selected cluster-center X and Y independently from closely related string-domain seed streams; those deterministic streams were visibly correlated.
- Added `AreaSeed.hash_2d()` / `unit_2d()` so spatial consumers can mix **both coordinates into one deterministic sample** with no preferred axis or diagonal.
- Bumped `temperate.rural` from v2 to **v3** because same-seed ecological output intentionally changed. `rural.crossroads` remains v2 because road/parcel/building morphology is unchanged.
- Replaced finite random cluster centers with a bounded **two-scale 2D value-noise scatter** over eligible countryside cells.
- Low-frequency smooth value noise now modulates local vegetation density, while an independent per-cell coordinate sample decides individual placement. A second broad noise field biases pockets toward trees, brush or rocks.
- Trees/shrubs/rocks still avoid roads, driveway halos, buildings, active fields, occupied parcel interiors and the immediate signalized town center.
- Preserved the Candidate 002 road fix exactly: plain paved carriageways, one center-path yellow line per inherited road, and one bent internal gravel farm-access branch.
- Expanded `LocalAreaGenerationSmoke.gd` with explicit anti-diagonal regressions: broad 4x4 map coverage, bounded local-neighbor ratio and low absolute X/Y spatial correlation across the critique seed and twelve consecutive area seeds.
- System 19, System 21 and System 22 source contracts remain unchanged.

## System 20 Rural Crossroads Candidate 002 — 2026-08-20

- Fixed the live **yellow-box road** problem without changing System 05 or any art asset. Wide paved corridors now materialize as `ground.road_plain`, with a single center-path `ground.road_yellow_line_h` / `ground.road_yellow_line_v` layer instead of asking every cell across a 3–5-cell-wide road to infer generic road topology.
- Centerline paint is withheld through the immediate intersection footprint so the crossroads reads as a crossing rather than overlapping painted boxes.
- Bumped `rural.crossroads` and `temperate.rural` from v1 to **v2** because same-seed morphology/environment output intentionally changed.
- Added one deterministic internal **3-cell gravel farm-access road** with multiple cardinal bends and one uncontrolled junction. The two caller-owned regional roads and their authorized boundary exits remain exact, and the central crossroads remains the only signalized intersection.
- Kept the local farm-access branch from claiming parcel frontage in this candidate, isolating the road-shape test from the already accepted **3 commercial / 6 residential / 4 farmstead / 12-building** layout target.
- Added deterministic clustered natural dressing across wilderness, vacant and otherwise unclaimed rural space using existing recovered art: deciduous trees, dense/thorn shrubs, small/cluster/mossy rocks.
- Natural clusters use bounded seeded placement and avoid roads, driveway halos, building envelopes, active fields and the immediate signalized town center rather than uniformly spraying props across the map.
- Preserved the entire finalized System 19 prefab library, System 21 camera behavior and System 22 moving-window viewer unchanged.
- Expanded `LocalAreaGenerationSmoke.gd` to lock profile/environment v2, the bent local road, boundary safety, physical lane-marking semantics, substantial clustered vegetation, tree/shrub/rock diversity, field clearance, the existing building-density baseline, and twelve consecutive seeds without reroll loops.

## System 20 Materialization + System 22 Live Rural Crossroads — 2026-08-20

- Replaced the isolated Rural Diner live critique fixture with the real **System 20 Rural Crossroads Candidate 001** as the canonical playable Web world.
- Added `AreaMaterializationCoordinator.gd` as the separately owned System 20 initial-write seam. It validates the full area, regenerates/validates all public System 19 subplans, snapshots WHAT + Door State, writes terrain/outdoor props/buildings, initializes doors CLOSED, and rolls back the entire initial transaction on failure.
- Kept System 20 pure planning independently testable; the materializer consumes an already-valid `GeneratedAreaPlan` and does not move planning rules into WHAT/runtime code.
- Added `RuralCrossroadsCritiqueFixture.gd`, which generates/materializes the 256×256 `rural.crossroads + temperate.rural` seed and derives critique collision/traversal registrations from generated public semantics rather than maintaining another authored building list.
- The player now starts one cell outside the **generated diner's actual primary exterior door**, facing it. Existing movement and System 18 automatic door passage immediately operate in the same area world.
- All **12 existing-library buildings** are materialized together in one WHAT world. No new building profile, fake store/barn, survivor population, vehicle, loot or outbreak content was added to make the test look busier.
- Added `LargeAreaRenderWindowController.gd`: the logical area remains 256×256, but the renderer plans/draws an **80×96** moving window at 24 px/cell for mobile performance. Window shifts preserve each global world cell's global pixel position and never alter simulation truth.
- System 21 remains the camera owner. Player-follow, five zoom presets, detached pan, focus/scripted seams and recenter are unchanged; the large-area viewer only updates the renderer's bounded window and presentation transform.
- Fixed the reported **Safari CENTER button** failure. `CameraControls.gd` now activates explicit camera controls directly on touch release, suppresses Safari's immediate synthetic mouse release for 500 ms, and shows camera mode (`FOLLOW`, `INSPECT`, etc.) on CENTER.
- Added deterministic `CameraControls.dispatch_control_event()` so the live button path and CI exercise the same touch/mouse de-duplication contract instead of spoofing Godot GUI signals.
- Removed the old `NEW BUILDING` diner critique button from the canonical live scene; the System 19 DEV seed-cycle owners remain available as System 19 tooling but no longer occupy the live area UI.
- Added `LargeAreaCritiqueRuntimeSmoke.gd` and `.github/workflows/large-area-critique-runtime.yml`, protecting full area materialization, all building doors CLOSED initially, generated-diner entry, System 18 traversal, bounded render-window shifts, world-pixel invariance, detached camera behavior, CENTER follow restoration and Safari touch de-duplication.
- Added exact-head status `verify/system22-area-critique`. Existing System 19, System 20 pure-plan, System 21 camera and Pages gates remain required on the final head.

## System 21 Tactical Camera / View Control — 2026-08-20

- Added the user-approved standalone **System 21 Tactical Camera / View Control** instead of putting camera behavior into System 20, the renderer or player movement.
- Normal gameplay now defaults to `FOLLOW_PLAYER`, centering the active `Camera2D` on the controlled survivor while reading the survivor's real WHAT placement rather than moving the actor to satisfy presentation.
- Added five discrete zoom presets: **Very Close 1.75×, Close 1.35×, Normal 1.00×, Far 0.75× and Area 0.50×**. Normal is the default and all zoom changes stay inside the camera presentation owner.
- Added reusable camera modes for `FOLLOW_PLAYER`, manual `DETACHED` inspection, `FOCUS_CELL`, `FOCUS_ACTOR` and temporary `SCRIPTED` presentation transitions. Focus/scripted calls may remember and restore one prior camera state for future cutscenes/reveals.
- Added `TacticalCameraState.gd`, `ZoomController.gd` and `TacticalCameraController.gd`. The controller reacts only to relevant public WHAT placement changes and advances no simulation ticks.
- Added `CameraInputAdapter.gd`: desktop mouse-wheel zoom, middle-button drag inspection, Home recenter and bracket-key zoom convenience. Right-click remains unclaimed because System 18 reserves it for a future interaction menu.
- Added mobile two-finger centroid pan and pinch-to-discrete-zoom behavior plus explicit phone-friendly `ZOOM - / CENTER / ZOOM +` buttons in `CameraControls.gd`.
- Made `DoorPointerInputAdapter.gd` camera-aware by inverting the active viewport canvas transform before mapping screen coordinates to world cells. Touch door selection resolves on a short release and cancels on drag/multitouch so a camera pinch cannot accidentally become a door action.
- Wired the camera through composition-only `CanonicalDemoMain.gd` and `game/main.tscn`; existing movement, doors, renderer/art, System 19 building generation and System 20 area generation rules remain separate.
- Added `CameraViewControlSmoke.gd` and `.github/workflows/camera-view-control.yml` with exact-head status `verify/system21-camera-view`.

## System 19 Finalization + System 20 Rural Crossroads Candidate 001 — 2026-08-20

- Finalized **System 19 Local Building Generation / Building Grammar** after the user explicitly approved moving on. New building profiles became ordinary content work unless the frozen grammar contract proves insufficient.
- Kept all six current System 19 archetypes unchanged: Trailer v2, Small Farmhouse v2, Large Farmhouse v4, Compact Laundry House v1, Small Gas Station v1 and Rural Diner v2.
- Added the first pure deterministic System 20 local-area/parcel planner, deliberately separate from camera/viewer and persistent WHAT materialization.
- Added `rural.crossroads` v1 and `temperate.rural` v1 as separate settlement/environment profiles.
- Candidate 001 is a **256×256 global-coordinate** area at `Rect2i(1000,2000,256,256)` with one inherited 5-cell primary road and one inherited 3-cell secondary road crossing at `(1128,2128)`.
- Candidate 001 generates exactly one signalized crossroads and zero local road spurs, then creates 3 commercial opportunities, 6 residential parcels, 4 farther farmsteads and remaining agricultural/vacant/wilderness frontage.
- Used only existing building content: one Small Gas Station, one Rural Diner, one intentionally vacant commercial opportunity, plus ten residential/farmstead placements drawn from Trailer, Small Farmhouse, Large Farmhouse and Compact Laundry House.
- System 20 selects buildings only through System 19 placement descriptors, rotates them to true road frontage, validates their System 19 plan, and connects driveways to the actual generated primary exterior door.
- Added semantic grass, roads, gravel driveways, fields, one traffic signal, mailboxes, sparse trees and sparse farm fencing without inventing fake runtime content.
- Added `LocalAreaGenerationSmoke.gd` and `.github/workflows/local-area-generation.yml` with exact-head status `verify/system20-local-area`.

## System 19 Rural Diner v2 + DEV New Building Cycle — 2026-08-20

- The user called the first diner **“very good”** and requested more tables.
- Bumped `commercial.diner.rural_small` from v1 to **v2** because same-seed generated dressing intentionally changed.
- Increased the dining room from four to **six booth/table pairs** while keeping the central aisle and service approaches clear. Total props rose from 26 to **30**.
- Expanded the profile to **four legal back-of-house room orders** across seeds.
- Added explicit DEV-only `BuildingGrammarDevSeedSession.gd` and `BuildingGrammarDevControls.gd` owners; the earlier diner critique scene could cycle to a fresh generated seed without mutating an already-materialized world in place.
- Expanded `BuildingGrammarSmoke.gd` to lock diner v2, all six table/booth clusters, legal seed variation, 32 seeds × four rotations, fixture materialization, System 18 entry and renderer diagnostics.
- Trailer v2, Small Farmhouse v2, Large Farmhouse v4, Compact Laundry House v1 and Small Gas Station v1 remained untouched.

## System 19 Building Grammar Hardening — Trial 001 Rural Diner — 2026-08-20

- Promoted `commercial.gas_station.small` v1 to the protected fifth reference example after user acceptance.
- Extracted reusable shared rules instead of copying exact room dimensions/prop counts: compact purposeful space, meaningful circulation, functional primary entry, reachable required rooms, clear approaches, local functional clustering, contiguous work runs, deliberate open space, bounded blocking density, frontage/orientation correctness and deterministic seeded variation.
- Added `BuildingArchetypePlacementDescriptor.gd` and `LocalBuildingGenerator.placement_descriptor()` as the narrow System 20 placement seam.
- Added reusable grammar owners: `BuildingGrammarProfile.gd`, `BuildingGrammarGenerator.gd`, `BuildingRoomDressingPlanner.gd` and `BuildingGrammarQualityValidator.gd`.
- Added the first shared-grammar proof archetype, `commercial.diner.rural_small`, with compact public dining hub plus kitchen/storage/bathroom, no hallway waste, clustered furniture and deterministic back-room variation.
- Added `BuildingGrammarSmoke.gd` to cover placement descriptors, profile quality, multi-seed/four-rotation generation, materialization, collision/art, System 18 entry and renderer diagnostics.

## System 19 Small Gas Station Candidate 001 — 2026-08-20

- Added `commercial.gas_station.small` v1 as a compact **19×15** roadside property using the existing art/physics contracts.
- Implemented real reachable **storage, office and bathroom**, connected sales floor, rear service exit, storefront entry, pump forecourt and clear customer approach.
- Added purposeful convenience-store, office, bathroom, warehouse and pump-island props with recovered semantic art.
- Registered it as a System 19 archetype and added rotation/frontage/materialization/System 18/render regression coverage.
- No Art Catalog/assets, renderer, movement, door-system, HUD or persistent-world contracts changed.

## Earlier project changelog

The detailed earlier System 19 house iterations and all preceding project history remain preserved in `CHANGELOG_ARCHIVE_THROUGH_2026-08-17.md` and Git history.
