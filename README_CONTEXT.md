# Tick Survival Lab — Project Context

> **MANDATORY CONTEXT RULE FOR GPT:** At the start of every new user prompt requesting code or repository changes, fetch and reread both `README_SOPS.md` and this file from current `main`, then inspect the current files relevant to that prompt. Do this once per prompt/change request, not before every edit inside the same coherent batch.

## Identity

Working repo/project name: **Tick Survival Lab**.

GitHub repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Web preview: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

This is an original Godot 4 top-down zombie-apocalypse survival/extraction simulation. Project Zomboid is a systemic-scope reference only; do not copy its proprietary code, art, maps, UI, names, text, or content.

First Fire is a same-owner source project. Reusable tactical/physical-world work may be adapted after inspection, but Tick must not inherit First Fire's camp/menu/expedition architecture.

Durable design references: `DESIGN.md`, `ROADMAP.md`, `WORLD_GENERATION.md`, `WORLD_NAVIGATION_AUDIT.md`, `ART_VOCABULARY.md`, `MINI_WORLD_STREETSCAPE_DESIGN.md`, `EXTRACTION_RAID_DESIGN.md`, `FOCUSED_RAID_INTERIORS.md`, and `FIRST_FIRE_REUSE.md`.

**`EXTRACTION_RAID_DESIGN.md` supersedes the seamless adjacent-region travel portions of `MINI_WORLD_STREETSCAPE_DESIGN.md`. `FOCUSED_RAID_INTERIORS.md` is the current local-generation depth contract.** The existing streetscape/building-family/art/performance rules remain valid where they do not conflict with the newer extraction/focused-raid rules.

## Current milestone / stage

Milestone 0.1 authoritative tick movement and 0.2 action execution are complete. 0.3A visual perception is complete. 0.3B weather foundation is functionally present. The current gameplay shell is an **extraction loop**:

**BASE/STAGING MAP → CHOOSE DESTINATION TYPE → GENERATE FRESH 64×64 RAID → TACTICAL PLAY → REACH GREEN EXTRACTION → RETURN TO BASE/STAGING MAP.**

The 5×5 mini-world is a destination catalog, not a seamlessly traversed terrain grid. Its cells represent commercial/strip-mall, downtown/office, residential, woods, and rural raid sites. Selecting a site creates a fresh deterministic raid seed for that visit. Repeating the same destination produces another fresh tactical map.

Local raid generation is now **generator v6**. A selected destination no longer inherits the old v4 requirement to look like a miniature world containing all five biome families. V6 keeps v4's proven road/physical foundation, removes incompatible legacy structures, normalizes the raid's broad biome identity to the selected destination, guarantees larger focus-appropriate structures where space permits, applies streetscape/building families, then deepens functional interiors.

## Ownership

- `TacticalMapGenerator.gd` — authored initial physical map facts plus shared ground-query language.
- `ProceduralRegionGenerator.gd` — deterministic v4 64×64 physical baseline: mixed-biome stress field, roads, parcels, structures, clutter, lights and exits. V4 is a substrate now, not the final extraction-content authority.
- `DestinationFocusCleanupPass.gd` — generation-only v6 cleanup owner. Removes legacy v4 building families incompatible with the selected raid destination, removes commercial parking parcels from non-commercial raids, and prunes obvious off-theme leftovers before focused content is added.
- `MiniRegionFocusPass.gd` — generation-only focused composition owner. Normalizes the raid's broad biome identity and guarantees larger destination-appropriate building shells where free geometry permits.
- `StreetscapePass.gd` — traffic controls, street furniture, recognizable building-family specialization, parking repair and door-run sanitation at generation time.
- `DestinationInteriorPass.gd` — generation-only functional interior owner for special families. Deepens mansions, duplexes, strip malls and trailers into purposeful internal room layouts after Streetscape chooses the family.
- `MiniRegionGenerator.gd` — generator v6 orchestration layer: v4 baseline → focus cleanup → focused composition → streetscape/families → destination interior depth, plus composed validation.
- `MiniWorldState.gd` — deterministic 5×5 destination catalog, broad destination identity, stable site seed and display name. Its older adjacency helpers are not current gameplay travel authority.
- `ExtractionRaidState.gd` — current high-level deploy/extract owner: base vs raid mode, active destination, fresh raid seed sequence, visit counts and successful extraction count.
- `LocalWorldState.gd` — mutable physical facts for the currently loaded tactical raid, such as door state/collision.
- `TickScheduler.gd` — authoritative world tick, action execution, interruption state, actor ordering and player-ready state.
- `WorldCalendar.gd` — tick-to-clock/date/daylight mapping.
- `PlayerActor.gd` — player location/facing/movement/stance and current survivor HUD fields/timing modifiers.
- `TimingDummy.gd` — scheduler proof actor only, not zombie AI.
- `TacticalLighting.gd` — physical lighting math.
- `TacticalSound.gd` — silent sound/localization helpers; propagation visualization is pending.
- `TacticalWeather.gd` — fixed current weather profile, visibility/light/sound-mask hooks, temperature and wind helpers. It does not simulate evolving weather patterns yet.
- `TacticalTiles.gd` — tactical/environment/player rendering vocabulary.
- `TacticalPerception.gd` — LOS, facing cone, opaque geometry, lighting/weather integration and fog memory.
- `MapPreview.gd` / `MapPreviewPresentation.gd` / `MiniWorldPresentation.gd` — inherited developer/presentation layers; seamless region-travel behavior in `MiniWorldPresentation.gd` is no longer the active main-scene behavior.
- `ExtractionWorldPresentation.gd` — active playable presentation harness. It binds the destination map to `ExtractionRaidState`, loads selected raids, makes the destination map view-only while deployed, and converts generated edge exits into extraction points. It owns presentation/orchestration only, not raid-session truth.

