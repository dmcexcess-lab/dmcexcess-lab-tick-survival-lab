# Changelog

## System 26 Spatial Sound / Hearing — 2026-08-23

- Implemented approved System 26 Candidate 001 around the rule **“Sound is physical. Hearing is an estimate.”** Exact transient `SoundEmission` truth is separated from listener-specific `HeardSoundObservation` knowledge so player UI and future AI do not receive magical hidden-source coordinates.
- Added `SoundEmissionProfileCatalog.gd` with live walk, Run-stride, normal-door and loud-door acoustic profiles. Candidate acoustic powers are 120 / 200 / 180 / 240 respectively; these are gameplay units, not claimed decibels.
- Added `AcousticMaterialCatalog.gd` and deterministic weighted eight-neighbor `AcousticPropagationQuery.gd`. Cardinal/diagonal travel costs are 10/14, with added attenuation 4 open door, 36 window, 64 closed door, 124 wall and 132 unknown/malformed structure. Strong barriers muffle rather than universally delete sound, and the solver may route around them through a cheaper opening.
- Detailed propagation uses only current materialized WHAT + Door State and refuses to invent unknown/unmaterialized space. Strongly sealed diagonal corners prevent zero-width acoustic leaks.
- Added neutral `HearingProfileProvider.gd`. The current `SurvivorHearingProfileProvider.gd` derives hearing from existing System 13 truth: base 50, Survival +4/level up to +40, fatigue up to -15 and sleep pressure up to -20. No duplicate persistent Perception stat was introduced.
- Added neutral `AcousticEnvironmentModifier.gd` so future weather/background machinery can alter propagation, detection and localization without System 26 importing a Weather owner that does not exist yet.
- Added deterministic heard/not-heard resolution and tiered recognition vocabulary. Current movement/impact examples degrade from specific `FOOTSTEPS` / `THUD` through broad `MOVEMENT` / `IMPACT` to honest `NOISE` rather than fabricated misclassification.
- Implemented the user-requested hard localization sanity contract: uncertainty can broaden bearing/range but cannot flip actor-relative front/rear or left/right signs. A real sound behind-left can be estimated at the wrong distance/bearing within that quadrant but never displayed in front-right space.
- Candidate localization uncertainty trends from about ±60° / ±70% range under poor conditions toward about ±8° / ±10% under strong conditions; near strong sounds collapse to tighter uncertainty. Jitter is deterministic per event/listener and never rerolled by rendering.
- Added `HeardSoundObservationStore.gd` schema v1. Active auditory knowledge ages only by authoritative WHEN ticks, survives auto/hard pause while no ticks pass, and repeated source/category groups refresh one cue instead of leaving a trail of labels. Exact transient emissions are not persisted by this store.
- Replaced the live synthetic auditory crosshair with yellow text in `PerceptionOverlayRenderer`. Yellow words may appear over VISIBLE, REMEMBERED or completely black UNSEEN space without revealing terrain or marking visual exploration. Off-screen words clamp to the viewport edge from the **perceived** location, not the true hidden source.
- Added `ActionSoundEmitterAdapter.gd` using existing truthful public physical events. Successful Walk commits produce footsteps; each successful Run stride produces a louder footstep; `DoorPhysicalTransitionService.transition_resolved` produces normal/loud door sound using its existing noise class. Movement/Door owners remain sound-agnostic and were not modified.
- Integrated System 26 into the live Rural Crossroads composition. The controlled survivor currently receives visible yellow feedback for their own real steps/door transitions; no fake random threat sounds were added merely for demonstration.
- Added `SpatialSoundSmoke.gd`, `.github/workflows/spatial-sound.yml`, and permanent exact-head context `verify/system26-spatial-sound`. Coverage includes material attenuation/routing, stat-dependent hearing, exact-source privacy, directional invariants, deterministic localization, grouping/pause/expiry, snapshot roundtrip, text presentation, WHEN/Movement/Run/Door/Perception regressions and canonical startup.
- The first implementation head exposed one Godot API mistake (`Vector2i.dot()` does not exist in Godot 4.7.1); the exact same localization math was repaired using explicit integer component multiplication before promotion.
- First fully green executable System 26 head: `2d3dcfa6fc8646cda62a5e775beb1ac7c8d04d08`.
- On that exact executable head all eleven required contexts were green: `verify/system26-spatial-sound`, `verify/system25-world-time-light`, `verify/system24-loot`, `verify/system23-perception`, `verify/system22-area-critique`, `verify/system21-camera-view`, `verify/system20-local-area`, `verify/system19-local-building`, `verify/system00f-streaming-materialization`, `verify/system00d-global-world` and `verify/pages-deploy`.
- Candidate common walk-footstep wavefront benchmark on that runner: **13,268.29 µs average across 100 fields**. This passes the <16 ms single-field target but is explicitly retained as a future many-emitter scale seam before large infected/NPC populations are introduced.

