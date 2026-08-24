# Changelog

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
