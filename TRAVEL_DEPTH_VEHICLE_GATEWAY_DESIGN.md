# Foot Travel / Vehicle Gateway Progression Design

Status: **design-only next-step contract; not implemented yet.**

This document defines the next navigation/progression direction for Tick Survival Lab. It supersedes the idea that the 5×5 destination map is simply a flat menu where every destination can be selected from base. It also rejects the idea that the game should render or simulate a seamless island surface.

The extraction loop remains valid. The change is how the player reaches raid destinations and how world depth is represented.

## 1. Core decision

The world is organized as **travel layers connected by vehicles**.

The player begins at base with **foot travel only**. Foot travel reaches a limited set of nearby locations. A vehicle is not initially a free-roaming tactical driving simulation. It functions like a dungeon staircase:

- the vehicle is a persistent gateway between one travel layer and another;
- using it moves the staging point into a farther/deeper region;
- the same parked vehicle is the route back to the previous layer;
- deeper layers contain their own nearby foot-accessible raid destinations;
- later vehicles/gateways can lead still farther outward.

The resulting structure is:

**BASE / TRAVEL LAYER 0**
→ walk to nearby raid site
→ extract back to base
→ eventually acquire/repair a vehicle gateway
→ **VEHICLE TRANSITION**
→ **TRAVEL LAYER 1**
→ walk from the parked vehicle to nearby raid sites
→ extract back to the parked vehicle staging point
→ use the same vehicle to return to Layer 0
→ eventually discover/unlock a gateway to Layer 2
→ repeat.

This is intentionally analogous to descending floors in a dungeon, except the floors are geographic travel bands and the stairs are vehicles.

## 2. Why this replaces the flat destination menu

The current flat 5×5 destination catalog has two problems:

1. It makes distance meaningless because every destination is one tap away from base.
2. It encourages local 64×64 generators to act like miniature cities containing roads, multiple biomes, and scattered parcels rather than dense raid locations.

The new design separates those responsibilities:

- the **travel map** expresses distance, progression, and access;
- the **raid map** expresses one detailed location worth exploring;
- the **vehicle gateway** expresses progression into farther territory.

This lets the local generator stop spending most of its 64×64 budget on connective roads and grass.

## 3. World topology: layered travel maps

The macro world is not one continuous tile plane. It is a deterministic graph of travel layers.

Each layer represents a geographic band around the player's current long-range staging anchor.

### Layer 0 — home range

The first layer is centered on the survivor's base.

It contains only destinations close enough to reach on foot and still plausibly return.

Examples:

- neighborhood houses;
- nearby convenience/strip commercial;
- small office or service property;
- wooded edge;
- rural fringe;
- utility/industrial property.

The exact arrangement is procedural from the world seed.

### Layer 1+ — vehicle ranges

A vehicle transition creates a new staging layer centered on the vehicle's destination/parking point.

That layer contains another set of foot-accessible destinations around the parked vehicle.

Later layers may trend toward different content without becoming hard level tiers. Examples:

- outer suburb;
- commercial corridor;
- denser office/industrial district;
- deep rural/farm country;
- forest/wilderness edge;
- urban core.

The world seed determines what lies farther out.

### Bootstrap scale

For the first implementation, use **three travel depths**:

- Depth 0: Base / immediate walking range.
- Depth 1: First vehicle-access region.
- Depth 2: Deeper vehicle-access region.

The architecture must permit more depths later without changing the state model.

## 4. Travel-map representation

The existing 5×5 map can be reused as a **travel-layer page**, but its meaning changes.

Each page represents one travel depth around the current staging anchor.

Cells are **destinations/nodes**, not pieces of continuously adjacent terrain.

A node stores at least:

- coordinate within the travel page;
- destination type;
- display name;
- deterministic site seed;
- distance from staging anchor;
- access mode (`foot`, `vehicle_gateway`, locked/future);
- optional gateway target depth;
- discovered/known state later;
- visit count through existing raid-session logic.

The center or designated anchor cell represents the current staging point:

- base on Depth 0;
- parked vehicle on deeper layers.