Preferred dependency direction remains:

**map/data → persistent/session world state → tick scheduler/rules → actor simulation → presentation/input**

## Extraction loop semantics

### Base / staging

Bootstrap base is the full-screen destination map, not yet a physical buildable base scene.

At base:

- tactical movement is unavailable;
- inspecting the map costs zero ticks;
- tap/click a destination cell to deploy;
- commercial means shops/strip malls, downtown means offices/dense streets, residential means homes/duplexes/estate houses, woods means woodland/trails, rural means trailers/farmhouses/sparse infrastructure;
- the same destination can be selected repeatedly;
- every repeat deployment receives a fresh deterministic raid seed.

### Deployment

A raid seed is derived from world seed + destination stable site seed + destination coordinate + that destination's visit count.

Therefore same world + same sequence of destination choices is reproducible, but the same site changes on its second/third/etc. raid.

Deployment travel is currently abstracted and costs zero ticks. Do not invent travel-time/fuel costs until vehicles/needs/transit are real systems.

### Raid

Only one 64×64 tactical raid is loaded at a time. Scheduler/calendar/weather/survivor state continue through a raid and extraction. The selected destination identity is passed to `MiniRegionGenerator` as the generation focus.

The map may be opened during a raid, but it is view-only until extraction. The player cannot redeploy directly from an active raid.

### Extraction

Generated green edge exit cells are extraction cells, not links to neighboring tactical regions.

Stepping onto any green extraction cell:

- uses the normal final movement tick cost;
- completes the raid successfully;
- returns `ExtractionRaidState` to base mode;
- reopens the destination map;
- preserves elapsed world/calendar state;
- does not load an adjacent map.

No loot-retention/death-loss behavior is faked before inventory exists.

## Focused destination-generation semantics

Destination selection provides breadth between raids. The 64×64 tactical map should provide depth inside the chosen destination.

For focused raids, the broad `biome_cells` identity is normalized to the chosen focus. Roads, sidewalks, interiors, parking, yards and other ground overrides still provide visual variety, but biome-sensitive systems no longer see an arbitrary five-biome mosaic in one raid.

V6 removes incompatible old v4 structures before adding focused content:

- residential permits house/rural-residential shells;
- commercial permits store/office shells;
- downtown permits office/store/industrial shells;
- rural permits rural-wood/house shells;
- woods permits rural-wood/cabin-like shells;
- commercial/downtown may keep parking lots; non-commercial focused raids do not keep old commercial parking parcels.

Current large-shell candidate targets are roughly:

- residential up to 14×11;
- commercial up to 18×12;
- downtown office up to 18×12;
- rural up to 13×10;
- woods up to 11×9.

Geometry can force smaller buildings; roads/spawn/collision facts remain authoritative.

### Functional room depth

Large ordinary stores can contain sales floor + manager office + back stockroom. Large offices can contain reception + open office + manager office + storage + meeting room. Larger ordinary houses can contain living room + kitchen + primary bedroom + bathroom.

Special families are also deepened:

