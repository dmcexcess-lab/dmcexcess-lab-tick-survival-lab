# Tick Survival Lab — Modular Rebuild Master Design

Status: **canonical design for the next rebuild.**

This document replaces the clean-reboot architecture as the implementation target. The current `game/scripts/reboot/` runtime is a frozen reference only until the modular rebuild replaces it. Do not extend the reboot architecture merely because it is currently playable.

The goal of this document is not just to describe the game. It exists to make future rewrites safe. A generator rewrite must not change rendering. A renderer rewrite must not change player movement. A strategic-map rewrite must not change tactical generation. Each subsystem gets an explicit owner, data contract, and test surface.

The most important rule is:

> **Main is composition, not implementation. Every gameplay, rendering, input, generation, UI, persistence, validation, and simulation responsibility lives in its own standalone script/module.**

Where practical, a module should expose one primary responsibility. Private helper functions may exist inside a tightly scoped module, but no script may become a grab bag of unrelated systems.

---

## 1. Why another rebuild is necessary

The pre-rewrite prototype had many systems that worked well and had a much richer visual presentation, but its presentation harness became too large and inherited too many responsibilities. The clean reboot correctly tried to reduce complexity, but it made two serious architectural mistakes:

1. it replaced the known-good renderer/art-selection behavior with a simplified approximation instead of recovering the exact old visual system;
2. it allowed `RebootMain.gd` to absorb tactical rendering, strategic-map drawing, controls, zoom, input routing, prefab orchestration, power-line presentation, site loading, and UI geometry.

That means a request to change one thing increasingly risks changing several unrelated things. This is specifically what this rebuild must eliminate.

The old prototype is therefore neither something to restore wholesale nor something to ignore. It is a **recovery mine**: preserve the solved art, algorithms, data semantics, and tested subsystem rules; reject its monolithic presentation structure.

The clean reboot is also a recovery mine: preserve the useful newer rural-generation lessons, hard doorway rules, event-driven performance work, prefab-authoring idea, and simplified player movement; reject its `RebootMain.gd` concentration of responsibilities and its replacement art catalog.

---

## 2. Golden recovery baseline

The last pre-clean-rewrite build to use the mature presentation/art stack is commit:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

Commit title: `Document focused raid interiors v6`.

This commit is the **visual/system archaeology baseline**, not the architecture to copy wholesale.

### 2.1 The artwork was not lost

The important art files on current `main` are byte-identical to the golden baseline. Their Git blob hashes match.

| Asset | Golden/current blob SHA | Status |
|---|---|---|
| `game/assets/tactical_atlas.svg` | `a031ac456a7d92b7fbf2d6e4d625c3a30e749a4f` | PRESERVE EXACT |
| `game/assets/clutter_atlas.svg` | `966c9de04ad84d05d6203cc4e078f2fad07c03d4` | PRESERVE EXACT |
| `game/assets/world_art_atlas.svg` | `995e52973e14db0ef60f3562c1cfa5ae342d62d2` | PRESERVE EXACT |
| `game/assets/building_props_atlas.svg` | `856be2fc90d009d1b4bcc565990b9428323bb4d6` | PRESERVE EXACT |
| `game/assets/final_environment_surfaces_atlas.svg` | `a42607858bae04f25fb1c6621a6d9262e81550b1` | PRESERVE EXACT |
| `game/assets/final_environment_props_atlas.svg` | `7714d8c95833e20ebca20cfa1374f23eaa5509f1` | PRESERVE EXACT |
| `game/assets/player_north.svg` | `dfeb5be1c9cc0b66aec842d969b60b485d3a4f99` | PRESERVE EXACT |
| `game/assets/player_east.svg` | `76c3e7e1a3b07712c65b385f1d80e131b45d90b3` | PRESERVE EXACT |
| `game/assets/player_south.svg` | `a2e358fd8fe15d497bf9559ae89835af0331d10f` | PRESERVE EXACT |
| `game/assets/player_west.svg` | `c2cc192efed4c4a81905eb0d8100cd4776d4731b` | PRESERVE EXACT |

Do not regenerate, substitute, reinterpret, or silently replace these assets during the modular rebuild. If art is intentionally changed later, that is a separate explicit art task.

### 2.2 What actually produced the old graphics

The mature pre-rewrite look was not one atlas. `TacticalTiles.gd` at the golden commit (`3d8a0a70ac983408bb48f58fc659dfb07e216ed3`) was a semantic art catalog plus draw helper that combined six atlases and the four player-facing sprites.

It knew, for example:

- when ordinary ground should come from the tactical atlas;
- when road topology should come from `world_art_atlas.svg`;
- when a richer final environment surface should replace a generic ground name;
- which wall theme came from tactical, world, or final-surface art;
- which door/window theme used a world-art opening versus the tactical fallback;
- whether a prop should come from the tactical, clutter, building-prop, or final-prop atlas;
- how road connectivity selected straight/corner/T/cross/end-cap sprites;
- which directional player sprite matched facing.

