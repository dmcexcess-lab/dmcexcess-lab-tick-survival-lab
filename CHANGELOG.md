# Changelog

## WHERE / WHAT / WHEN Simulation Foundation Design — 2026-08-16

- Added `SYSTEM_DESIGNS/00_FOUNDATION_WHERE_WHAT_WHEN.md` as the thorough DRAFT architecture for the three peer simulation foundations beneath generation/rendering: **WHERE (Spatial Model), WHAT (Persistent World / Entity State), and WHEN (Tick / Action / Pause Kernel)**.
- Defined WHERE around one global integer tactical-grid coordinate language, N/E/S/W directions, arbitrary whole-cell footprints, deterministic footprint rotation, layered occupancy concepts and structure/opening geometry. The document recommends structure cells with explicit axis rather than cell-edge walls for simplicity/recovered-art compatibility, but that recommendation remains DRAFT until explicitly approved.
- Defined WHAT as durable world truth independent of procedural generators, Godot Nodes, renderers and streaming partitions. Proposed stable opaque entity IDs, semantic world types, explicit stores/mutation paths, derived occupancy indexes, generated-initial-state versus current-persistent-state separation, and ordinary persistent physical state as the basis for player-built bases anywhere.
- Defined WHEN as one integer world-tick/action/event kernel for player actions, other actors and future scheduled systems. Preserved useful golden `TickScheduler.gd` concepts—explicit costs, deterministic ordering, phases, committed/resumable/cancelable interruption, resumable snapshots and player-ready auto-pause—while generalizing beyond a player-centric actor list to a deterministic scheduled-event queue.
- Separated normal tactical auto-pause from **hard real-life application pause**. Hard pause advances zero simulation ticks and must preserve in-progress action state across work/customer/browser/mobile interruptions.
- Designed one world tick to support both detailed nearby actions and coarse distant population/outbreak events, allowing causal open-world simulation without executing every invisible footstep.
- Added explicit cross-system examples for movement, doors, simplified serious injuries, construction/base building, global world generation and outbreak simulation, plus compatibility checks for rendering, vision, lighting, weather, silent spatial sound, inventory, AI, vehicles, construction and streaming.
- Added shared determinism/performance rules: integer coordinates/ticks, stable IDs, deterministic event tie-breaking, named/sub-seeded RNG streams, event-driven world-change notifications, no full-world per-tick scans, no permanent Node per persistent object, visible/detail simulation only where relevant.
- Recorded the **WHERE / WHAT / WHEN decomposition as settled in concept** in `DESIGN_DECISIONS.md`; the detailed umbrella remains DRAFT and does not authorize code.
- Updated `SYSTEM_DESIGNS/README.md` so 00A/00B/00C point to the umbrella draft and explicitly require bounded subsystem approval before implementation. Generation remains downstream as a producer of initial WHAT using WHERE.
- Updated `README_CONTEXT.md` so the current task is review of the foundation draft before any new runtime code, and corrected `DESIGN_WORKFLOW.md` to remove the last stale extraction-style gameplay language from current project philosophy.
- No gameplay/runtime code changed. The deployed Web build remains the frozen/deprecated clean-reboot reference.

## Project North Star / Persistent-World Anti-Drift Reset — 2026-08-16

