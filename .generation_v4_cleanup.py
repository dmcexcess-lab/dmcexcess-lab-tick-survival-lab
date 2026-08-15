from pathlib import Path

# Fix exterior prop anchors that were authored against the old 7x7 parcels.
p = Path('game/scripts/ProceduralRegionGenerator.gd')
s = p.read_text()
s = s.replace('anchor + Vector2i(PARCEL_W / 2, PARCEL_H / 2)', 'anchor + Vector2i(int(PARCEL_W / 2), int(PARCEL_H / 2))')
s = s.replace('a.y + PARCEL_H / 2, PARCEL_W, 1, "dirt"', 'a.y + int(PARCEL_H / 2), PARCEL_W, 1, "dirt"')
s = s.replace('Vector2i(a.x + 1, a.y + 6), "mailbox", false', 'Vector2i(a.x + 1, a.y + 10), "mailbox", false', 1)
s = s.replace('Vector2i(a.x + 5, a.y + 6), "trash_can", false', 'Vector2i(a.x + 5, a.y + 10), "trash_can", false', 1)
s = s.replace('Vector2i(a.x + 6, a.y + 1), "hedge", false', 'Vector2i(a.x + 9, a.y + 2), "hedge", false', 1)
s = s.replace('Vector2i(a.x + 6, a.y + 4), "flower_bed", false', 'Vector2i(a.x + 9, a.y + 5), "flower_bed", false', 1)
s = s.replace('Vector2i(a.x + 1, a.y + 6), "hydrant", false', 'Vector2i(a.x + 1, a.y + 10), "hydrant", false', 1)
s = s.replace('var lamp_cell := Vector2i(a.x + 5, a.y + 6)', 'var lamp_cell := Vector2i(a.x + 8, a.y + 10)', 1)
# Rural farmhouse occurrences come after the residential replacement above.
s = s.replace('Vector2i(a.x + 1, a.y + 6), "mailbox", false', 'Vector2i(a.x + 1, a.y + 10), "mailbox", false', 1)
s = s.replace('Vector2i(a.x + 6, a.y + 5), "propane_tank", false', 'Vector2i(a.x + 9, a.y + 6), "propane_tank", false', 1)
p.write_text(s)

# Durable generation rules.
p = Path('WORLD_GENERATION.md')
s = p.read_text()
s = s.replace('The current local generator now exposes `generator_version = 2`.', 'The current local generator exposes `generator_version = 4`.')
parcel_anchor = 'The structure generator then writes standard physical facts into the shared map schema. Procedural buildings now also record per-wall theme metadata, orient doors toward road frontage, use more appropriate interior light profiles, and receive modest deterministic interior/exterior clutter.\n'
parcel_extra = '''The current local-region parcel pass uses **10×11 parcel cells** as its bootstrap block grammar instead of the old 7×7 micro-parcels. Generated houses/shops are generally 9×8, while downtown structures may occupy 10×10. This gives structures enough interior area to function as places rather than decorative boxes.\n\nGenerated structures now emit `building_rects` plus real `rooms`. Room boundaries are written as ordinary physical wall cells with ordinary door cells cut through them; there is no separate fake interior-map schema. Current bootstrap layouts provide three-room houses/rural homes, sales-floor + stockroom stores, three-zone offices, and utility-room + warehouse industrial layouts. Room-specific floor overlays use the same shared ground language.\n\nCommercial parking uses an asphalt lot base plus explicit `parking_cells` for marked stalls. **Parking stall tiles may not touch cardinally**: there must be at least one non-parking tile between neighboring marked stalls. `parking_lots` records the lot footprint while `parking_cells` records only individual marked spaces.\n'''
if parcel_extra not in s:
    s = s.replace(parcel_anchor, parcel_anchor + '\n' + parcel_extra)
map_section = '''## Overworld map presentation\n\nThe player-facing map is one **full-screen overworld map**, opened from the tactical view by the on-screen `MAP` control or keyboard `M`. It is a schematic presentation of the same authoritative world coordinates: biome terrain, roads, parking lots, building footprints, exits, and the survivor as a red dot. Opening/closing it costs zero ticks and it does not own simulation state.\n\nThere is intentionally **no minimap and no separate local-area map mode**. Interior rooms remain tactical-world geometry and are seen by entering/exploring the building rather than through a second local map layer.\n\n'''
if '## Overworld map presentation' not in s:
    s = s.replace('## Region boundaries\n', map_section + '## Region boundaries\n')