## System 25 World Time / Ambient Daylight + Remembered Fog — 2026-08-23

- Added a real System 25 scenario-time interpretation layer downstream of WHEN. WHEN remains integer-tick authority and knows nothing about seconds, hours, days, dawn or night.
- Candidate 001 maps **5 ticks = 1 simulation second**, 300 ticks/minute, 18,000 ticks/hour and 432,000 ticks/day, with the scenario starting at day 0, 08:00:00. The clock is fully derived from `TickKernel.world_tick()` and owns no second advancing counter.
- Added `DaylightProfile.gd` and `OutdoorAmbientLightService.gd` with a smooth temperate baseline: dawn 05:30–07:30, full daylight 07:30–18:30, dusk 18:30–20:30, night level 0.08 and full-day level 1.0.
- Integrated System 25 into the canonical Rural Crossroads composition. Any action that advances WHEN ticks advances derived world time/daylight; normal decision pause and hard pause do not.
- Extended canonical `PerceptionOverlayRenderer` with a normalized ambient-light presentation input. REMEMBERED terrain/structures/static furniture retain 0.30 luminance in full daylight and darken toward 0.10 as ambient light falls. Candidate 001 baseline night produces remembered luminance ~= 0.116.
- `UNSEEN` remains fully opaque black at every ambient level. Ambient changes do not mutate perception memory, poll hidden WHAT, reveal terrain, or alter stale last-seen facts.
- VISIBLE-world global darkness is intentionally deferred until interiors, windows, local/artificial lights, electrical state, flashlights/fire and weather can be modeled physically rather than with a fake global tint.
- Removed the temporary demo-only ambient cycle after System 25 became the single time/daylight authority.
- Added `WorldTimeAmbientSmoke.gd`, `PerceptionAmbientMemorySmoke.gd`, `.github/workflows/world-time-ambient.yml`, and permanent exact-head context `verify/system25-world-time-light`.
- Verification proves tick/time mapping, midnight rollover, hard-pause behavior, WHEN restore determinism, daylight phase/interpolation, System 23 ambient-memory behavior, true-black UNSEEN, WHEN regression, System 23 regression and canonical startup.
- Corrected the System 25 approval record to use the user's actual instruction granting implementation discretion rather than an erroneous generated quote.
- First fully green executable head: `6b6680c5b8eb4d8db2c4097df093abace661d5c7`.
- On that executable head all ten required contexts were green: `verify/system25-world-time-light`, `verify/system24-loot`, `verify/system23-perception`, `verify/system22-area-critique`, `verify/system21-camera-view`, `verify/system20-local-area`, `verify/system19-local-building`, `verify/system00f-streaming-materialization`, `verify/system00d-global-world` and `verify/pages-deploy`.

## System 24 World Loot / Searchable Containers / Scavenging — 2026-08-23

