# Focused Raid Interiors / Generator v6

Status: current destination-generation contract layered under the extraction loop.

## Purpose

Each extraction destination is now allowed to be strongly itself. A Commercial raid does not need to spend map area proving that woods, rural, residential, downtown, and commercial terrain all exist at once. The 5×5 destination map already provides strategic variety between raids.

The local 64×64 generator should therefore spend its tile budget on **depth inside the selected destination**: larger structures, more meaningful interiors, stronger frontage, and rooms that imply a believable use.

The v4 procedural generator remains the physical road/network baseline. Generator v6 composes focused cleanup, large-shell preparation, streetscape/building-family specialization, and functional interior generation on top of that baseline.

## Generation order

`ProceduralRegionGenerator v4` → `DestinationFocusCleanupPass` → `MiniRegionFocusPass` → `StreetscapePass` → `DestinationInteriorPass`

The passes have separate responsibilities:

- `DestinationFocusCleanupPass.gd` removes incompatible legacy structures left by the old mixed stress-map generator and removes commercial parking parcels from non-commercial raids.
- `MiniRegionFocusPass.gd` normalizes the raid's biome identity and guarantees larger focus-appropriate building shells where space permits.
- `StreetscapePass.gd` selects recognizable building families, repairs parking, places traffic/street furniture, and sanitizes accidental door runs.
- `DestinationInteriorPass.gd` gives special families functional internal room purpose rather than treating them as one-room rectangles.

The passes mutate only generated initial map facts. Runtime doors, destruction, actors, loot, combat, and persistence remain owned elsewhere.

## Destination identity

For focused raids, `biome_cells` are normalized to the selected destination identity. This does not mean every individual ground tile becomes visually identical: roads, sidewalks, floors, yards, parking, trees, and structures still override the base terrain. It means biome-sensitive presentation and future destination-sensitive systems see one coherent raid identity instead of a five-biome stress mosaic.

Allowed legacy building themes are also destination-specific:

- Residential: house / rural-wood residential shells.
- Commercial: stores and offices.
- Downtown: offices, stores, industrial structures.
- Rural: rural-wood and house shells.
- Woods: rural-wood/cabin-like shells only.

Commercial/downtown may retain parking. Residential, rural, and woods do not retain old standalone commercial parking parcels.

## Large building targets

The focus pass searches for the largest coherent free rectangle first instead of always adding another 9×8 shell.

Current candidate ranges:

- Residential: up to 14×11.
- Commercial: up to 18×12.
- Downtown office: up to 18×12.
- Rural: up to 13×10.
- Woods/cabin shell: up to 11×9.

These are bootstrap targets, not hard architectural maxima. Roads, spawn safety, existing structures, parking, and physical geometry can force a smaller candidate.

Commercial and downtown validation require at least one destination building of roughly 130+ tiles of footprint area; residential requires roughly 110+ when generated through v6.

## Functional interiors

### Standalone store / commercial anchor

A large store should contain:

- sales floor;
- checkout/retail fixtures;
- **manager office**;
- **back stockroom**;
- storage fixtures such as pallet racks/cardboard;
- appropriate retail refrigeration/shelving when available.

The purpose is eventual search gameplay: a player should have a reason to move from the public front to restricted rear rooms instead of searching one open rectangle.

### Office / downtown anchor

A large office can contain:

- reception;
- open office area;
- **manager office**;
- storage/file room;
- meeting room;
- desks/computers/cubicles/filing fixtures.

This creates sight-line breaks and multiple room-entry decisions without introducing multi-floor architecture.

### Ordinary larger house

A larger house should contain recognizable domestic functions rather than `front_room/back_room` only:

- living room;
- kitchen;
- primary bedroom;
- bathroom;
- domestic fixtures such as sofa/TV, stove/fridge, bed, toilet/vanity.

Future larger residential templates may add garages, second bedrooms, laundry, dining rooms, utility rooms, dens, or enclosed patios using the same room-purpose approach.

### Mansion / estate house

Current deep mansion layout includes:

- living room;
- kitchen;
- primary bedroom;
- secondary bedroom when the footprint supports it;
- bathroom;
- richer domestic fixtures.

A mansion remains a large single-story gameplay house, not a literal multi-floor estate simulation.

### Duplex

A duplex remains two sealed residences. Each unit now has internal purpose rather than being one undifferentiated room:

- living/kitchen zone;
- bed/bath zone;
- independent exterior access remains owned by the family shell.

### Strip mall

Each storefront unit has a public sales section plus rear depth. The first unit supplies a manager-office rear room while other units provide back stockrooms. Unit partitions and separated storefront entrances remain intact.

This is deliberately more interesting than a long rectangle divided into three one-room stores.

### Trailer

Trailer interiors remain compact but purposeful:

- living/kitchen zone;
- bed/bath zone.

## Validation

Permanent `MiniWorldSmoke.gd` calls `MiniRegionGenerator.validate()` across all 25 deterministic destination sites. Generator v6 validation now proves, through its composed passes:

- focused biome identity does not leak back into a five-biome mixture;
- off-focus legacy building themes are removed;
- non-commercial raids do not retain commercial parking parcels;
- streetscape invariants still hold;
- commercial raids contain stockroom and manager-office room purpose;
- downtown raids contain office/reception and manager-office purpose;
- residential raids contain living, kitchen, bedroom, and bath purpose;
- special building families retain valid physical footprints;
- developed destinations contain at least one larger anchor building;
- existing v4 road/network/collision validation remains in force except for obsolete whole-world biome-diversity and one-size-fits-all building-size assumptions.

## Non-goals

This pass does not add loot, searchable-container behavior, infected, combat, body state, a physical base, audible sound, multi-floor buildings, or runtime persistence.

Room names and fixtures are physical/content vocabulary for later systems. They do not secretly own loot tables or interactions yet.

## Design rule

**Destination selection provides breadth between raids; local generation should provide depth within the raid.**