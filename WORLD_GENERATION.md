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

The same inputs must produce the same biome ownership, roads, parcels, initial buildings, and initial props. Persistent changes after generation belong to world state and override regenerated initial facts.

## Biome/district vocabulary

### Residential

Purpose: homes, yards, small apartment pockets, neighborhood streets, schools/parks later.

Rules:

- medium road density;
- mostly small detached structures with yard setbacks;
- occasional denser residential parcels near commercial/downtown borders;
- more grass/wood/carpet/linoleum than concrete;
- many windows and multiple household access points over time;
- moderate loot density, high variety, low industrial material density.

### Commercial

Purpose: strip retail, gas stations, restaurants, offices, parking lots and roadside services.

Rules:

- high road adjacency;
- broad paved/concrete surfaces and parking areas;
- medium/large rectangular footprints;
- storefront-facing doors/windows;
- signs, carts, counters, shelving, vending and utility objects;
- strongest transition band between residential and downtown.

### Downtown

Purpose: dense urban core, multi-use buildings, narrow alleys, service access and high-value infrastructure.

Rules:

- highest structural density;
- arterial road focus plus alleys/service corridors;
- larger footprints and reduced setbacks;
- more sidewalk/tile/concrete;
- more artificial lighting and powered infrastructure;
- future verticality can be represented as building interiors/floors without changing outdoor region coordinates.

### Woods

Purpose: wilderness, concealment, trails, camps, hunting areas and low-infrastructure spaces.

Rules:

- very low paved-road density except crossings;
- grass/dirt dominant;
- vegetation obstacles clustered rather than uniformly random;
- winding dirt paths/clearings;
- sparse structures;
- stronger presence near island edge and between developed pockets when geography supports it.

### Rural

Purpose: farmland, ranches, farmhouses, sheds, fields, service roads and isolated infrastructure.

Rules:

- low road density but long connected routes;
- large open parcels;
- dirt/grass fields;
- sparse farmhouses/outbuildings;
- natural transition between woods and developed districts;
- future crops, livestock and utility infrastructure plug into these parcels.

## Biome assignment

The current prototype uses seeded spatial centers and weighted distance to create contiguous district fields rather than independent random cells. Downtown is biased toward the region center; rural and woods are biased outward. Small deterministic noise breaks perfectly smooth borders.

Long-term refinement should add macro geography before biome assignment: coastline/elevation/water, then major roads and infrastructure, then district suitability. Biomes should respond to those constraints rather than being pure colored Voronoi patches.

## Road hierarchy

Generation order matters.

1. Major arterials establish long-distance connectivity.
2. Secondary roads connect districts and parcels.
3. Local residential/commercial streets subdivide developed areas.
4. Rural service roads and woodland trails use lighter ground types and lower connectivity requirements.
5. Parcels/structures are placed after roads so buildings never sever required travel corridors.

Major roads should eventually continue across region boundaries using edge contracts derived from world seed + region coordinate. A road leaving one chunk must enter its neighbor at the same coordinate.

## Parcel and structure rules

Structures are generated from parcels, not by scattering wall rectangles independently.

A parcel owns:

- biome/district;
- road frontage;
- allowed footprint range;
- setback/open-space rules;
- structure archetype candidates;
- utility/parking/yard zones;
- entrance preference;
- density.

The structure generator then writes standard physical facts into the shared map schema. Authored building templates may later be inserted into compatible parcels, allowing procedural city layout with hand-authored high-quality interiors.

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

## Current prototype limits

The 64×64 generator currently proves rules and data flow only. It does not yet simulate coastlines, rivers, elevation, cross-region road contracts, true building archetype libraries, utilities, loot economy, populations, outbreak state, or persistence deltas. Those should be layered onto this foundation rather than replacing it.