- Implemented approved System 24 Candidate 001: **loot exists before search**. Eligible physical furniture is explicitly enrolled as System 11 containers and receives deterministic stable unplaced `item.*` WHAT entities during one-way virgin source initialization; search never rolls rewards into existence.
- Added the required two-layer item taxonomy: every Candidate 001 definition is top-level `USABLE` or `JUNK`, plus a practical primary family such as food, drink, kitchen, medical, tools, farming, construction, electrical, household, sanitation, office, clothing, outdoors, automotive, industrial, recreational or misc, with optional cross-cutting tags.
- Junk is real persistent weighted item truth rather than decorative/fake filler. Candidate content includes context-appropriate packaging, broken household/tool/farming/electrical/office/sanitation items alongside useful supplies.
- Added `LootItemCatalog.gd` with readable labels, taxonomy and positive integer-gram weights registered through the existing System 13D physical-property catalog.
- Added `LootContainerProfileCatalog.gd` with building-aware classification. The same retail-shelf semantic produces different grocery/pharmacy/hardware/convenience/gas-station stock, while household fridges/pantries/vanities/dressers, medical cabinets, office storage, warehouse racks, tool cabinets and farm storage receive their own profiles.
- Audited the six protected older building archetypes as well as the newer baseline library so rural houses and the gas station are not second-class loot content. Gas-station endcaps/storage pallets and protected-house dressers/vanities are covered explicitly.
- Added `GeneratedBuildingPlan.entity_id_for_role(role)` as the public System 19 generated-role -> materialized-entity identity seam and moved `GeneratedBuildingMaterializer` onto that same helper so System 24 never duplicates a private ID convention.
- Added `LootState.gd` snapshot schema v1. System 24 persists source/container initialization provenance only; **System 11 remains sole current-contents truth**.
- Added deterministic `LootSourceInitializer.gd`: complete source plan/preflight first, then WHAT item creation + System 11 enrollment/containment + System 24 provenance. Already-initialized sources are successful no-ops and never repopulate after looting.
- Added exact rollback across WHAT + System 11 + System 24. `WorldLootSmoke.gd` uses a CI-only fault-injecting containment mutation service to fail on the second item after mutation has already begun and proves all three domains restore byte-equivalent snapshots.
- Added shared physical interaction reach: actor footprint plus one-cell-forward fringe in current facing.
- Added timed `scavenge.search_container` WHEN action. Search is `CANCELABLE`, costs profile-specific time (currently 8/10/12/15-tick classes), revalidates actor/container placement and reach, and reads **current** System 11 contents at completion so concurrent changes are reflected rather than hidden behind a stale request snapshot.
- Extended System 12 additively with neutral `ItemContainerAccessPolicy` and `PolicyAwareItemTransferActionService`. The original `ItemTransferActionService` remains personal-container-only and keeps its historical regressions unchanged.
- Added `LootWorldContainerAccessPolicy` so only initialized, physically reachable world containers are admitted to System 12. TAKE / STORE therefore use the existing timed transfer coordinator, including stale-version checks, cancellation, destination revalidation and compensation.
- Corrected the carry-admission assumption exposed by external containers: external-container -> hand/personal-container transitions can add carried mass and now use the existing System 13E acquisition policy at request/commit, with post-source-removal revalidation on the two-step hand path. Rejected over-hard-limit acquisition moves nothing and spends zero ticks.
- Live Candidate 001 registers **5 ticks** for every System 12 item-transfer action type. Taking, storing, dropping/placing and equipping remain System 12 timing, not a duplicate System 24 clock.
- Added `LootContainerInspectionQuery.gd`, `LootPlayerInteractionController.gd` and phone-first `LootContainerPanel.gd`. A successful search shows container contents with `USABLE/JUNK`, family, label and weight, current/soft/hard carry totals, TAKE controls and direct-pack STORE controls.
- Integrated persistent scavenging into the live Rural Crossroads critique runtime. The deterministic area buildings are loot-initialized after physical materialization; ordinary world/camera controls are blocked while the loot panel is open, but the kernel is not hard-paused so TAKE/STORE actions can spend their real ticks.
- Added `.github/workflows/world-loot.yml` and permanent exact-head context `verify/system24-loot`. The workflow covers taxonomy/context classification, deterministic/no-respawn initialization, legitimate empty sources, snapshot roundtrip, injected mid-transaction rollback, timed search, completion-time live contents, timed external TAKE/STORE, carry ceiling, Systems 11/12/13E/19 regressions and canonical demo startup.
- First fully green executable System 24 head: `411099a3c39b7abeeb189e8a176491cb7e410b6d`.
- On that exact executable head all nine required contexts were green: `verify/system24-loot`, `verify/system23-perception`, `verify/system22-area-critique`, `verify/system21-camera-view`, `verify/system20-local-area`, `verify/system19-local-building`, `verify/system00f-streaming-materialization`, `verify/system00d-global-world` and `verify/pages-deploy`.

