# Changelog

## System 20C Rural-Open / Countryside Candidate 001 — 2026-08-23

- Implemented the user-approved **System 20C Rural-Open / Countryside Candidate 001** as `rural.open` **v1** while preserving `temperate.rural` v3 and all three existing settlement profiles.
- Added real arbitrary-bounds **dry countryside** planning inside the existing System 00D `rural_open` planning context. Rural-open requests may contain zero or more inherited roads; roadless world space is now structurally valid while Crossroads, Small-Town and Rural-Scattered still explicitly require inherited roads.
- Extended `AreaGenerationRequest` with optional clipped `inherited_geography` records carrying source geography ID/grid, rect, elevation and lowland/rolling/upland/ridge landform. Existing callers default to an empty geography collection.
- Added `RuralOpenLandscapePlanner.gd`. Agricultural `ground.field_green` cover is globally coherent and limited to eligible lowland/rolling cells; upland/ridge receive no fabricated agriculture. Trees/shrubs/rocks use the existing `temperate.rural` semantic families.
- Rural-open landscape decisions use the **global world seed + absolute global cell coordinates**, not request-local coordinates. Natural prop IDs are `rural_open.natural.<x>.<y>`, so changing future logical-source bounds cannot change a prop's persistent physical identity.
- Added `System20AreaRequestProjector.project_rural_open_bounds()`. It rejects settlement-site overlap, preserves exact intersecting regional roads, clips complete System 00D geography, carries intersecting power/water/wastewater corridors as read-only context, and does not invent service/facility geometry.
- Candidate 001 is intentionally dry-land-only. Any bounds containing a real System 00D river or bridge intent fail explicitly with `rural_open_hydrology_not_materializable`; known water is never painted over with fake grass.
- Rural-Open Candidate 001 creates **zero local roads, zero town blocks, zero settlement parcels and zero buildings**. Sparse isolated rural properties remain deferred until System 00F logical countryside-source ownership can guarantee they will not become source-boundary artifacts.
- The existing `LocalRoadPlanner` did not need a redundant rural-open special case: exact inherited-road installation plus zero configured local spurs already satisfies `inherit_only`. The focused rural-open generator path also avoided unnecessary changes to `ParcelPlanner`, `InfrastructureReservationPlanner`, and generic `GeneratedAreaValidator`.
- Added `RuralOpenCountrysideGenerationSmoke.gd` and expanded the System 20 workflow. The smoke dynamically discovers real canonical v6 roadless, roadside, agricultural, upland/ridge and river test windows rather than adding a second authored world truth.
- CI proves exact deterministic replay, roadless/roadside legality, full geography coverage, field/landform legality, global-cell natural IDs, corridor/road/field exclusion, settlement overlap rejection, real river rejection, and **split-vs-combined exact cell-level landscape equivalence**.
- System 00D v6, System 19, System 00F Slice 001, Systems 21/22 and Pages all remained green. The live Web critique still uses Rural Crossroads Candidate 006.
- First fully green integrated code head: `cbc39f03d3568ca4fcbe7f294e350eb1c507bbda`.
- Exact code-head successes: System 00D run `32625507767`, System 00F run `32625507886`, System 19 run `32625507803`, System 20 run `32625507729`, System 21 run `32625507813`, System 22 run `32625507775`, Pages run `32625507820`.
- Recommended next bounded architecture design: **System 00F Slice 002 — stable logical countryside source catalog/materialization**, with source identity independent from technical stream-region coordinates.

## Prior changelog

The complete project changelog through 2026-08-22 is preserved verbatim in `CHANGELOG_ARCHIVE_THROUGH_2026-08-22.md`.

Earlier detailed history through 2026-08-17 also remains in `CHANGELOG_ARCHIVE_THROUGH_2026-08-17.md` and Git history.