- Added `PROJECT_NORTH_STAR.md` as the short canonical game-identity document future work must reread before local subsystem design. Primary shorthand is now **“Ultima-style turn-based mini Zomboid.”**
- Added the project principle **“Mini means reduced complexity, not reduced consequence or mood.”** Survival systems should preserve meaningful decisions, causality, danger and atmosphere without reproducing unnecessary internal simulation variables.
- Updated the human `README.md` around the current persistent-open-world direction, turn-based variable-duration action model, real-life hard-pause requirement, invisible tactical grid, simplified-but-consequential health philosophy, extraction-style expedition risk, physical base, outbreak simulation and customizable player stories.
- Added `DESIGN_DECISIONS.md` as an append/supersede cross-system decision log so later work can recover why a foundational direction was chosen instead of inferring intent from whichever code happens to exist.
- Explicitly superseded the earlier disconnected **static strategic map -> generated raid -> extraction** world model as the long-term physical foundation. Extraction-shooter influence now means risk/reward expeditions inside a logically continuous persistent world; internal streaming/storage partitions are implementation details rather than separate realities.
- Recorded the global-world-planning rule: roads, utilities, parcels and other cross-region structures are planned in global coordinates before local materialization so independently loaded chunks cannot invent incompatible seams.
- Recorded the long-term causal outbreak goal: pre-collapse people/households/jobs/homes/schedules can be simulated through collapse, with coarse deterministic distant simulation permitted for performance as long as persistent causal state is preserved.
- Recorded the Player Story direction: the player eventually customizes/inhabits a real person embedded in the generated world, including home, occupation/workplace, household/family, relationships, pets/vehicle/resources and outbreak-start circumstances where appropriate.
- Recorded the base direction: a base is fundamentally a real physical world location, with higher-level UI only summarizing underlying storage/workspaces/power/water/vehicles/residents/etc.
- Recorded the current spatial baseline: authoritative **invisible tactical grid**, cell-to-cell actors, whole-cell object footprints and semantic N/E/S/W orientation. Renderer owns whether clutter/furniture uses 90-degree rotation or explicit alternate-facing art. Wall/door/window cell-vs-edge representation remains deliberately unresolved for Spatial Model design.
- Recorded the hard interruption-safety rule: real-life work/customer interruptions must freeze simulation safely and must never count as a tactical mistake.
- Rewrote `README_CONTEXT.md` as an accurate routing index for the current open-world direction and moved the foundational design order below map generation/rendering: Spatial Model -> Tick/Action/Pause -> Persistent World -> Population/Outbreak/Player Story -> generalized local-world contract.
- Reordered `SYSTEM_DESIGNS/README.md` accordingly and marked the old raid-specific `RaidMapSpec` draft **SUPERSEDED** rather than silently adapting it to a different world architecture.
- Strengthened `DESIGN_WORKFLOW.md` and `README_SOPS.md` with a mandatory North-Star drift check, cross-system decision logging, future-seam review, and the rule that chat must not outrun durable repository memory when the game direction materially changes.
- Added CI guards requiring the North Star and decision log to remain present and checking the current core identity/open-world design statements while the deprecated reference runtime continues to build unchanged.
- No new modular runtime/gameplay code was implemented in this pass; the deployed Web build remains the frozen clean-reboot reference.

## Design-First Modular Workflow / System Approval Ledger — 2026-08-16

- Added `DESIGN_WORKFLOW.md` as the mandatory project process: **DESCRIBE -> APPROVE -> IMPLEMENT -> VERIFY** for every major new subsystem or rewrite.
- Added an explicit scope gate requiring GPT to push back before coding when a prompt spans multiple major systems, break the work into dependency-ordered pieces, recommend the first bounded system, and obtain approval before implementation.
- Added a strict no-placeholder/no-fake-completion rule. Missing prerequisite systems must be designed first or explicitly deferred rather than replaced with temporary mechanics that silently become architecture.
- Added targeted clarification rules for genuinely ambiguous historical references, destructive scope, module ownership, stable contract changes, Safari/mobile interaction, timing, persistence and player-visible semantics. Ordinary spelling/typos do not require clarification when intent is clear.
- Recast `README_CONTEXT.md` as a concise routing/current-state index rather than the encyclopedia of every subsystem. Detailed canonical system memory now belongs under `SYSTEM_DESIGNS/`.
- Added `SYSTEM_DESIGNS/README.md` as the subsystem approval ledger and reusable system-design template. Major systems move through DRAFT -> APPROVED -> IMPLEMENTED (or SUPERSEDED), and DRAFT explicitly does not authorize coding.
- Added a change-impact declaration requirement: before implementing an approved system, identify the modules expected to change, neighboring modules that must remain untouched, and whether any public contract changes.
- Added the rule that if implementation unexpectedly requires crossing a forbidden module boundary, work stops and the system design returns to DRAFT rather than cascading a convenient patch into neighboring systems.
- Strengthened `README_SOPS.md` into a living repository SOP with the new scope/approval gates plus reusable Godot, Safari and GitHub lessons. Reusable discoveries must be written back to SOP/system docs during the same coherent prompt instead of living only in chat history.
- Added CI guards requiring the design workflow and system approval ledger to remain present and preserving the frozen reference runtime while Phase 0 design work continues.
- Set the recommended first detailed subsystem design to the semantic tactical map / `RaidMapSpec` contract. No new modular runtime code was implemented in this pass.