## System 23 Remembered Furniture / Clutter — 2026-08-23

- Extended the implemented System 23 REMEMBERED state so previously observed static `prop.*` and `fixture.*` furniture/clutter remains visible as dark stale memory after leaving LOS.
- Environmental memory now records compact last-observed static-object facts: stable entity ID, semantic type, anchor cell and facing. These records are observer knowledge and never poll hidden current WHAT.
- Hidden furniture movement/removal leaves the remembered object unchanged until the cell is re-observed; seeing the cell again refreshes or clears the stale object snapshot.
- `PerceptionOverlayRenderer` redraws remembered furniture/clutter above true-black fog using the same Art Catalog and prop-orientation rules as live prop presentation, while the live Prop renderer remains current-truth only.
- Loose items, vehicles and vegetation remain separate future memory extensions rather than being bundled into this change.
- Bumped deterministic perception-memory snapshots to schema v2 to serialize remembered static props/fixtures. System 23 still does not own save-file orchestration.
- Extended `PerceptionFogMemorySmoke.gd` to prove visible furniture capture, hidden removal remaining stale, re-observation clearing the stale object, remembered-prop presentation planning, deterministic schema-v2 snapshot roundtrip, zero WHEN-tick consumption and the existing FOV performance budget.
- First exact executable head with remembered static furniture/clutter: `a08ccf8064f318e283acab6a3f73aa10e59f2acf`.
- On that executable head all eight exact-head contexts were green: `verify/system00d-global-world`, `verify/system00f-streaming-materialization`, `verify/system19-local-building`, `verify/system20-local-area`, `verify/system21-camera-view`, `verify/system22-area-critique`, `verify/system23-perception` and `verify/pages-deploy`.

## Baseline Building / Area / Environment Profile Library — 2026-08-23

- Expanded finalized System 19 with **18 reusable one-story baseline building profiles**, bringing the callable registry to **24 archetypes total** while preserving the six accepted reference buildings unchanged.
- Added baseline residential profiles for a small suburban house, family suburban house, three-unit townhome row and four-unit one-story multi-unit row. Current city-density content is horizontal: complexity comes from rooms, adjacency and units rather than unimplemented upper floors.
- Added `lodging.motel.roadside` and deliberately did not create a fake multi-story hotel abstraction. Motel guest rooms and horizontal multi-unit homes use real independent exterior entrances; one designated primary exterior door remains the stable System 20 placement/access anchor.
- Added commercial profiles for convenience store, neighborhood grocery, pharmacy, hardware store and small office; civic profiles for clinic, police station, fire station, elementary school and church; industrial/agricultural profiles for small warehouse, workshop and medium barn.
- Added `OneStoryBaselineProfileCatalog.gd` and the shared `OneStoryProfileBuildingGenerator.gd` so the baseline library is profile/content work rather than eighteen copied generator implementations.
- Derived a reusable circulation rule during verification: blocking props do not materialize on any room cell immediately adjacent to a door. This fixed a common `room_connectivity_failed` failure without hand-editing individual floorplans and makes door approaches grammar-owned reserved circulation.
- Expanded System 19 regression coverage to all 18 baseline profiles across all four rotations, deterministic replay, shared structural validation, multi-unit exterior-access rules and art-semantic resolution while retaining the six protected-reference regression checks.
- Added five System 20 settlement morphology profiles: `suburban.neighborhood`, `urban.mixed`, `commercial.corridor`, `industrial.district` and `civic.campus`, all v1 and all owned by the existing System 20 contract rather than new peer systems.
- Added `BaselineGridParcelPlanner.gd` for shared baseline-grid parcel classification across residential, commercial, civic and industrial uses while reusing the established local-town street morphology.
- Fixed the common access contract exposed by the new land uses: occupied civic and industrial parcels now finalize the same real road/frontage-to-generated-primary-entry access path as residential, farmstead and commercial parcels.
- Made baseline building selection **deterministically parcel-fit aware**. The planner scans the ordered profile-authorized System 19 pool for a legal descriptor fit before committing an archetype; it uses no reroll loop and fails honestly if no allowed building fits.
- Added six new environment palettes alongside `temperate.rural` v3: `temperate.suburban`, `temperate.urban`, `temperate.industrial`, `temperate.woodland`, `temperate.coastal` and `temperate.marsh`, all v1.
- Environment palettes are explicitly local vocabulary, not global geography authority. Woodland/coastal/marsh palettes do not authorize System 20 to invent a forest, coast, marsh or other landform not established by System 00D or a future global geography owner.
- Added `BaselineAreaProfilesSmoke.gd` and extended the System 20 workflow to verify all five new morphologies, all seven environment palettes/art semantics, exact target land-use counts, real System 19 building generation/validation and deterministic replay.
- First exact executable head where the expanded System 19 library, baseline System 20 area/environment library and all eight exact-head contexts were green: `2e7a6e0da27a02f8058a3a79538cd9cb55a48cef`.
- On that executable head the successful contexts were `verify/system00d-global-world`, `verify/system00f-streaming-materialization`, `verify/system19-local-building`, `verify/system20-local-area`, `verify/system21-camera-view`, `verify/system22-area-critique`, `verify/system23-perception` and `verify/pages-deploy`.