- mansion/estate: living room, kitchen, primary bedroom, secondary bedroom when space supports it, bathroom;
- duplex: each sealed unit gets a living/kitchen zone and bed/bath zone;
- strip mall: each storefront has a public sales zone plus rear depth; one rear room is a manager office and other units can use stockrooms;
- trailer: compact living/kitchen plus bed/bath zones.

All buildings remain **single-story**. Room-purpose metadata and fixtures do not yet imply loot tables/searchability; those belong to later owning systems.

See `FOCUSED_RAID_INTERIORS.md` for the durable detailed contract.

## Timing semantics

The control model is real time with automatic pause, represented synchronously in the current harness while outcomes remain discrete.

- player input occurs at player-ready points;
- every real tactical movement/door/stance/etc. action has an explicit tick cost;
- other scheduled actors may act during a committed player action;
- ties resolve by next action tick then lexical actor ID;
- pausing/map inspection does not advance time;
- the final step onto an extraction cell is a normal movement-cost action;
- base destination selection itself is currently zero-tick because transit is abstracted.

Calendar remains 7,200 ticks/day, 5 ticks/displayed minute. Pausing does not advance it.

## Mobile / controls

Logical viewport is 640×844. Touch remains first-class:

- left: empty top slot → TURN L → CROUCH;
- right: FORWARD → TURN R → BACK;
- plus/minus changes tactical presentation zoom only;
- MAP opens the full-screen destination map;
- one physical touch must equal one action;
- `SafariInputGuard.gd` plus the local suppression window prevent synthesized mouse double-actions.

At base the destination map stays open until a raid is selected. During a raid, `M`/MAP can inspect and close the map without advancing ticks.

## Tactical zoom / performance

The tactical camera remains local-detail only:

- 39 px / 14×12 — far local overview;
- 44 px / 12×10 — default;
- 50 px / 10×9 — close detail.

Far view uses cheaper cosmetic weather. Authoritative weather/perception values do not change with zoom.

## Streetscape / building families

Generator v6 retains the v5 streetscape vocabulary inside every raid.

Building families include house, farmhouse, standalone store, office, warehouse, trailer, mansion/estate house, duplex, and two-/three-unit strip malls.

Current generation invariants include:

- commercial parking has a building destination;
- parking-only legacy commercial parcels are repaired into strip malls where applicable;
- traffic lights and stop signs are actually placed under current streetscape rules;
- developed streets can use street-name signs, streetlights and hydrants;
- rural/woodland roads bias toward utility poles;
- no horizontal or vertical run of three adjacent door cells survives generation;
- all buildings remain single-story;
- focused developed raids contain a larger destination anchor where generation space permits and validation requires the current thresholds;
- functional room validation runs across all 25 deterministic smoke-test destination sites.

## Visual / perception / sound

Art is not physics. Collision, LOS and interaction remain explicit data.

Player facing uses four independent upright sprites. Walls/closed doors/tall opaque props block LOS/light; windows transmit sight/daylight; flashlight is directional; visibility requires cone + LOS + sufficient light; fog remembers previously seen cells.

There is **no audible game sound**. Sound is simulated data and will be communicated through yellow spatial markers. Do not add music, footsteps, gunshot playback, zombie voices or weather audio unless the user explicitly reverses this rule.

## Current limits / next work

The current build proves:

- destination selection from a 5×5 world map;
- fresh deterministic raid seeds per visit;
- focused generator v6 local generation;
- destination-specific building population instead of inherited mixed-biome structures;
- larger destination anchors and deeper functional interiors;
- single active tactical raid;
- physical edge extraction back to staging;
- streetscape/building coherence;
- mobile-safe local zoom;
- tick/calendar/weather/perception foundations.

It does **not** yet contain infected AI, loot/search/inventory, combat, body injuries, extraction rewards/loss, a physical base, raid objectives, vehicles, off-screen population simulation or save serialization.

Preferred next gameplay order remains:

1. playtest deploy/extract + focused destination generation;
2. 0.3C spatial silent sound visualization;
3. infected actors using sight + sound;
4. searchable containers / loot / inventory;
5. extraction retention/failure consequences;
6. combat/body state;
7. richer raid objectives and destination-specific content;
8. physical base only when progression systems justify it.

## Source-of-truth order

1. Newest explicit user instruction
2. Current `main` repository state
3. `README_SOPS.md`
4. This context file
5. `FOCUSED_RAID_INTERIORS.md`
6. `EXTRACTION_RAID_DESIGN.md`
7. Other durable design docs