## Modular Rebuild Reset / Golden Recovery Contract — 2026-08-16

- Reclassified the current clean-reboot runtime under `game/scripts/reboot/` as **frozen/deprecated reference code** rather than the architecture to keep extending. The live Web build remains available until its modular replacement is proven.
- Added `MODULAR_REBUILD_MASTER_DESIGN.md` as the canonical next-build architecture and consolidated the current game direction, rural-generation rules, static strategic-map progression, vehicle-gateway concept, prefab direction, recovered/deferred systems, and implementation order.
- Made modularity a hard project rule: the root `Main.gd` is bootstrap/composition only. Rendering, input, controls, camera, zoom, player movement, collision, generation, strategic map, prefab authoring, extraction/travel, persistence, validation, and later simulation systems must each have standalone owners rather than accumulating as functions in Main.
- Pinned golden pre-clean-rewrite recovery commit `1763958f44eb7f855fd49944c00d1ffe608c0abe` for exact visual/system archaeology.
- Confirmed that the richer pre-rewrite artwork was **not lost**. The six important atlas files and four directional player sprites on current `main` are byte-identical to the golden commit. The visual regression came from replacing `TacticalTiles.gd`'s semantic multi-atlas selection/render behavior with a simplified reboot catalog, not from missing image files.
- Recorded exact golden/current asset blob hashes in the master design/context/SOP so future recovery work can distinguish an unchanged art asset from a changed renderer.
- Identified golden `TacticalTiles.gd` (`3d8a0a70ac983408bb48f58fc659dfb07e216ed3`) as the source of the mature multi-atlas visual vocabulary. Its semantic mappings/road topology/prop-selection behavior will be recovered into a standalone `ArtCatalog` plus separate ground/structure/prop/player renderers instead of copied back into another monolithic presentation script.
- Established a semantic world-data boundary: procedural generation must output concepts such as house walls, gravel driveways and kitchen sinks plus explicit physics facts; it may not output atlas indices or invoke renderer functions. This makes the random generator independently replaceable without changing graphics, player controls, camera, strategic map or other systems.
- Documented a proposed highly modular folder layout with independent app/data/art/render/camera/input/player/world/strategic/raid/generation/prefab-dev/UI/time/perception domains and separate generation planners/validators.
- Consolidated the current Rural Edge target: two-lane rural roads with straight/bend/crossroads variation, dirt/gravel access roads, broad vegetation/open land, utility/power infrastructure, sparse stop signs, roughly 3–4 residential properties as a normal scale rather than a rigid quota, farm/country-house/manufactured-home variation, and normally zero/one compact gas/convenience/corner store with no rural strip malls.
- Preserved the strongest recent geometry lessons: functional procedural rooms normally at least 3x3, storefront/public rooms around 5x5–7x7, support rooms around 3x3, wall-aware installed fixtures, circulation-aware clutter, and authoritative door-axis/approach validation.
- Defined the next implementation order: first build a bootstrap-only Main and recover the **exact old visual stack on a tiny authored test map**; only after the visuals are visibly verified should the new modular Rural Edge generator be written. Prefab tooling, travel/extraction, ticks, vision, lighting, weather and silent spatial sound follow as separate subsystem phases.
- Updated `README_CONTEXT.md` and `README_SOPS.md` so future code prompts are forced to treat the modular master design as canonical, inspect the actual golden implementation when recovering old behavior, avoid cross-subsystem rewrites, and ask targeted clarification before genuinely ambiguous destructive changes.
- This reset is deliberately **design/architecture only**: no current runtime scripts or retained art files were deleted or rewritten in this pass.

