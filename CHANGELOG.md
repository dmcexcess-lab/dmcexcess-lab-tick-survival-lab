# Changelog

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
- Kept the inherited wide-road presentation fix unchanged: plain carriageway surfaces, one center-path yellow line per inherited road, and unpainted gravel local roads.
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