The player marker remains red.

## 5. Foot-travel rule

At the beginning of the game, **walking is the only strategic travel mode**.

The player may select only destinations inside the current staging anchor's walking range.

### Walking range is a gameplay limit

The world map should visibly distinguish:

- reachable on foot;
- known but too far to walk;
- inaccessible because it requires a vehicle gateway;
- undiscovered, if discovery is added later.

The first implementation does not need a detailed hiking simulation between maps. Travel may remain abstract, but it should no longer be free in the design.

Ultimately foot deployment should consume authoritative world cost derived from distance, such as:

- elapsed calendar time;
- fatigue/stamina burden;
- hunger/thirst once those systems exist;
- encumbrance effects on return travel.

Do not invent those secondary costs before their owning systems exist. The first implementation may use a single distance-to-travel-ticks rule.

### Safe selection rule

A destination should be selectable only when it is considered reachable from the current staging anchor.

The game should never strand the player merely because they clicked a map cell outside supported return range.

## 6. Vehicle gateway rule

Vehicles are **world-navigation gateways first** and drivable simulation objects later, if ever needed.

A usable vehicle functions like stairs in a dungeon.

### Entering a vehicle gateway

Using a vehicle gateway:

1. closes the current travel layer;
2. records the source layer and gateway identity;
3. advances to the linked deeper travel layer;
4. places the staging anchor at that vehicle's arrival/parking node;
5. reveals/selects nearby foot-accessible destinations around that parked vehicle.

### Returning

The parked vehicle remains present as the guaranteed return gateway.

Using it returns to the previous travel layer and its corresponding source anchor.

This is the important stairs rule:

> A vehicle that takes you deeper must also provide the clear route back out.

The player should never need to find a different random extraction vehicle just to return to the previous macro layer.

### Vehicle state later

Future systems can add:

- fuel;
- damage;
- repair requirements;
- storage capacity;
- survivor capacity;
- trunk/loadout transfer;
- vehicle-specific range;
- breakdown events;
- noise/risk during travel.

Those are future systems. The first implementation should treat a gateway vehicle as either **usable or unusable**, not simulate a full car.

## 7. How vehicles are acquired

Vehicles should become progression objects rather than instant starting permissions.

The intended progression is:

1. start with only nearby foot raids;
2. scavenge and survive locally;
3. discover a vehicle opportunity;
4. later satisfy whatever requirements make it usable (keys, fuel, repair, battery, etc. when those systems exist);
5. the usable vehicle unlocks the next travel layer;
6. farther regions expose different/better/more dangerous opportunities.

For bootstrap testing, DEV may mark a gateway vehicle usable immediately. That test shortcut must not become the final progression rule.

## 8. Extraction semantics under layered travel

Tactical extraction still ends the active raid.

What changes is the place the player returns to.

### Depth 0

A successful local raid returns to the **base staging layer**.

### Deeper layers

A successful raid returns to the **parked vehicle staging layer**, not magically all the way home.

The player then chooses whether to:

- raid another nearby site on foot;
- use the vehicle gateway to return toward base;
- eventually use another unlocked gateway to travel still deeper.

This produces expedition structure without requiring one giant continuous map.

## 9. Tactical raid-map philosophy

The 64×64 tactical map is no longer responsible for representing a whole district.

It represents **one destination**.

The generator must therefore prefer density and purpose over broad terrain coverage.

### Global tactical-map rules

A raid should normally contain:

- one dominant destination/POI;
- optionally one or two secondary structures/features;
- enough exterior space for approach, stealth, sight lines, and extraction;
- roads only where the destination logically needs them;
- no requirement for a full connected street network across every map;
- no requirement to showcase every environment family;
- no large empty grass/asphalt fields unless they are part of the destination's identity.

Roads become **context**, not the main content.

### Commercial / strip mall

Prefer one large strip center or standalone commercial complex occupying a major part of the map.

Possible composition:

- frontage road along one edge;
- parking field with believable aisles;
- 2–5 storefront units;
- manager office(s);
- rear stockrooms;
- service corridor/alley;
- dumpster/loading area;
- one or more rear exits;
- optional detached kiosk/service structure.