## Prefab Workshop / Authored Generator Inserts — 2026-08-16

- **Safari/mobile access fix:** replaced the easy-to-miss small strategic-map prefab control with a large bottom-center **PREFAB BUILDER** touch button, and enlarged/renamed the tactical prefab control to the same clear label.
- Added an in-game **Prefab Workshop** so reusable tactical structures can be authored directly in the running game instead of hardcoding every floor plan into `RebootSiteGenerator.gd`.
- Added `RebootPrefabEditor.gd`, a touch/mouse-first developer overlay with a **16x14 maximum canvas**, matching one far-zoom tactical window. Access it from `PREFAB BUILDER` in tactical play, the large `PREFAB BUILDER (n)` button on the strategic map, or F2 on desktop.
- Added a native `LineEdit` prefab-name field for reliable Web/Safari keyboard behavior.
- Added tap/click and drag painting for common floor tiles, canonical house/light/store/industrial walls, windows, horizontal-wall doors, vertical-wall doors, and three pages of common furniture/fixture/prop tools.
- Added ERASER plus two-tap CLEAR and DELETE protection for destructive editing actions.
- SAVE trims empty outer rows/columns, so a structure only occupies its actual used footprint rather than carrying the full 16x14 editor canvas.
- Added `RebootPrefabLibrary.gd` as the durable authored-content owner. Prefabs are serialized as portable JSON data at `user://reboot_prefabs.json` rather than becoming generator code.
- Web prefab persistence is intentionally **browser/device-local**. It is separate from the future survivor/world save system and does not automatically commit or synchronize authored prefabs to GitHub/another device.
- Added hard authored-prefab validation before SAVE. Door H/V orientation uses the same v4 wall-axis contract as procedural doors; bad wall intersections, blocked approaches, overlapping structure/props, and doors without same-axis structural neighbors are rejected.
- Exterior authored doors are supported: their approach clearance can extend outside the stored prefab footprint and is checked against the destination map during placement.
- Integrated saved prefabs into future Rural Road generation. After normal deterministic procedural generation, the runtime deterministically attempts **at most one** authored prefab insert before running the canonical site validator.
- Safe placement rejects player-spawn proximity, main roads, side roads, existing building buffers, existing structures, non-vegetation props, incompatible road/asphalt/field ground, and doorway-clearance conflicts. If no valid footprint exists, the map remains purely procedural.
- Authored prefabs currently appear as **additional structures** rather than replacing one of the four residences or roadside business. Semantic prefab roles/room tagging are intentionally deferred so the existing Rural Road property contract remains intact.
- Added `RebootPrefabSmoke.gd` as a permanent Pages CI gate. It builds a real cabin prefab, checks 16x14-to-used-footprint trimming, storage encode/decode round trip, deliberate broken-door rejection, deterministic stamping, preserved door-axis metadata, authored-use metadata, and full `RebootSiteGenerator.validate()` success after insertion.
- Added `PREFAB_WORKSHOP.md` and updated reboot context/SOP/core docs so prefab authoring, local persistence, safe stamping, and future export/import/semantic-role work have explicit owners and boundaries.

## Rural Road Generator v4 / Door Geometry & Road Variety — 2026-08-16