## System 23 Perception / LOS / Fog Memory — 2026-08-23

- Implemented the approved Candidate 001 perception contract with deterministic four-way facing LOS, a 12-cell range, 120-degree forward cone and radius-1 all-around near awareness.
- Added `VisionProfile.gd`, `VisionQuery.gd`, `PerceptionMemoryStore.gd` and `ObserverPerceptionService.gd` under the focused perception domain. The draft's proposed separate `VisionOcclusionQuery.gd` was not needed; cohesive tracing/opacity logic remains inside `VisionQuery.gd`.
- Walls and CLOSED doors block sight while remaining visible themselves; OPEN doors and windows transmit LOS. Unknown/malformed structure opacity and missing required door truth fail closed rather than granting information.
- Added true three-state observer knowledge: `UNSEEN` is completely black, `REMEMBERED` is dark stale last-observed terrain/structural shell, and `VISIBLE` uses current live world truth.
- Added observer-keyed sparse perception memory with last-observed terrain/structure/door snapshots and stale last-seen living-actor observations. Hidden movement, death, door changes or other live mutations never remotely update remembered visual truth.
- Added `PerceptionOverlayRenderer.gd`. Existing live Ground/Structure/Prop/Actor renderers remain current-truth renderers; the overlay blacks all non-visible cells and redraws only stored remembered snapshots above that mask.
- Preserved the future Spatial Sound seam: synthetic auditory descriptors may render over visible, remembered or completely unexplored black fog without revealing/exploring terrain. System 23 does not fabricate or propagate sound events.
- Perception recomputation is event-driven and consumes zero WHEN ticks. Newly materialized but unobserved world remains true black; technical streaming activation is never treated as exploration.
- Added deterministic memory snapshot/restore coverage and a focused repeated-FOV benchmark requiring average recomputation below one 60 Hz frame-scale budget on the CI fixture.
- Added `PerceptionFogMemorySmoke.gd`, `.github/workflows/perception.yml`, and exact-head context `verify/system23-perception`; integrated perception into the canonical demo composition without moving gameplay truth into rendering.
- Corrected the final contract fixtures for typed memory snapshot handling and collinear closed-door/window LOS targets without changing the implemented LOS rules.
- First fully green executable implementation head after the final LOS fixture correction: `87fb517265ba1defc395068d09ccb7059e16d114`.
- On that exact executable head, `verify/system23-perception` and all seven protected exact-head gates were green: System 00D, 00F, 19, 20, 21, 22 and Pages.
- Documentation promotion is status-only: no executable/config/workflow behavior is changed by the promotion commits.

## Materialization Performance Razor — 2026-08-23

