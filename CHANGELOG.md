# Changelog

## Prefab Workshop / Authored Generator Inserts — 2026-08-16

- Added an in-game **Prefab Workshop** so reusable tactical structures can be authored directly in the running game instead of hardcoding every floor plan into `RebootSiteGenerator.gd`.
- Added `RebootPrefabEditor.gd`, a touch/mouse-first developer overlay with a **16x14 maximum canvas**, matching one far-zoom tactical window. Access it from `PREFABS` in tactical play, `PREFABS n` on the strategic map, or F2 on desktop.
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
- Property connectors now meet the main road using its local alignment, allowing homes/businesses to connect correctly to bent road variants.
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