That semantic selection behavior is what must be recovered. The clean reboot preserved the files but replaced much of this selection logic, which is why the game looked different despite using files with the same names.

### 2.3 Recovered module/code inventory

The following golden-baseline modules contain useful solved work. Their code must be inspected and deliberately classified during implementation rather than re-created from memory.

| Golden module | Golden blob | Rebuild treatment |
|---|---|---|
| `TacticalTiles.gd` | `3d8a0a70ac983408bb48f58fc659dfb07e216ed3` | RECOVER semantic mappings and draw behavior; split into art catalog + layer renderers |
| `LocalWorldState.gd` | `f8fd11ebbf0ff2b3958fd46000404cbb12142fc5` | PORT/VERIFY mutable door/collision facts |
| `PlayerActor.gd` | `2f839f1a50041c8bd00e144c1a9389d0a33d1401` | PORT desired movement/facing semantics into smaller player modules |
| `TickScheduler.gd` | `0d1efa7f76ca58a0357fd9a3d0703320b2ad8d69` | DEFERRED BUT SOLVED; port behind stable action interface later |
| `WorldCalendar.gd` | `c4b5e5547414ec689703173ab3ccc4b0ce037cb2` | DEFERRED BUT SOLVED; port later |
| `TacticalLighting.gd` | `b606b5e634bb8b6bee1ac998734b6c5cfc3bfd20` | DEFERRED BUT SOLVED; port later as standalone simulation module |
| `TacticalPerception.gd` | `d73660aa17e1b344dd8f3b16f391ec5b4967c0a3` | DEFERRED BUT SOLVED; port later after lighting/facing |
| `TacticalWeather.gd` | `6840c65032f2e8656a2623133c141560741574c0` | DEFERRED BUT SOLVED; separate weather state from weather VFX |
| `TacticalSound.gd` | `50ac2632e6bd4071bdde20c725b19081cb6af160` | DEFERRED BUT SOLVED; preserve silent spatial-sound design |
| `SafariInputGuard.gd` | `c9174a97acb554dc15e4c3885b6c97cff11c628b` | PORT/VERIFY Safari touch/mouse de-duplication |
| `ExtractionRaidState.gd` | `8f08bffae042843fa2ff5d12d397f78b4241566b` | PORT CONCEPT; rewrite around new static strategic travel state |
| `StreetscapePass.gd` | `906f7fd7b3616bddb42576d66c757a20dbb503d3` | MINE FOR generation rules, families, civic placement; do not restore chain architecture |
| `DestinationInteriorPass.gd` | `297262c24a753d59422e09f6905f178bfe377830` | MINE FOR room/furniture ideas; replace with modular prefab/room systems |
| `ProceduralRegionGenerator.gd` | `3866acae031c19b75cd19ceb5356d8740fe09c09` | MINE FOR algorithms/data only; do not restore as master generator |
| `MapPreview.gd` | `8ef5d900e5f56bb557bba496d10acc47438b38de` | DO NOT RESTORE ARCHITECTURE; inspect for recovered behavior only |
| `MapPreviewPresentation.gd` | `cd70e604d7b0e78d88d55aa32d13e614f1da60a0` | DO NOT RESTORE ARCHITECTURE; recover visual behavior into separate views/renderers |
| `MiniWorldPresentation.gd` | `4e2d9830be1c80e3642464d8493279d2adebbc32` | DISCARD travel architecture; mine zoom/performance lessons |
| `ExtractionWorldPresentation.gd` | `3c9296860e418ce2f6c6b982636a04dcff4b38c9` | DISCARD presentation inheritance; port only extraction semantics if still applicable |

The old `MapPreview.gd` was itself large and multi-purpose. It is evidence that the old visuals worked, not a template for the new architecture.

---

## 3. Non-negotiable modular architecture

### 3.1 Main/root rule

`Main.gd` (or the root scene script replacing it) is allowed to do only application composition:

- obtain references to child modules/services;
- pass dependencies/configuration;
- connect high-level signals;
- choose the initial high-level mode/controller;
- perform minimal startup/shutdown bookkeeping.

It must **not** contain:

- `_draw()` gameplay rendering;
- `_unhandled_input()` action logic;
- touch-button hit testing;
- keyboard mappings;
- zoom calculations;
- camera calculations;
- map generation;
- road generation;
- building generation;
- prefab placement;
- player movement/collision rules;
- strategic map layout/drawing;
- tactical HUD drawing;
- art/atlas selection;
- extraction rules;
- persistence/serialization;
- weather/lighting/perception/sound;
- validation rules;
- UI geometry constants for subsystem screens.

If a behavior can be named as a system, it gets its own script.

### 3.2 One responsibility per module

The target is not merely “several files.” The target is **replaceability**.

A module should answer one question. Examples:

- `RoadLayoutGenerator`: where are roads?
- `PropertyPlanner`: where are properties relative to roads?
- `PrefabPlacer`: can this prefab fit here and where?
- `DoorGeometryValidator`: are openings physically valid?
- `ArtCatalog`: what visual source represents semantic ID X?
- `GroundLayerRenderer`: draw ground cells.
- `StructureLayerRenderer`: draw walls/doors/windows.
- `PlayerMovement`: can the player enter this cell and update position?
- `ZoomController`: which camera preset is active?
- `StrategicMapView`: render the static travel map and nodes.

Private helper methods inside one responsibility are fine. Mixing separate responsibilities is not.

### 3.3 Stable contracts are more important than inheritance

Avoid deep presentation inheritance like:

`MapPreview -> MapPreviewPresentation -> MiniWorldPresentation -> ExtractionWorldPresentation`.

Prefer composition and small interfaces/data objects.

Systems communicate by:

- typed data Resources/RefCounted records;
- explicit method calls through narrow interfaces;
- signals for state changes and user intents.

Do not make one module reach into another module's internal dictionaries or UI state.

### 3.4 Rewrite isolation guarantee

The architecture must make these statements true:

- deleting and rewriting `generation/` cannot change art, player sprites, camera, controls, strategic map, or renderer;
- deleting and rewriting `render/` cannot change map generation, collision facts, travel state, or player state;
- deleting and rewriting `input/` cannot change simulation rules;
- deleting and rewriting `strategic/` cannot change tactical raid generation;
- replacing the art catalog cannot change physics;
- adding vision/lighting/weather later cannot require edits to the generator beyond semantic metadata already in the map contract.

A rebuild phase is not complete until these boundaries are demonstrably true.

---

## 4. Canonical folder/module plan

Names may change slightly during implementation, but responsibility boundaries should not.

```text
game/
  main.tscn
  scripts/
    app/
      Main.gd                     # bootstrap/wiring only
      GameFlowController.gd       # high-level strategic <-> raid mode transitions
      ServiceRegistry.gd          # optional dependency registry, no gameplay rules

    data/
      RaidRequest.gd              # biome/site/seed request
      RaidMapSpec.gd              # complete semantic tactical map data
      CellPhysics.gd              # movement/opacity/interaction facts
      BuildingRecord.gd
      RoomRecord.gd
      DoorRecord.gd
      PrefabRecord.gd
      StrategicNode.gd
      TravelState.gd

    art/
      ArtCatalog.gd               # recovered TacticalTiles semantic mappings
      ArtSource.gd                # atlas/source descriptor
      ArtBaselineManifest.gd      # optional code-visible immutable baseline IDs

    render/
      TacticalRenderer.gd         # layer orchestration only
      GroundLayerRenderer.gd
      StructureLayerRenderer.gd
      PropLayerRenderer.gd
      PlayerRenderer.gd
      PowerLineRenderer.gd
      ExtractionMarkerRenderer.gd
      LightingOverlayRenderer.gd  # later
      WeatherVfxRenderer.gd       # later
      PerceptionOverlayRenderer.gd# later

    camera/
      TacticalCameraState.gd
      ZoomController.gd
      ViewportCellCalculator.gd

    input/
      InputRouter.gd
      TouchInputAdapter.gd
      KeyboardInputAdapter.gd
      SafariInputGuard.gd
      ActionIntent.gd

    player/
      PlayerState.gd
      PlayerMovement.gd
      PlayerFacing.gd
      PlayerActionCosts.gd        # later tick integration

    world/
      LocalWorldState.gd
      CollisionQuery.gd
      DoorState.gd

    strategic/
      StrategicMapState.gd
      StrategicMapView.gd
      StrategicMapInput.gd
      TravelRangeRules.gd
      VehicleGatewayState.gd
      StaticMapDefinition.gd

    raid/
      RaidSessionState.gd
      RaidController.gd
      ExtractionRules.gd

    generation/
      RaidGenerator.gd            # coordinator only
      BiomeRuleCatalog.gd
      SiteCompositionPlanner.gd
      roads/
        RoadLayoutGenerator.gd
        RoadTopology.gd
        SideRoadGenerator.gd
      parcels/
        PropertyPlanner.gd
        PropertyAccessPlanner.gd
      prefabs/
        PrefabCatalog.gd
        PrefabSelector.gd
        PrefabPlacer.gd
        PrefabTransform.gd
        PrefabValidator.gd
      buildings/
        ProceduralBuildingSelector.gd
        RoomGraphGenerator.gd
        RoomLayoutSolver.gd
        DoorPlanner.gd
        DoorGeometryValidator.gd
      dressing/
        FixturePlanner.gd
        FurniturePlanner.gd
        ClutterPlanner.gd
        VegetationPlanner.gd
        UtilityNetworkPlanner.gd
        CivicPropPlanner.gd
      extraction/
        ExtractionPlacement.gd
      validation/
        RaidMapValidator.gd
        RoadValidator.gd
        BuildingValidator.gd
        AccessibilityValidator.gd
        BiomeQualityValidator.gd

    prefabs_dev/
      PrefabBuilderController.gd
      PrefabBuilderView.gd
      PrefabPalette.gd
      PrefabSerializer.gd
      PrefabStorage.gd
      PrefabPreviewRenderer.gd

    ui/
      TacticalHudView.gd
      TacticalControlsView.gd
      MapButtonView.gd
      DevMenuView.gd

    time/                         # later recovered subsystem
      TickScheduler.gd
      ActionExecution.gd
      WorldCalendar.gd

    perception/                   # later recovered subsystem
      TacticalLighting.gd
      TacticalPerception.gd
      TacticalSound.gd
      TacticalWeather.gd

    ci/
      ... one smoke/contract test per subsystem ...
```

