# Extraction Raid Loop 0.6 Design

Status: current gameplay-direction contract. This document supersedes the seamless adjacent-region travel portions of `MINI_WORLD_STREETSCAPE_DESIGN.md` while retaining its compatible streetscape, building-family, art, and performance rules. `FOCUSED_RAID_INTERIORS.md` is the detailed current contract for local generator v6.

## 1. Core identity

Tick Survival Lab is structured as a **systemic extraction-survival game** rather than a seamless open-world walking simulation.

The player operates from a safe base/staging layer, chooses a broad destination from the full-screen world map, deploys into one fresh procedural tactical raid, completes whatever scavenging/objective/survival work exists there, and must physically reach an extraction point to return safely to base.

The immediate loop is:

**BASE → CHOOSE DESTINATION → GENERATE RAID → ENTER TACTICAL MAP → SURVIVE / SEARCH / OBJECTIVE → REACH EXTRACTION → BASE**

The map is therefore not a miniature continuously traversable world. It is a destination-selection layer for repeated tactical expeditions.

## 2. Why this structure

This solves several design and technical problems at once:

- every tactical map has a clear beginning and end;
- the player always has a reason to move through dangerous terrain instead of wandering indefinitely;
- risk/reward systems such as loot, injuries, noise, time, fatigue, infection, and encumbrance can all matter during the return trip;
- the game can generate dense, interesting locations without needing a giant persistent terrain surface;
- mobile Safari only renders the active local raid;
- persistent simulation can remain focused on meaningful actors/items rather than thousands of unloaded map tiles;
- destination type becomes an intentional strategic choice instead of a biome the player happens to walk into;
- because breadth is chosen on the destination map, the tactical generator can spend its limited 64×64 footprint on deeper structures and interiors rather than proving all biome types exist at once.

This is closer to an extraction shooter structurally, but combat is not required to be the only or even primary activity. Stealth, scavenging, rescue, investigation, survival, and objective completion can all use the same deploy/extract loop.

## 3. Base / staging state

For the current bootstrap, **base is represented by the full-screen destination map**, not yet by a physical buildable base scene.

At base:

- tactical movement is disabled;
- simulation does not advance merely because the player is inspecting destinations;
- the player can tap/click any valid destination cell to deploy;
- the same destination may be raided repeatedly;
- every repeat deployment rolls a fresh deterministic raid seed;
- future systems may add inventory loadout, survivor choice, healing, crafting, storage, vehicles, and mission preparation here.

A physical home/base map can be added later without changing the raid-session state contract.

## 4. Destination map

The existing 5×5 mini-world remains, but its cells are **raid sites**, not adjacent traversable regions.

Current destination identities:

- **Commercial** — shops, strip malls, parking lots, storefronts;
- **Downtown** — offices, civic/commercial structures, denser streets;
- **Residential** — houses, duplexes, estate houses, neighborhood streets;
- **Woods** — woodland/trail environments;
- **Rural** — trailers, farmhouses, sparse roads and utility infrastructure.

The 5×5 layout exists to provide variety and readable destination choice. It does not imply that the player can walk from one cell directly into its neighbor.

The map remains:

- full-screen only;
- available with `MAP` / keyboard `M`;
- touch-first and Safari-safe;
- zero-tick to inspect.

## 5. Raid generation

Every deployment gets a raid seed derived from:

- world seed;
- selected destination's stable site seed;
- destination coordinate;
- number of times that destination has been deployed to.

Therefore:

- the same world + same sequence of destination choices is deterministic;
- repeated raids to the same commercial/residential/woods/etc. site produce different tactical maps;
- starting a new world seed changes the destination catalog and raid sequence;
- CI can reproduce an exact raid by seed.

`MiniRegionGenerator` **v6** is the current local raid generator. The selected destination identity is passed in as the generation focus.

The v6 pipeline is:

**v4 physical/road baseline → destination-focus cleanup → large focused shell composition → streetscape/building-family specialization → functional interior depth**

The old v4 mixed-biome structure population is not the final content authority anymore. Incompatible legacy buildings are removed before focused content is added, and the broad biome identity is normalized to the selected destination.

## 6. Raid-session state owner

`ExtractionRaidState.gd` owns the high-level session mode:

- `base` or `raid`;
- active destination coordinate;
- current raid seed;
- last raid seed;
- total raid serial;
- deployment count per destination;
- successful extraction count.

Presentation may display this state but must not invent a second copy of it.

The destination catalog remains owned by `MiniWorldState.gd`.

The local physical map remains owned by the existing generator/world-state stack.

## 7. Deployment semantics

Selecting a destination while at base:

1. validates the selected map cell;
2. advances that destination's deployment count;
3. derives a fresh raid seed;
4. generates one 64×64 tactical map using the destination identity;
5. loads that map into `LocalWorldState`;
6. places the survivor at the generated raid spawn;
7. closes the destination map and begins tactical play.

Bootstrap deployment selection itself costs zero authoritative ticks because the travel between base and raid site is currently abstracted rather than simulated.

When vehicles, fuel, distance, travel events, or needs during transit become real systems, deployment travel can gain an explicit authoritative cost without changing this state machine.

## 8. Extraction semantics

The generated edge exits become **extraction points**.

Current rule:

> A raid ends successfully when the player physically steps onto any green generated edge extraction cell.

Extraction:

- uses the normal movement tick cost for the final step;
- preserves authoritative world/calendar progression from the raid;
- returns the raid session to `base` mode;
- reopens the destination map;
- prevents direct transition into another tactical region;
- allows a new destination to be selected only after returning to base.

The player may open the destination map during a raid, but it is view-only until extraction.

## 9. Failure / death direction

Not implemented yet, but the intended extraction logic is:

- successful extraction carries acquired persistent results back to base;
- death or catastrophic failure does not count as extraction;
- later, dropped gear/corpse/world consequences may remain associated with the failed raid seed;
- a future rescue/recovery raid could potentially revisit persistent failed-raid state if that proves fun.

No fake inventory/loot loss is added before inventory exists.

## 10. Tactical map requirements

Generator v6 retains the useful v5 streetscape rules while making the raid much more destination-specific.

Current global physical/content rules:

- traffic controls/street furniture use the existing streetscape system;
- commercial parking has destinations;
- strip malls have separated units/doors;
- residential destinations can produce houses, duplexes and estate houses;
- rural/woods generation can produce trailers/farmhouses/cabin-like structures and sparse infrastructure;
- no three-door procedural runs;
- all buildings remain single-story;
- tactical zoom remains 14×12 / 12×10 / 10×9 performance-safe local detail.

The extraction loop changes navigation semantics, not the physical map schema.

## 11. Focused destination depth

A raid no longer needs to contain a little bit of every world environment. The destination map already gives the player that choice between raids.

V6 therefore prefers fewer, larger focus-appropriate interiors when free geometry allows it. Current candidate anchor sizes reach roughly 14×11 for residential and 18×12 for commercial/office destinations.

Functional room vocabulary currently includes:

### Commercial / store

- sales floor;
- checkout/retail fixtures;
- **manager office**;
- **back stockroom**;
- refrigeration/shelving/storage fixtures.

### Downtown / office

- reception;
- open office;
- **manager office**;
- storage/file room;
- meeting room;
- desks/computers/cubicles/filing fixtures.

### Residential

- living room;
- kitchen;
- primary bedroom;
- bathroom;
- appropriate domestic furniture/fixtures.

### Mansion / estate house

- living room;
- kitchen;
- primary bedroom;
- secondary bedroom where footprint supports it;
- bathroom.

### Duplex

Each sealed unit contains internal living/kitchen and bed/bath zones instead of being one undifferentiated rectangle.

