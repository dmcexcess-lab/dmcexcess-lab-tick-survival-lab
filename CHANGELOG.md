# Changelog

## Clean Reboot Core / Rural Generator v1 — 2026-08-16

- Replaced the active prototype runtime with a deliberately small clean-reboot core while retaining the existing environment and directional player artwork.
- Switched `game/main.tscn` to `scripts/reboot/RebootMain.gd`; the running build no longer loads the legacy v4-v6 generator chain, tick/calendar stack, weather, lighting, perception/fog, extraction-session presentation, or the old Safari autoload.
- Added `RebootArt.gd` as the reboot-only art catalog using the final environment surface/prop atlases and four independent player-facing sprites.
- Added `RebootSiteGenerator.gd`, a new deterministic 64x64 site generator that does not wrap or repair the legacy generator.
- Added four first-band rural site archetypes: **Farmstead**, **Small Trailer**, **Double-Wide**, and **Country House**.
- Farmstead generation now treats the property as the content: a large multi-room farmhouse, barn, shed, fields, fences, driveway, yard clutter, utilities and vegetation rather than a road network with buildings fitted around it.
- Added functional rural room grammar and matching fixtures. The farmhouse contains living room, kitchen/dining, primary and secondary bedrooms, bathroom and utility/laundry; trailers/double-wides use distinct manufactured-home floor plans rather than relabeled generic houses.
- Added generator quality validation for required site/building/room functions, valid spawn, deterministic output and a hard maximum of 18% road/gravel coverage so roads cannot dominate a rural tactical map.
- Added `RebootPlayer.gd` with only grid cell + cardinal facing, left/right rotation, forward/back movement and O(1)-style blocker lookup. No tick/time system is present yet.
- Added a phone-first control deck with `FORWARD`, `BACK`, `TURN L`, `TURN R`, `MAP`, and `-`/`+` zoom controls plus keyboard development equivalents.
- Added local touch/mouse de-duplication to preserve one physical Safari tap = one action without restoring the old global input autoload.
- Added three tactical zoom levels and a player-following camera that renders only the visible cells of the 64x64 site.
- Established an event-driven performance baseline: no idle `_process()` redraw loop and no whole-map redraw merely because the map exists. Redraw occurs only after movement, turning, zoom, map toggle or site generation.
- Added a cheap static strategic progression display: **Base -> Rural Edge -> Small Town -> Suburbs -> City Edge -> City Core**. Only rural walking-range sites are selectable in this first slice; deeper nodes are visibly locked for later roaming/vehicle-gateway progression.
- Added `RebootSmoke.gd` to validate all four rural archetypes deterministically plus player rotation/movement/spawn invariants.
- Replaced the permanent Pages workflow with a reboot-only gate: canonical reboot source validation -> Godot 4.7.1 import/parse -> reboot core smoke -> real main-scene startup -> Web export -> Pages deployment.
- Added `REBOOT_CORE.md` and rewrote README/context/SOP documentation so future work extends the new owners rather than accidentally reviving legacy patch layers.
- Vision cone, lighting, weather, silent sound, infected, loot/inventory, combat, injuries, ticks/calendar, vehicles, extraction consequences and persistence are intentionally deferred until this generator/player foundation is playtested and strong.

## Prototype era — archived in Git history

The earlier v0-v6 work established the retained art vocabulary and explored ticks, perception, weather, procedural regions, streetscapes, extraction travel and focused interiors. That runtime is no longer canonical after the clean reboot. Its detailed changelog remains available in repository history at commits before this reboot.