The exact count of scripts is intentionally high. That is a feature: no future request should require understanding the whole game to change one system.

---

## 5. Core data separation: semantic world, art, and physics

This is the most important technical boundary after modularity.

### 5.1 Generator outputs semantic IDs, never sprite indices

Generation must never know atlas coordinates or texture paths.

Bad:

`walls[cell] = 18`

Good:

`surface_id = "wall.house_siding"`

Bad:

`props[cell] = FINAL_PROP[67]`

Good:

`object_id = "fixture.kitchen_sink"`

The renderer asks `ArtCatalog` how that semantic ID is drawn.

This is the contract that prevents a generator rewrite from changing graphics.

### 5.2 Art is not physics

Recover the old `ART_VOCABULARY.md` rule exactly:

> **Art is not physics.**

A sprite does not decide whether a cell is blocked, opaque, searchable, interactable, destructible, lootable, powered, or persistent.

`RaidMapSpec` stores physical facts separately from presentation IDs.

Examples:

- wall record: visual ID + blocked + opaque;
- window record: visual ID + blocked + light/vision transmission;
- door record: visual ID + axis + open/closed + blocked state;
- prop record: visual ID + blocking/opaque/interaction tags.

### 5.3 Inventory items are not loose world art

Preserve the old art rule: ordinary inventory items do not need floor sprites. The tactical world shows terrain, structures, furniture, fixtures, vegetation, civic infrastructure, environmental clutter, and large physical objects. Searchable contents are data/UI later.

---

## 6. Game identity and core loop

Tick Survival Lab remains an original top-down grid-based zombie-apocalypse survival/extraction simulation in Godot 4.

The current geographic/gameplay direction is:

**STATIC STRATEGIC MAP -> REACHABLE DESTINATION -> GENERATED TACTICAL RAID -> EXPLORE/SURVIVE/LOOT LATER -> PHYSICAL EXTRACTION -> RETURN TO STAGING -> EXTEND ROAMING RANGE TOWARD THE CITY.**

The strategic map represents a real broad geography from rural outskirts toward a city, but it is presentation/navigation rather than a seamless tactical surface.

### 6.1 Geographic progression

Broad progression runs:

1. **Rural edge / farms / sparse housing**
2. **Small towns**
3. **Suburbs**
4. **City edge / commercial-industrial fringe**
5. **City center / dense urban core**

This is not a linear RPG difficulty ladder. Deeper access means farther travel, different opportunities, denser/specialized sites, and greater logistical commitment.

### 6.2 Foot travel first

The survivor begins with a limited roaming radius on foot. Only nearby strategic nodes are reachable.

Strategic travel can initially be abstract rather than simulated tile-by-tile, but later it must cost authoritative time/fatigue/etc. through the owning systems.

### 6.3 Vehicles are “stairs”

Vehicles initially function as strategic gateways rather than a tactical driving simulator.

A usable vehicle:

- expands the survivor's reachable region toward deeper city bands;
- acts like a dungeon staircase between strategic travel depths/anchors;
- establishes a farther staging anchor;
- remains the clear route back to the previous layer/anchor.

Fuel, damage, trunks, repair, capacity, and actual driving can be added later without changing the gateway architecture.

### 6.4 Extraction

A raid ends by physically reaching a valid extraction point. Extraction returns the survivor to the staging anchor that launched the raid: base at home range, or a parked vehicle/deeper anchor later.

No fake loot-retention or failure rules should be invented before inventory/death systems exist.

---

## 7. Static strategic map

The strategic map should ultimately be a static authored image/background with interactive node overlays, not procedurally generated tactical-looking geography.

Separate modules own:

- the background/static map definition;
- node/world state;
- travel reachability;
- map rendering;
- map input;
- deployment/travel action requests.

The strategic map may visually show roads, settlements, farms, suburbs, and city center, but those visual marks do not themselves generate tactical layouts.

A node contains semantic information such as:

- ID;
- geographic band;
- destination/site tags;
- world/site seed;
- display position on static map;
- current reachability;
- visit count;
- optional vehicle-gateway relationship;
- discovered/known state later.

