# Tick Survival Lab — Procedural World Generation Rules

## Purpose

The procedural world system must create places that feel geographically plausible enough to navigate and inhabit while remaining deterministic, destructible, and compatible with the same physical tile/object schema used by the authored First Fire-derived tactical locations.

The generator is not allowed to create a second kind of map. Whether a building is authored or procedural, the resulting world facts are still ground, indoor regions, walls, doors, windows, obstacles, props, lights, exits, actors, items, and later persistent damage/state.

## Scale hierarchy

The intended hierarchy is:

**tile/object → parcel/building → block/local area → biome/district → region/chunk → island**

The current stress slice generates one deterministic 64×64 region. That is large enough to prove follow-camera, biome transitions, roads, structures, weather, LOS, and movement over a map roughly eleven times the tile count of the original 20×18 tactical locations.

The final island should not be one permanently active giant tile dictionary. Large worlds should be represented as deterministic region/chunk coordinates generated from a world seed. Only regions near active actors need full tile/object simulation loaded. Distant regions can remain summarized until needed.

This means practical island size is limited more by persistence and active-actor simulation than by terrain generation. Hundreds of 64×64 regions are technically reasonable if only a small neighborhood is active at a time.

## Determinism

Every region must be reproducible from:

- world seed;
- region coordinate;
- generator version/ruleset.

The current local generator now exposes `generator_version = 2`. The same inputs must produce the same biome ownership, roads, road classes, initial buildings, initial clutter, and lights. Persistent changes after generation belong to world state and override regenerated initial facts.

## Biome/district vocabulary

### Residential

Purpose: homes, yards, small apartment pockets, neighborhood streets, schools/parks later.

Rules:

- medium road density;
- detached structures require practical road frontage rather than appearing deep inside inaccessible parcels;
- yard setbacks and undeveloped yard parcels remain common;
- grass/wood dominate with sidewalks near roads;
- mailboxes, bins, bushes, trees and household clutter reinforce the street edge;
- multiple household access points and richer interiors can expand later without changing the parcel contract.

### Commercial

Purpose: strip retail, gas stations, restaurants, offices, parking lots and roadside services.

Rules:

- strong road adjacency requirement;
- broad paved/concrete surfaces and parking/open lots;
- medium/large rectangular footprints;
- entrances orient toward the nearest road frontage;
- storefront windows, counters, shelving, carts, bins, benches and utility clutter;
- strongest transition band between residential and downtown.

### Downtown

Purpose: dense urban core, multi-use buildings, narrow alleys, service access and high-value infrastructure.

Rules:

- highest structural density;
- arterial road focus plus short local/service streets rather than arbitrary full-region grids;
- larger footprints and reduced setbacks;
- more sidewalk/tile/concrete;
- benches, hydrants, streetlights and powered infrastructure;
- future verticality can be represented as building interiors/floors without changing outdoor region coordinates.

### Woods

Purpose: wilderness, concealment, trails, camps, hunting areas and low-infrastructure spaces.

Rules:

- paved roads do not grid through woods;
- district connectors become narrow dirt trails;
- grass/dirt dominate;
- trees are true movement/vision obstacles while low bushes can remain visual clutter;
- vegetation is clustered rather than uniformly random;
- sparse firewood/camp clutter may appear;
- stronger presence near island edge and between developed pockets when geography supports it.

### Rural

Purpose: farmland, ranches, farmhouses, sheds, fields, service roads and isolated infrastructure.

Rules:

- low road density but long connected routes;
- dirt/service roads instead of urban street grids;
- large open parcels;
- sparse farmhouses should still sit within useful reach of a road;
- fences, trees, firewood and mailboxes define farm edges;
- natural transition between woods and developed districts;
- future crops, livestock and utility infrastructure plug into these parcels.

## Biome assignment

The current prototype uses seeded spatial centers and weighted distance to create contiguous district fields rather than independent random cells. Downtown is biased toward the region center; rural and woods are biased outward. Small deterministic noise breaks perfectly smooth borders.