- Implemented the user-approved behavior-preserving performance pass on verified executable head `0b10957bb586162634e9da3c1a4415aef528fd2d`.
- Kept modular ownership intact; profiling/regression evidence pointed to transaction copying and per-cell mutation traffic, not the number of focused systems/classes.
- Added coalesced WHAT terrain mutation records so large rectangular/sparse ground writes advance revision and emit change notification once per semantic batch instead of once per changed cell. Existing single-cell mutation APIs remain unchanged.
- Updated `GroundLayerRenderer` only at its invalidation seam so a relevant bulk terrain change requests one redraw while distant/diagonal-only batches do not spuriously redraw the current view.
- Removed nested full-world snapshots during enclosing materialization transactions: standalone building/area materializers remain independently transactional, while System 20 and System 00F explicitly reuse their enclosing rollback owner through `materialize_in_transaction()` seams.
- System 00F still owns one outer WHAT + Door State + Materialization Registry snapshot for a new-source batch; exact rollback behavior and registry schema v1 are unchanged.
- Added a same-technical-region streaming fast path: the precise focus cell updates, but provider discovery/catalog validation/ensure-materialization work is skipped until the technical focus region actually changes.
- Added `PerformanceRazorSmoke.gd` under the existing System 00F contract to prove 4096-cell coalesced mutation behavior, redraw coalescing, no-op rewrites, standalone/enclosing snapshot ownership, and zero provider/materialization work on same-region movement.
- All seven protected exact-head contexts passed on the executable code head: System 00D, 00F, 19, 20, 21, 22 and Pages.
- On the same GitHub runner class and same multi-scenario 00F regression workloads, settlement materialization improved from ~55.6s to ~13.9s (about **75% faster / 4.0× throughput**) and countryside from ~63.4s to ~10.7s (about **83% faster / 5.9× throughput**). These are CI regression-suite timings, not literal player-facing load latency.
- No area/building morphology, profile versions, deterministic signatures, stable IDs, Materialization Registry schema, WHEN semantics, gameplay rules or live presentation behavior changed.
- Remaining long-horizon scale seam: one outer full-state rollback snapshot and non-evicting WHAT residency still grow with explored world size. Persistence-backed residency/eviction or a write-journal transaction representation remains future work only when separately designed and justified by profiling.

## Architecture / Repository Razor Cleanup — 2026-08-23

- Performed the user-approved one-time architecture/process cleanup before adding another world-generation or streaming slice.
- Kept the core architecture intact: WHERE / WHAT / WHEN, System 00D global planning, System 19 building grammar, System 20 local generation, System 00F materialization/activation, rendering, movement and typed simulation domains remain independent owners.
- Tightened the modularity rule: **replaceability, not file count**. Profiles, candidate numbers, revisions and implementation slices no longer automatically become peer systems/documents/files.
- Merged the duplicated design workflow into `README_SOPS.md` and retired `DESIGN_WORKFLOW.md` as a second active process authority.
- Retired `MODULAR_REBUILD_MASTER_DESIGN.md` from the active tree. Enduring rules now live in the North Star/SOP/current system contracts; obsolete raid/strategic-map assumptions remain recoverable through Git history rather than precedence exceptions.
- Reduced `README_CONTEXT.md` to current-state routing instead of duplicating the System 00D/20/00F manuals, and replaced the stale root README with the current modular/open-world project description.
- Simplified `SYSTEM_DESIGNS/README.md` to the status/routing ledger.
- Consolidated completed System 20 candidate contracts into `20_LOCAL_AREA_PARCEL_GENERATION.md`; removed the active 20A/20B/20C/20D candidate files after preserving their final rules in the owning design and their detailed history in Git/changelog.
- Consolidated System 00F Slice 002 into the 00F umbrella and removed the separate active 00F2 design file.
- Removed the superseded raid-map physical-world design from the active design directory. Its history remains in Git and the persistent-open-world supersession remains recorded in `DESIGN_DECISIONS.md`.
- Removed the frozen `game/scripts/reboot/` runtime after confirming `main.tscn` boots the canonical modular `CanonicalDemoMain.gd` stack. Golden archaeology remains anchored by commit `1763958f44eb7f855fd49944c00d1ffe608c0abe`.
- Removed the older pre-modular root runtime cluster under `game/scripts/` (mini-world/extraction/map-preview/golden tactical generator/presentation/scheduler/perception/weather helpers) and its abandoned smoke tests. These files were recovery sources, not canonical runtime dependencies; their exact blobs remain available from the golden/history commits.
- Removed obsolete top-level architecture notes whose active assumptions had been superseded: reboot/prefab workshop, extraction raid, focused raid interiors, mini-world streetscape, travel-depth gateway, old world-generation/navigation audit, stale extraction-era roadmap and the old First Fire reuse mapping. Current game intent remains in `DESIGN.md`/North Star; implementation history remains in Git/changelog.
- Refactored System 00F coordinators to normalize materialization adapters through one provider collection keyed by `source_kind`, while retaining the existing area-site/countryside convenience constructor/API surface. Future source kinds no longer require another coordinator field/branch.
- Added common provider methods to the existing settlement and countryside source adapters. Existing 00F tests therefore exercise both current source kinds through the generic provider internals.
- Made `GeneratedAreaPlan.is_generated()` profile-neutral. Generic plan existence no longer hardcodes `rural.open` / `rural.watercourse` exceptions; profile-specific content requirements remain the generator/validator's responsibility.
- After deeper inspection, **kept** `System20WatercourseRequestProjection.gd`: it contains cohesive watercourse projection geometry and prevents the already-broad integration projector from growing further. It is documented as an internal helper, not a peer system.
- Simplified Pages deployment to validate/export the canonical modular runtime instead of carrying reboot-era regression obligations. Dedicated subsystem workflows remain responsible for subsystem contracts.
- Updated System 20 / 00F workflows so CI follows the consolidated canonical design files rather than deleted candidate/slice docs.
- New SOP policy: full exact-head regression remains mandatory for executable/config/workflow changes; later documentation-only status/changelog closure may rely on the already-green code SHA plus lightweight consistency checks instead of rerunning every expensive Godot suite.
- Stale `work/*` branches were audited, but branch-ref deletion is not exposed by the connected GitHub tool and therefore is not falsely claimed as completed.
- No new gameplay, morphology, streaming source kind, renderer behavior or live presentation was added in this cleanup.