On mobile/Safari, nodes and actions must be large tap targets with no hover dependency.

---

## 8. Tactical map philosophy

A tactical raid represents **one coherent sample of a place**, not a miniaturized whole region and not a stress test that includes every biome.

The map may remain 64x64 initially because that scale is already proven, but composition—not raw size—is what matters.

Global rules:

- one coherent biome/site context per raid;
- one or a few believable property clusters rather than dozens of tiny buildings;
- roads support the location rather than consuming the map;
- buildings are large enough to contain believable rooms but not giant empty boxes;
- meaningful exterior approach/concealment/extraction space;
- furniture/fixtures obey room function;
- clutter never blocks critical doors/circulation without an intentional rule;
- every layout must remain physically navigable;
- variation comes from site composition, prefab selection, road form, parcel positions, dressing, and optional procedural detail—not random incoherence.

---

## 9. Rural-edge biome — first implementation target

The rural edge is the first biome to rebuild and polish before adding Small Town.

This section captures the latest desired direction. Examples are **composition examples, not rigid quotas**.

### 9.1 Overall read

A rural raid should look like a sample of a real rural road:

- lots of grass;
- many trees, bushes, scrub, weeds and field/yard vegetation;
- one two-lane main road crossing/curving through the sample;
- small dirt/gravel roads and driveways branching from the main road;
- frequent utility poles and visible power-line runs along developed road sections;
- stop signs where intersections warrant them;
- few or no traffic lights;
- sparse residential/commercial development rather than dense city parcels.

### 9.2 Road variety

The road-layout module should support weighted patterns such as:

- straight rural two-lane road;
- gentle/stepped bend that reads as a curve at tile scale;
- crossroads;
- later T-junction or offset intersection where useful.

The road network is generated before properties. Property access planners connect drives/side roads to it.

Roads are protected semantic ground and cannot be painted over by later property/field/furniture passes.

### 9.3 Property composition

Typical example composition:

- one farm complex;
- one or two substantial rural houses;
- one or two trailers/double-wides;
- zero or one small roadside gas station/convenience/corner store normally, with a maximum of two only when composition has room.

This must remain a weighted grammar, not a hard formula. A seed can vary the mix while still reading unmistakably rural.

No strip mall belongs in this band.

### 9.4 Farm complex

A farm complex can include:

- medium/large farmhouse;
- barn;
- shed/workshop;
- field/garden/hay/crop context;
- fences;
- dirt/gravel drive;
- propane/utilities;
- equipment/environmental clutter;
- tree line or windbreak.

The farmhouse should contain multiple believable rooms without making every room huge.

### 9.5 Rural houses/manufactured homes

Possible families:

- farmhouse;
- country house;
- small trailer;
- double-wide;
- later ranch-style or other variants.

Manufactured homes should read as manufactured homes through footprint and room arrangement, not simply a renamed square house.

### 9.6 Roadside business

Rural businesses are compact gas stations/convenience/corner stores.

Desired scale rule:

- large public rooms such as a storefront generally around **5x5 to 7x7 usable cells**;
- ordinary support rooms generally around **3x3 usable cells**;
- avoid long empty warehouse-like interiors unless the site type specifically calls for them.

Example corner store grammar:

- 5x5 or 7x7 storefront;
- 3x3 stock room;
- roughly 3x3 manager/office support space;
- 3x3 bathroom;
- optional rear service/loading strip where footprint supports it.

Gas station adds compact pumps/forecourt/signage without becoming a giant parking lot.

### 9.7 Fixture/furniture rules

Installed things must look installed.

Examples:

- sinks against wall/plumbing planes;
- stoves/ranges along kitchen walls unless a deliberate island/range design exists;
- refrigerators against walls/cabinet runs;
- toilets/vanities/tubs/showers against bathroom walls;
- beds against walls with usable approach;
- TVs placed so seating can plausibly face them;
- store shelves make aisles rather than random clusters;
- checkout belongs near public entrance/exit flow;
- stockroom pallets/racks stay out of door circulation;
- office desks/chairs/file storage form a recognizable work space.

### 9.8 Clutter rules

Clutter has layers:

1. functional fixtures;
2. room-edge clutter;
3. environmental scatter;
4. authored/procedural story stamps.

Never scatter clutter blindly into walkable space after layout is complete.

Door cells and required door-approach/circulation cells are hard reservations.

### 9.9 Door geometry rule

Preserve the strongest clean-reboot lesson.

Every door has an authoritative wall axis.

- horizontal-wall door: north/south approaches clear, left/right remain wall structure;
- vertical-wall door: east/west approaches clear, up/down remain wall structure.

A door cannot exist at a perpendicular wall crossing/T-junction. Later walls, windows, fixtures, vegetation, or clutter cannot occupy the reserved opening/approach area.

All functional procedural rooms should normally be at least **3x3 usable cells** unless a later explicit design allows a special smaller space.

---

## 10. Later biome grammar