s = s.replace('true building archetype libraries, utilities, loot economy', 'larger authored building-archetype libraries, utilities, loot economy')
p.write_text(s)

# Current project context.
p = Path('README_CONTEXT.md')
s = p.read_text()
s = s.replace('Current generator version is 3.', 'Current generator version is 4.')
s = s.replace('The current generator version is **3**.', 'The current generator version is **4**.')
s = s.replace('connected road hierarchy, directional road topology art, follow-camera/zoom,', 'connected road hierarchy, larger room-aware procedural buildings, spaced parking stalls, a full-screen overworld map, directional road topology art, follow-camera/zoom,')
map_rule_anchor = 'Map tapping remains available. `MENU`/Escape opens the actual pause menu and Web exit uses same-tab browser navigation.\n'
map_rule_extra = '''\nThe player map is **one full-screen overworld map only**. `MAP` on touch or keyboard `M` opens it; it shows the current generated region with roads, parking lots, building footprints, biome terrain, exits, and the survivor as a red dot. It costs zero ticks and blocks tactical action input while open. There is deliberately no minimap and no separate local-area-map mode.\n'''
if 'one full-screen overworld map only' not in s:
    s = s.replace(map_rule_anchor, map_rule_anchor + map_rule_extra)
road_anchor = '- procedural buildings now emit `wall_themes`, `door_themes`, and `window_themes` as presentation metadata while physical membership remains walls/doors/glass.\n'
road_extra = '''- generator v4 uses 10×11 bootstrap parcels with 9×8 houses/shops and up-to-10×10 downtown structures;\n- `building_rects` records overmap-scale footprints while `rooms` records room zones; room partitions themselves are ordinary physical wall/door cells;\n- `parking_lots` records paved lot footprints and `parking_cells` records marked stalls; parking stall cells are never cardinally adjacent, guaranteeing at least one non-parking tile between marked spaces.\n'''
if '`building_rects` records overmap-scale footprints' not in s:
    s = s.replace(road_anchor, road_anchor + road_extra)
s = s.replace('true room-aware building-template libraries, loot economy', 'larger authored building-template libraries, loot economy')
p.write_text(s)

# Changelog entry.
p = Path('CHANGELOG.md')
s = p.read_text()
heading = '## Full-Screen Overworld Map / Generation v4 — 2026-08-14'
section = '''## Full-Screen Overworld Map / Generation v4 — 2026-08-14\n\n- Added one full-screen Zomboid-style overworld map presentation, opened by keyboard `M` or a Safari-safe on-screen `MAP` button; there is intentionally no minimap and no separate local-area map mode.\n- The overworld uses the same generated region coordinates and shows biome terrain, road network, parking-lot footprints, building footprints, exits, and the survivor as a red dot; opening/closing it costs zero authoritative ticks and tactical actions are blocked while it is open.\n- Upgraded `ProceduralRegionGenerator.gd` to generator version 4 and replaced 7×7 micro-parcels with a 10×11 bootstrap parcel grammar.\n- Enlarged generated houses/shops to roughly 9×8 and downtown structures to as much as 10×10 so interiors have meaningful traversable area.\n- Added real physical interior subdivision: houses/rural homes get three rooms, stores get sales + stock rooms, offices get three zones, and industrial buildings get utility + warehouse zones. Interior partitions are ordinary wall cells with ordinary door cells, not a second map schema.\n- Added `building_rects` and `rooms` metadata for presentation/testing while keeping collision/LOS authority in the existing walls/doors/world state.\n- Reworked commercial parking: lots use an asphalt base and only marked stalls use parking tiles; parking stall cells are prohibited from touching cardinally, guaranteeing at least one non-parking tile between adjacent marked spaces.\n- Updated tactical presentation to consume per-cell wall/door/window themes so the new interior partitions and existing shell metadata render with their intended material vocabulary.\n- Strengthened deterministic region validation/smoke coverage for building footprint size, room subdivisions, interior walls/doors, parking metadata, and parking-stall spacing.\n\n'''
if heading not in s:
    assert s.startswith('# Changelog\n')
    s = '# Changelog\n\n' + section + s[len('# Changelog\n'):].lstrip('\n')
p.write_text(s)