The player should spend most of the raid exploring the property, not walking through decorative roads.

### Office / business park

Prefer one large single-story office complex or two related office buildings.

Possible spaces:

- reception;
- open office;
- private offices;
- manager/executive office;
- conference room;
- storage/file room;
- break room;
- bathrooms;
- utility/server room;
- parking/loading edge.

### Residential

Prefer a recognizable neighborhood slice rather than a road grid.

Possible composition:

- 2–4 substantial houses;
- or one mansion/estate plus grounds/outbuildings;
- or duplex/fourplex cluster;
- fenced yards;
- garages/sheds;
- living rooms, kitchens, multiple bedrooms, bathrooms, laundry/utility areas.

The road may run along one edge or through one side of the map, but should not consume the center simply to prove road connectivity.

### Rural

Possible composition:

- farmhouse + barn + shed;
- trailer property + workshop;
- farmyard + fields;
- roadside service property;
- fenced acreage.

Large open space is acceptable here because it is meaningful rural terrain rather than leftover generation space.

### Woods

Possible composition:

- dense woodland;
- trails;
- cabin/camp;
- hunting shack;
- clearing;
- creek/wash later;
- abandoned service road only where useful.

Woods should feel like traversal/concealment space, not grass with a road cross.

## 10. Destination identity and procedural variety

A node's destination type controls the broad grammar, but each deployment still receives a fresh deterministic raid seed through the existing visit-seed system.

Therefore repeated raids to a Residential node can produce different local layouts while still always reading as residential.

The hierarchy becomes:

**world seed**
→ travel-layer graph
→ destination node identity
→ node site seed
→ visit count
→ raid seed
→ focused tactical layout.

This preserves reproducibility while maintaining replay variation.

## 11. Travel depth is progression, not difficulty level

Deeper does not simply mean `+20% zombie health` or other gamey scaling.

Depth should change **access and opportunity**.

Farther regions may naturally differ because they contain:

- larger commercial centers;
- denser office districts;
- specialized industrial sites;
- remote farms;
- richer or rarer loot pools later;
- different survivor/infected population patterns later;
- increased logistical cost of failure because the player is farther from base.

The simulation systems should create much of the danger. Travel depth mainly increases commitment and broadens possible content.

## 12. Map UI behavior

The world/travel map becomes one of the central game screens.

At any staging point it should show:

- current travel depth;
- current anchor (`BASE` or vehicle name/status);
- red player marker at the anchor;
- destination nodes with biome/type iconography;
- foot-reachable nodes clearly enabled;
- too-far nodes visually disabled;
- usable vehicle gateway(s) distinctly marked;
- return vehicle marked clearly on deeper layers.

On Safari/mobile:

- all nodes must be large tap targets;
- no hover dependency;
- tap once to select/show destination summary;
- explicit `DEPLOY` / `TRAVEL` action is preferred over accidental one-tap launch once the map carries more consequence;
- MAP remains a dedicated touch control.

During an active tactical raid, the travel map remains inspection-only.

## 13. Travel costs and ticks

Travel must eventually participate in authoritative time.

The durable rule should be:

> Strategic travel is an action with explicit world cost, even though the intermediate terrain is not tactically simulated.

### Foot travel

Cost derives from node distance and later modifiers such as fatigue/encumbrance/weather.

### Vehicle travel

Cost derives from gateway distance and later vehicle/fuel/road-condition rules.

### Bootstrap implementation

The first travel implementation may use simple fixed-per-distance authoritative tick costs. It must not use real-time animation duration as simulation time.

The tactical raid still begins only after travel cost has been committed.

## 14. Persistence model

The layered design requires persistent strategic state, not persistent rendered terrain.

Persistent world/session data should eventually include:

- world seed;
- generated travel-layer graph;
- discovered destination nodes;
- current travel depth;
- current staging anchor;
- vehicle gateway identities and usability state;
- visit counts;
- survivor/base/inventory state;
- active raid state if mid-raid saving is later supported.