Do not implement these until Rural Edge is consistently good, but the architecture must already allow them as independent biome rule modules.

### Small Town

- compact main street;
- detached local stores/service buildings;
- diners/convenience/local offices;
- houses closer together;
- duplexes and small apartment-like single-story footprints where appropriate;
- civic details;
- modest road/parking rather than suburban sprawl.

### Suburbs

- denser residential neighborhoods;
- subdivisions/loops/cul-de-sacs;
- larger houses and duplexes;
- yards, garages/sheds/fences;
- occasional strip mall or office property;
- more sidewalks/streetlights than rural.

### City Edge

- commercial corridors;
- larger plazas and offices;
- warehouses/service sites;
- mixed dense housing;
- alleys/loading/service access;
- more infrastructure and road complexity.

### City Center

- densest urban grammar;
- offices/storefront blocks;
- tight sidewalks/alleys;
- larger institutional/commercial interiors;
- minimal meaningless grass;
- later verticality only if explicitly designed; single-story remains acceptable for the initial system.

---

## 11. Prefab system — authored and procedural content meet here

The prefab system remains a strong idea, but the clean-reboot implementation is not architecture to preserve.

### 11.1 Prefab is data

A prefab is a portable semantic data record, not GDScript and not raw atlas indices.

It may contain:

- semantic ground cells;
- walls;
- doors with axes;
- windows;
- props/fixtures;
- physical blocking/opacity metadata where exceptional;
- footprint bounds;
- frontage direction/entrance anchors;
- site type tags (`house`, `trailer`, `store`, `barn`, etc.);
- allowed biome/band tags;
- required road/drive relation;
- room tags/room rectangles or room cell sets;
- optional utility/service anchors;
- optional clutter anchors;
- allowed rotation/mirroring flags.

### 11.2 Prefab builder modules

The in-game dev builder should be rebuilt from separate modules:

- builder controller;
- builder view;
- palette/tool definition;
- preview renderer using the same canonical tactical renderer/art catalog;
- validator;
- serializer;
- local storage;
- later import/export.

The builder must never implement its own substitute visual language.

### 11.3 Size

Maximum authorable footprint should be approximately **one far-zoom tactical window**. Resolve the exact cell dimensions from the canonical camera/zoom module at implementation time rather than hardcoding a stale size into editor logic.

SAVE trims unused outer rows/columns.

### 11.4 Generator integration

The generator does not “paint over” an existing site with arbitrary prefab data.

`PrefabPlacer` receives:

- a semantic prefab;
- candidate parcel/site anchors;
- rotation/mirroring options;
- clearance requirements;
- road/frontage requirements;
- current `RaidMapSpec`.

It either returns a valid placement or fails cleanly.

Authored prefabs can later participate as normal property families rather than always appearing as an extra sixth structure. Semantic tags/room metadata are what make that possible.

---

## 12. Generator pipeline

The generator should be a coordinator calling replaceable passes. No pass is allowed to draw.

Recommended pipeline:

1. `RaidRequest` created from strategic destination + raid seed.
2. `BiomeRuleCatalog` supplies rural/small-town/etc. composition rules.
3. `SiteCompositionPlanner` chooses broad property mix and density.
4. `RoadLayoutGenerator` generates main road topology appropriate to biome.
5. `SideRoadGenerator` adds only required secondary roads/paths.
6. `PropertyPlanner` allocates parcels/anchors relative to road/context.
7. `PrefabSelector` selects authored/built-in property templates by semantic tags.
8. `PrefabPlacer` stamps valid buildings/property footprints.
9. Optional procedural building modules fill content when prefab variation is insufficient.
10. `FixturePlanner` / `FurniturePlanner` place functional contents.
11. `ClutterPlanner` adds controlled environmental/story detail.
12. `VegetationPlanner` fills nature according to biome and reserved geometry.
13. `UtilityNetworkPlanner` creates poles/lines/boxes where appropriate.
14. `CivicPropPlanner` places stop signs/street furniture according to road class/biome.
15. `ExtractionPlacement` chooses valid extraction cells.
16. independent validators verify geometry, access, biome quality and content rules.
17. return `RaidMapSpec`.

If any step fails, the coordinator can retry with a derived deterministic sub-seed or fail clearly. Do not silently “repair” invalid maps by deleting arbitrary geometry after the fact.

---

## 13. Rendering architecture — recover the good graphics exactly

### 13.1 `ArtCatalog.gd`

Recover the golden `TacticalTiles.gd` semantic mapping behavior into a pure catalog/source resolver.

It owns:

- atlas paths;
- atlas grid/cell metadata;
- semantic ground IDs -> atlas source/index;
- wall themes -> source/index;
- door/window themes -> source/index;
- props/fixtures -> source/index;
- player-facing sprite references;
- legacy semantic aliases where still useful.

It does **not** know world coordinates, camera position, generator logic, player state, or game mode.