### Strip mall

Each storefront has a public sales zone plus rear depth. One unit supplies a manager office; other units can contain rear stockrooms.

### Trailer

Compact living/kitchen and bed/bath zones.

These room names are generation/content facts only. Loot/searchability does not exist until the later loot/inventory owner consumes this vocabulary.

The detailed contract is in `FOCUSED_RAID_INTERIORS.md`.

## 12. Future destination weighting

The broad destination type should eventually affect **probability**, not hard guarantees for every item/event.

Examples:

- commercial: packaged food, retail goods, medicine stores, tools, crowds/infected density;
- downtown/offices: electronics, records, office supplies, dense interiors, security/access problems;
- residential: food, clothing, personal medicine, household tools, survivor stories;
- woods: natural concealment, cabins/camps, fewer manufactured resources, wildlife;
- rural: fuel, tools, farm supplies, larger outdoor spaces, trailers/farmhouses.

Those loot/population rules do not belong in the generator until their owning systems exist.

## 13. Objective direction

Extraction alone is enough for the current proof. Later raids can layer objectives on top of the same loop:

- scavenge until satisfied and leave;
- recover a specific item;
- rescue/retrieve a survivor;
- investigate a location;
- activate/repair infrastructure;
- clear/access a route;
- retrieve a corpse/cache;
- deliver or place something;
- survive a timed task.

Objectives should create reasons to penetrate deeper into the map rather than merely sprint from spawn to extraction. Functional back rooms, manager offices, storage rooms and bedrooms provide natural future objective/search destinations.

## 14. Persistence direction

The architecture reduces the immediate need for 25 simultaneously persistent terrain regions.

Near-term persistence can focus on:

- base state;
- survivor state;
- inventory/equipment;
- world calendar/weather/outbreak state;
- destination visit history;
- current active raid if saving mid-raid becomes necessary.

Long-term persistent raid deltas are optional and should be added only when they create gameplay value.

## 15. Validation contract

Permanent CI must prove:

- deterministic 5×5 destination catalog;
- all five destination identities exist;
- local v6 generation remains valid;
- focused raid biome identity does not leak back into the old five-biome mixture;
- incompatible legacy building themes are removed;
- developed raids contain the current larger anchor requirement;
- commercial room grammar includes manager-office + stockroom depth;
- downtown room grammar includes office/reception + manager-office depth;
- residential room grammar includes living + kitchen + bedroom + bathroom purpose;
- extraction session resets to base;
- a raid cannot be redeployed while another raid is active;
- same world + same visit sequence yields the same raid seeds;
- repeat deployment to one destination yields a different raid seed;
- generated raid maps expose four edge extraction cells;
- all existing map/tick/calendar/environment/perception tests remain green.

## 16. Acceptance criteria

The current extraction shell is functionally present when the player can:

1. launch into a safe destination-map state;
2. tap a commercial, downtown/office, residential, woods, or rural site;
3. receive a freshly generated tactical raid matching that destination rather than a five-biome sampler;
4. encounter larger and more purposeful destination interiors where geometry permits;
5. move normally inside the raid;
6. open the map during the raid only for inspection;
7. reach a green extraction cell;
8. step onto it and return to the safe destination map;
9. choose another destination or choose the same destination again;
10. get a newly seeded tactical map on the next deployment;
11. never walk directly from one raid map into an adjacent destination.

## 17. Next gameplay work

Once this deploy/extract + focused-generation loop is playtested, the next systems should make the loop meaningful rather than make the world larger:

1. spatial silent sound visualization;
2. infected actors using sight + sound;
3. searchable containers / loot / inventory;
4. extraction retention and failure consequences;
5. combat / body injury;
6. richer raid objectives and destination-specific content;
7. physical base/hideout only when there is enough inventory/survivor progression to justify it.

The key rule remains:

**The world map chooses risk. The tactical map contains the risk. Extraction is how progress comes home.**