Long-term refinement should add macro geography before biome assignment: coastline/elevation/water, then major roads and infrastructure, then district suitability. Biomes should respond to those constraints rather than being pure colored Voronoi patches.

## Road hierarchy

Generation order matters and is now enforced in the 64×64 prototype.

1. Each biome receives a connector toward the nearest main arterial axis.
2. Developed biomes receive short local cross streets; rural and woods receive lighter service roads/trails.
3. A three-tile arterial cross is carved last so its surface/class wins at intersections.
4. All four region exits are placed on that same arterial network.
5. The player spawn is placed on the arterial crossing, so the test start can reach every edge exit by road.
6. Developed road edges receive sidewalks; rural edges receive dirt shoulders.
7. Parcels/structures are placed only after roads, and developed structures require nearby road frontage.
8. Building doors orient toward the nearest road side instead of always facing one global direction.

`road_cells` records traversable road/trail membership, while `road_class_cells` records `arterial`, `secondary`, `local`, or `trail`. Region validation fails if an exit or spawn is not on the road network, if an edge exit cannot be reached from spawn through road cells, or if later geometry blocks a road tile.

This is still a local-region prototype, not the final island road planner. Major roads must eventually continue across region boundaries using deterministic edge contracts derived from world seed + neighboring region coordinates. A road leaving one chunk must enter its neighbor at the same coordinate. The current `road_ports` field establishes the local data shape but does not yet claim neighbor-compatible macro contracts.

## Parcel and structure rules

Structures are generated from parcels, not by scattering wall rectangles independently.

A parcel owns or derives:

- biome/district;
- road frontage/distance;
- allowed footprint range;
- setback/open-space rules;
- structure archetype candidates;
- utility/parking/yard zones;
- entrance preference;
- density.

The structure generator then writes standard physical facts into the shared map schema. Procedural buildings now also record per-wall theme metadata, orient doors toward road frontage, use more appropriate interior light profiles, and receive modest deterministic interior/exterior clutter.

Authored building templates may later be inserted into compatible parcels, allowing procedural city layout with hand-authored high-quality interiors.

## Clutter rules

Clutter must reinforce place identity without becoming random visual noise or secretly changing game rules.

Current reusable clutter vocabulary includes indoor chair, desk, toilet, sink, cabinet, bookshelf, television, lamp, rug and laundry sprites plus outdoor tree, bush, fence, mailbox, trash can, road sign, bench, hydrant, streetlight, planter, tire pile, cardboard, picnic table and firewood sprites.

Placement rules distinguish visual clutter from physical obstacles. Large/tall objects may enter `obstacles`; small decoration remains in `props`. Tall objects that should block vision are separately recognized by perception. This preserves the important distinction between **looks solid**, **blocks movement**, and **blocks sight**.

## Region boundaries

Each region eventually needs deterministic edge contracts for:

- roads/trails;
- rivers/drainage;
- coastline/impassable terrain;
- utility lines;
- biome continuity.

This avoids visible seams and lets regions be generated independently or lazily.

## Active simulation budget

Rendering is camera-local. Lighting and vision are player-local. Later actor simulation should use tiers:

- **active:** exact tick-by-tick actors near the player or an important event;
- **nearby:** lower-detail scheduled simulation in neighboring chunks;
- **distant:** summarized state changes only.

The world remains authoritative without requiring every zombie, animal, crop and survivor on the island to execute every tick.

## Current prototype limits / next geography work

The 64×64 generator now proves contiguous biome fields, connected road hierarchy, frontage-aware structures, deterministic clutter, follow-camera navigation, weather, day/night lighting and local LOS/fog. It does not yet simulate coastlines, rivers, elevation, neighbor-compatible chunk road contracts, true building archetype libraries, utilities, loot economy, populations, outbreak state, or persistence deltas.

Before building a full island, the next world-generation-specific work should be **macro geography + edge contracts**, not simply making the current local region bigger. Coastline/water/elevation and cross-region roads should become the constraints that the existing biome/parcel generator responds to.