## System 20D Rural Watercourse / Bridge — 2026-08-23

- Implemented `rural.watercourse` v1 on clean code head `1ef3bd08e9d1a4ef258a2013c3af133ce6605002` before the razor cleanup.
- System 00D remains authoritative for river route/width and bridge intent; System 20 only projects/materializes those facts into semantic local terrain.
- Added physical `ground.water_river` and bridge-deck `ground.road_plain` terrain, with bridge overwrite permitted only by a matching real System 00D bridge intent.
- Added explicit inherited hydrology request facts and generated hydrology provenance, plus exact split-vs-combined terrain invariance.
- Watercourse generation creates no local roads/parcels/blocks/buildings/decorative water props and does not add 00F river-source ownership.
- The first clean 20D code head passed the complete protected seven-context stack: System 00D, 00F, 19, 20, 21, 22 and Pages.

## System 00F Slice 002 — Countryside Logical Source Materialization — 2026-08-23

- Implemented catalog-v1 stable dry-countryside logical sources derived from System 00D geography parent identity + final dry global rectangle, independent from technical stream-region coordinates.
- Exact settlement area-site and river-corridor rectangles are subtracted; dry land adjacent to rivers remains source-owned.
- Added countryside materialization through the existing public System 20C pipeline and atomic mixed settlement+countryside commits in the shared Materialization Registry schema v1.
- Revisit tests prove persistent player/world mutations are not regenerated; deliberate mixed-source ID collision tests prove exact WHAT/Door/registry rollback.
- First green implementation code head: `abe3d56792b74d5dd08882bd4f06dbd76107f35d`.

## System 20C Rural-Open / Countryside — 2026-08-23

- Implemented `rural.open` v1 arbitrary dry-countryside generation while preserving `temperate.rural` v3.
- Allows roadless or roadside global countryside, consumes global geography/infrastructure context, creates no local settlement roads/parcels/buildings, and fails honestly on real hydrology.
- Agricultural/natural decisions use global world seed + absolute coordinates and are split-vs-combined invariant.
- First green integrated code head: `cbc39f03d3568ca4fcbe7f294e350eb1c507bbda`.

## Prior changelog

Detailed project history through 2026-08-22 remains in `CHANGELOG_ARCHIVE_THROUGH_2026-08-22.md`.

Earlier 2026-08-16/17 detail that is not duplicated by the 2026-08-22 archive remains in `CHANGELOG_ARCHIVE_THROUGH_2026-08-17.md`.