- Corrected the reported remaining "wall behind doors" problem as a **generator floor-plan defect rather than an art defect**. The tactical door tile was already correct; several prefabs were placing doors on or too near perpendicular partition geometry.
- Added authoritative door-axis metadata. Horizontal-wall doors reserve north/south approach cells; vertical-wall doors reserve east/west approach cells.
- Door cells and their perpendicular approaches are now structural reservations: later wall/window/fixture/clutter generation cannot overwrite them.
- Added a stronger door invariant: each door must retain structural neighbors on both sides of its own wall axis while its perpendicular approaches remain clear. This rejects doors embedded in wall crosses/T-junctions even when the door cell itself contains no wall.
- The new validator caught real prefab errors during implementation: country-house exterior doors shared an x-axis with an interior divider, one farmhouse partition door sat too close to a perpendicular junction, and manufactured-home door lines were separated proactively. The floorplans were corrected rather than weakening validation.
- Established **3x3 as the minimum usable functional-room size**. The rural store's old 3x1 manager office and 2x2 bathroom are now 3x3; every recorded home/business room must satisfy the same minimum.
- Rural roadside business contract is now 7x7 storefront, 3x3 stock room, 3x3 manager office, 3x3 bathroom and 7x3 rear service space.
- Rebuilt the rural main-road generator as connected topology rather than one hard-coded straight strip. Seeds now produce **straight roads, bent/curved-looking roads, or crossroads**.
- Added horizontal/vertical/corner/T/cross/end road sprite selection from the retained road-topology artwork.
- Protected authoritative main-road cells from later field, yard, building-floor, driveway or gas-forecourt painting so generated road connectivity cannot be visually overwritten after the fact.
- Property connectors now meet the main road using its local alignment, allowing homes/businesses to connect correctly to bent roads rather than assuming one global y coordinate.
- Permanent eight-seed smoke now requires all three road variants plus the 3x3 room minimum and axis-correct door geometry, while retaining the rural five-site composition, utility/power, vegetation, tactical-art, determinism and player checks.

## Rural Road Generator v3 / Original Tactical Tile Restoration — 2026-08-16

- Corrected the reboot's art restoration after playtesting showed that the v2 mapping still was **not the original tactical look**. The remembered structural vocabulary came from the early `TacticalTiles.gd` path, not the later `world_art` shell/opening tiles.
- Restored the exact original tactical-atlas structural mapping: wall variants **16–22**, closed door **23**, open door **24**, and window **25**. Common ground/floors and many common props also return to the original tactical/clutter sheets.
- Added hard door-clearance grammar and reframed rural tactical generation around four residences plus one roadside gas station/corner store, with one farm complex, manufactured housing, country houses, utility poles/power lines, sparse stop signs and rural vegetation.
- Added the first compact roadside business grammar and strengthened eight-seed deterministic validation. Generator v4 supersedes the older same-cell-only door validation and fixed straight-road assumption.

## Rural Road Generator v2 / Composite Art Restoration — 2026-08-16

- Replaced the reboot-v1 one-property rural archetypes with one coherent **Rural Road** biome grammar. A tactical map became a sample of rural road rather than one giant showcase farmhouse/trailer property.
- Reduced residential scale and introduced smaller functional room grammar, roadside lots, driveways/mailboxes, outbuildings, vegetation and fixture-placement validation.
- Expanded generator smoke coverage to eight deterministic Rural Road seeds.
- Attempted to restore the pre-reboot composite art vocabulary, but this pass incorrectly treated the later `world_art` structural shell/door vocabulary as the remembered old tile set. Generator v3 superseded that mapping with the actual early `TacticalTiles.gd` structural indices.

## Clean Reboot Core / Rural Generator v1 — 2026-08-16

- Replaced the active prototype runtime with a deliberately small clean-reboot core while retaining the existing environment and directional player artwork.
- Switched `game/main.tscn` to `scripts/reboot/RebootMain.gd`; the running build no longer loads the legacy v4-v6 generator chain, tick/calendar stack, weather, lighting, perception/fog, extraction-session presentation, or the old Safari autoload.
- Added `RebootArt.gd` as the reboot-only art catalog and `RebootSiteGenerator.gd` as a new deterministic 64x64 site generator that does not wrap or repair the legacy generator.
- Added the minimal player/movement/rotation core, phone-first controls, three tactical zoom levels, event-driven visible-cell renderer, static outskirts-to-city strategic map, reboot-only CI, and clean reboot documentation.
- Vision cone, lighting, weather, silent sound, infected, loot/inventory, combat, injuries, ticks/calendar, vehicles, extraction consequences and persistence remain intentionally deferred until the generator/player foundation is strong.

## Prototype era — archived in Git history

The earlier v0-v6 work established the retained art vocabulary and explored ticks, perception, weather, procedural regions, streetscapes, extraction travel and focused interiors. That runtime is no longer canonical after the clean reboot. Its detailed changelog remains available in repository history at commits before this reboot.