### 13.2 Layer renderers

Split drawing by layer so each can be replaced/tested independently.

`GroundLayerRenderer`
- semantic ground/surface IDs;
- road connectivity -> appropriate topology sprite;
- sidewalks/curbs/driveways/etc.

`StructureLayerRenderer`
- walls;
- doors/open state;
- windows;
- no physics mutation.

`PropLayerRenderer`
- furniture;
- fixtures;
- vegetation;
- civic/environment clutter.

`PlayerRenderer`
- only directional player visual.

`PowerLineRenderer`
- only static power-link presentation.

Later overlay renderers:
- lighting;
- fog/perception;
- weather VFX;
- sound markers.

`TacticalRenderer` merely establishes camera-visible cells and calls layer renderers in order.

### 13.3 Performance

Preserve the clean-reboot improvement:

- no idle tactical redraw when nothing animated is active;
- render visible cells only;
- sparse layers use O(1)-style lookup structures;
- when weather/lighting animation returns, only the relevant overlay redraw cadence should animate where possible;
- wide Safari zoom remains intentionally bounded.

---

## 14. Player, movement, camera, zoom, controls

These are foundational but separate.

### Player state

Owns only:
- cell;
- cardinal facing;
- later stance/movement mode/body state.

### Player movement

Consumes collision query + player state and performs:
- forward;
- backward;
- later side/interaction actions only when explicitly designed.

It does not know button rectangles or textures.

### Camera state

Owns:
- visible-cell window;
- camera origin centered/clamped around player;
- tactical board geometry independent of game UI.

### Zoom

Owns named presets. The old proven mobile-safe local presets were approximately:

- 14x12 @ 39 px;
- 12x10 @ 44 px;
- 10x9 @ 50 px.

Exact rebuild values can be verified against recovered renderer/Safari performance.

### Input

`TouchInputAdapter` knows touch buttons.

`KeyboardInputAdapter` knows keyboard convenience mappings.

`SafariInputGuard` handles synthetic mouse suppression.

Both emit semantic `ActionIntent`s to `InputRouter`. Neither directly moves the player.

Initial touch intent set:

- FORWARD;
- BACK;
- TURN LEFT;
- TURN RIGHT;
- MAP;
- ZOOM - / +;
- DEV/PREFAB BUILDER when present.

Crouch and interaction can return later as their owning actions return.

---

## 15. Recovered/deferred simulation systems

These systems were already substantially solved in the pre-rewrite build. They are **deferred, not forgotten**.

### Authoritative tick scheduler

Design to preserve:

- discrete world tick;
- player chooses while paused;
- committed action advances world time;
- other actors may act during player action;
- deterministic actor ordering;
- interruption policies: committed, resumable, canceled, forced-failure;
- phaseable long actions.

Do not re-add this until generator/player/render/input foundation is stable, but port from the golden implementation rather than reinventing it casually.

### Calendar

Recovered known mapping included 7,200 ticks/day and 5 ticks per displayed minute. Reverify when timing is restored.

### Vision/perception

Recovered desired system:

- cardinal facing/vision cone;
- LOS against physical opaque geometry;
- windows transmit sight/light;
- darkness affects usable visibility;
- fog-of-war memory;
- enemy intent/awareness later where applicable.

The user explicitly wants vision cone added back **later**, not in the first foundation rebuild.

### Lighting

Recovered physical lighting rules exist in `TacticalLighting.gd` at the golden commit. Port later as standalone simulation and rendering overlay modules.

### Weather

Recovered weather profiles include clear/rain/storm/fog/wind/snow plus visibility/light/sound-mask hooks and VFX. Weather state and weather rendering must be separate modules when restored.

### Sound

The game is intentionally **silent** unless this decision is explicitly reversed. Sound is simulation data communicated visually, including yellow spatial/noise markers. Do not add audible footsteps, zombie voices, gunshots, weather audio or music by default.

---

## 16. Validation and tests are architectural guards

Every module gets its own smoke/contract test where practical.

### 16.1 Architecture CI

Future CI should explicitly fail if `Main.gd` acquires forbidden responsibilities. At minimum:

- no `_draw` in Main;
- no `_unhandled_input` in Main;
- no atlas/texture references in Main;
- no generator implementation in Main;
- no button rectangles in Main;
- no world-state dictionaries in Main.

Main should remain small enough to audit at a glance.

### 16.2 Art baseline guard

CI should verify the immutable recovered art asset hashes while the baseline is frozen. Any intentional art change must update the manifest in a dedicated art task.

### 16.3 Renderer contract

Deterministic semantic map fixtures should prove:

- known semantic ground resolves to the same recovered atlas source/index;
- house/store/office/etc. wall/door/window themes reproduce the golden mapping;
- prop aliases resolve to the expected final/clutter/building atlas source;
- facing selects the correct directional player sprite.

### 16.4 Generator contract

Generator tests operate on semantic/physical data, never screenshots alone.

