# Changelog

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