The detailed 64×64 raid may continue to be generated from seed + visit state unless a specific raid needs persistent deltas.

## 15. Proposed ownership

When implemented, avoid putting travel rules into the presentation layer.

### New/changed owner: `TravelWorldState.gd`

Owns:

- travel depths/layers;
- destination nodes;
- foot ranges;
- staging anchor;
- gateway vehicle connections;
- current depth;
- deterministic travel graph generation;
- whether a node is strategically reachable.

This should replace the flat-world authority currently represented by `MiniWorldState.gd` once the migration is complete.

### `ExtractionRaidState.gd`

Continues to own:

- base/staging vs active raid;
- selected destination;
- active raid seed;
- visit sequence;
- extraction completion.

It should gain only the minimal staging-anchor information required to return to the correct layer after extraction, or query `TravelWorldState` for it. Do not duplicate travel graph truth here.

### Presentation

A future travel-map presentation renders `TravelWorldState` and sends requested deploy/gateway actions to the owning state objects. It does not calculate reachability itself.

### Local generation

`MiniRegionGenerator`/its successor remains responsible only for the generated tactical destination. It should not know about travel depth except for explicit destination-generation parameters passed in from higher-level state.

## 16. Migration from the current build

The current build should be changed in this order when implementation begins:

1. **Do not first rewrite tactical generation.** Build the travel-state model and map semantics so the game knows what a destination means.
2. Replace flat any-cell deployment with reachability from the current staging anchor.
3. Add travel depth/page state.
4. Add a debug vehicle gateway and prove descend/return semantics.
5. Change extraction return so deeper raids return to the parked vehicle staging layer rather than directly to base.
6. Then rewrite focused raid composition away from road-grid dominance toward destination-sized POIs.
7. Only after that add vehicle acquisition/fuel/repair progression.

This ordering prevents another generator rewrite around travel rules that are still moving.

## 17. First implementation acceptance criteria

The first coded version of this design is successful when all of the following are true:

1. The game begins at Depth 0 with BASE as the staging anchor.
2. Only nearby nodes are selectable for foot deployment.
3. Farther nodes are visible but unavailable without a gateway.
4. Selecting a reachable node commits a deterministic travel cost and creates one focused tactical raid.
5. Successful extraction returns to the same strategic staging anchor that launched the raid.
6. A usable vehicle gateway can transition from Depth 0 to Depth 1.
7. Depth 1 has its own deterministic set of nearby destinations.
8. The arrival vehicle is clearly represented as the guaranteed return gateway to Depth 0.
9. Reusing that vehicle returns to the exact prior layer/anchor rather than generating an unrelated map.
10. At least one additional deeper gateway can prove the architecture can reach Depth 2.
11. Same world seed produces the same travel layers, node identities, gateway links, and site seeds.
12. Same destination + same visit sequence produces the same raid seeds.
13. Tactical maps remain one active 64×64 destination at a time.
14. Commercial/residential/office/woods/rural raids no longer need a full-map road network.
15. No travel UI inspection advances time by itself.
16. No actual audible game sound is introduced.

## 18. Non-goals for the first implementation

Do not add these merely because vehicles are now part of strategic navigation:

- free tactical driving;
- vehicle physics;
- traffic simulation;
- fuel economy simulation before fuel exists;
- complex repairs before item/inventory systems exist;
- off-screen vehicle movement;
- giant continuous island rendering;
- random travel-event combat screens;
- multiplayer transport;
- survivor companions.

The vehicle is first and foremost a **persistent strategic gateway**.

## 19. Design summary

The new world model is intentionally dungeon-like underneath its real-world fiction:

- **Base is the starting floor.**
- **Foot range defines the rooms you can reach from the current landing.**
- **Raid sites are the rooms.**
- **Extraction returns you to the landing.**
- **Vehicles are stairs.**
- **Farther travel layers are deeper floors.**

This gives Tick Survival Lab a strong progression spine without sacrificing procedural generation or requiring a massive continuously rendered world.

The central rule is:

**Walk locally. Raid deeply. Use vehicles to move the expedition frontier outward.**