For Rural Edge, sample many seeds and assert ranges/quality such as:

- valid road topology;
- rural road coverage below a biome-appropriate ceiling;
- property count within allowed composition range, not one fixed hardcoded quota;
- farm/trailer/house/business families appear at intended frequencies over a seed suite;
- roads/side roads connect to properties;
- enough vegetation/open rural land;
- utility poles correlate with developed road frontage;
- sparse stop signs, no routine traffic lights;
- minimum room dimensions;
- every interior accessible;
- door-axis geometry valid;
- critical door approaches free;
- fixtures satisfy placement rules;
- no impossible overlaps.

### 16.5 Replaceability test

The best architectural test is practical: a mock generator should be swappable in without modifying renderer/player/input code. A mock renderer should be swappable in without modifying generator/player logic.

---

## 17. Implementation sequence

Do not rebuild everything at once.

### Phase 0 — this document / freeze

- freeze current reboot runtime as historical reference;
- make this document canonical;
- identify golden recovery commit/assets/modules;
- do not continue adding features to `RebootMain.gd`.

### Phase 1 — modular shell + recovered graphics

Build only:

- bootstrap-only Main;
- semantic data records;
- recovered `ArtCatalog` from golden `TacticalTiles`;
- split tactical layer renderers;
- player state/facing/movement;
- collision query;
- camera/zoom;
- touch/keyboard/Safari input modules;
- tactical controls view;
- static strategic map view/state.

Use a tiny authored test map first. **Do not write the new random generator until the recovered visuals are visibly confirmed against the old build.**

Acceptance criterion: the same old art stack visibly returns while Main remains only wiring.

### Phase 2 — Rural Edge generator

Implement semantic rural generator modules from scratch using the rules in this document.

Acceptance criterion: many seeds look like believable rural road samples and generator replacement does not change any visual/input/player module.

### Phase 3 — modular prefab builder

Rebuild the prefab builder on top of the canonical renderer/data schema. Add semantic prefab tags/frontage/rooms so authored buildings can participate as normal generator choices.

### Phase 4 — extraction/travel shell

Connect static strategic map, foot reachability, raid deployment, physical extraction, and return to staging.

### Phase 5 — recover simulation systems one by one

Suggested order:

1. tick scheduler/calendar;
2. vision/perception cone;
3. lighting;
4. weather state + VFX;
5. silent spatial sound;
6. infected actors;
7. search/loot/inventory;
8. extraction stakes;
9. combat/body state;
10. vehicles as strategic gateways and later richer vehicle state.

Each phase must arrive as its own module set with tests. Never fold the subsystem into Main because it is “temporary.”

---

## 18. Definition of done for the modular rebuild foundation

The foundation is not complete merely because it runs.

It is complete when:

1. `Main.gd` is bootstrap/wiring only and contains no drawing/input/generator/player/UI implementation.
2. The exact golden art assets remain unchanged.
3. The recovered golden semantic art mapping is represented in a standalone `ArtCatalog`.
4. Tactical rendering is split into independent ground/structure/prop/player layers.
5. Player state, movement, facing, collision, input, camera and zoom are separate modules.
6. Strategic map state/view/input are separate modules.
7. A test tactical map displays the richer pre-rewrite art correctly.
8. Safari touch input works without double actions.
9. A generator can be removed/replaced without editing renderer/player/input/strategic-map code.
10. Renderer code can be replaced without editing generator or simulation code.
11. CI enforces architecture boundaries and art-baseline hashes.
12. The next Rural Edge generator consumes/produces semantic data only.

---

## 19. Source-of-truth / anti-drift rules

For future work, use this order:

1. newest explicit user instruction;
2. current repository state;
3. `README_SOPS.md`;
4. `README_CONTEXT.md`;
5. **this document**;
6. recovered golden code at commit `1763958f44eb7f855fd49944c00d1ffe608c0abe` for implementation archaeology;
7. older design documents only where they do not conflict with the newer static-map/modular-rebuild direction.

When a user asks to “rewrite” a subsystem, interpret that literally as replacing that module behind the stable contract. Do not opportunistically rewrite adjacent modules.

When recovering an old subsystem, inspect the actual golden code/assets first. Do not describe an approximation as “the old system.”

If uncertain about which behavior or visual the user means, ask a targeted question before making a destructive or cross-module change.

---

## 20. Short project statement

Tick Survival Lab is a modular top-down zombie survival/extraction simulation. The survivor begins on the rural edge of a static strategic world map and initially travels on foot to procedurally assembled tactical raid sites. Better roaming capability and vehicles extend the expedition frontier toward small towns, suburbs, the city edge, and the city center. Vehicles initially act like dungeon stairs between strategic travel depths. Tactical sites use a recovered, fixed multi-atlas art vocabulary and semantic world-data contract, while generation, rendering, player movement, input, camera, strategic travel, prefab authoring, extraction, and future simulation systems remain independently replaceable modules.
