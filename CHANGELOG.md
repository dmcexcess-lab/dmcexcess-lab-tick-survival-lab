# Changelog

## Extraction Raid Loop 0.6 — 2026-08-15

- Pivoted the 5×5 mini-world from seamless adjacent-region travel into an extraction-survival destination map: base/staging → choose destination → fresh 64×64 raid → reach green extraction → return to base.
- Added `EXTRACTION_RAID_DESIGN.md` as the durable gameplay contract; it supersedes only the seamless-travel portions of the earlier mini-world design while retaining v5 streetscape/building/art/performance work.
- Added `ExtractionRaidState.gd` as the authoritative base-vs-raid session owner, including active destination, visit counts, deterministic fresh raid seeds, last raid seed, and successful extraction count.
- Added `ExtractionWorldPresentation.gd` as the active main-scene harness. The full-screen map stays open at base, destination cells are tap/click deploy targets, and the same destination produces a different deterministic local map on later visits.
- Commercial destinations are presented as shops/strip malls, downtown as offices/dense streets, residential as homes/duplexes/estate houses, plus woods and rural raid destinations.
- Removed active gameplay dependence on walking through one local edge into a neighboring macro region. Generated green edge exits now function as extraction cells; stepping onto one costs the normal final movement action and returns to base/staging.
- The world map remains inspectable during a raid but becomes view-only until extraction, preventing redeployment while a raid is active.
- Preserved scheduler/calendar/weather/survivor state across raid completion while keeping deployment transit abstract and zero-tick until travel/fuel/vehicle systems actually exist.
- Strengthened `MiniWorldSmoke.gd` with deterministic extraction-session proofs: cannot redeploy mid-raid, extraction returns to base, same world/visit sequence reproduces raid seeds, repeating one destination rerolls to a new seed, and raid maps retain four extraction cells.
- Updated `README_CONTEXT.md`, `ROADMAP.md`, and `game/main.tscn` so the extraction loop—not seamless region traversal—is now the canonical gameplay direction.

## Mini-World / Streetscape v5 — 2026-08-15

- Added `MINI_WORLD_STREETSCAPE_DESIGN.md` as the durable design for the mini-Zomboid pivot: a cheap deterministic macro world connected to detailed local tactical regions rather than one continuously rendered island.
- Added `MiniWorldState.gd` with a deterministic 5×5 macro world, guaranteed downtown/commercial/residential/rural/woods identities, stable per-region seeds, current-region coordinates, and bounded cardinal travel.
- Added `MiniRegionGenerator.gd` as generator version 5. It keeps procedural generator v4 as the physical road/map baseline, prepares region-appropriate building shells, then applies a deterministic streetscape/building-family coherence pass.
- Added `MiniRegionFocusPass.gd` so macro cells labeled residential, commercial, rural, woods, or downtown are guaranteed enough coherent local building shells even when an arbitrary v4 seed would otherwise produce no buildings of the needed type.
- Added `StreetscapePass.gd` with actual traffic-control usage: traffic lights, multiple stop signs, street-name signs, streetlights, hydrants, and rural/woodland utility poles now appear from road/intersection rules instead of leaving most civic art unused.
- Added single-story trailer, mansion/estate-house, duplex, and two-/three-unit strip-mall grammars while retaining existing houses, farmhouses, standalone stores, offices, and warehouses.
- Added family metadata as the sixth `building_rects` field and family-aware footprint validation so narrow trailers and shallow strip malls are legal without weakening ordinary building rules.
- Eliminated generated parking lots with no destination: every v5 parking-lot rectangle must overlap a building, and legacy parking-only commercial parcels are deterministically repaired into attached strip malls.
- Added a door-sanity pass that removes accidental horizontal or vertical runs of three adjacent doors; multi-unit storefront entrances are deliberately spaced with wall/window frontage between them.
- Replaced the old whole-region overmap with a central 5×5 mini-world map. The survivor is shown as a red dot inside the current macro cell using local coordinates; `M` and the Safari-safe on-screen `MAP` button remain zero-tick controls.
- Added region travel through local edge roads. Crossing an edge into a valid neighboring macro cell loads its deterministic local region while preserving scheduler/calendar, weather, survivor state, and authoritative movement cost.
- Narrowed tactical zoom to performance-safe local-detail views: 14×12 at 39px, 12×10 at 44px by default, and 10×9 at 50px. The far 14×12 view uses lower-rate/lower-density cosmetic weather while authoritative weather and perception values remain unchanged.
- Retired v4's old validation assumption that every individual 64×64 map must contain a substantial patch of all five biomes; region identity now belongs to the 5×5 macro world. Road connectivity, blocked-road, exit, geometry, room, and physical-world validation remain in force.
- Added permanent `MiniWorldSmoke.gd` coverage across all 25 macro regions for deterministic world/local generation, world bounds, traffic controls, parking/building coherence, no triple-door runs, and the requested trailer/mansion/duplex/strip-mall family diversity.

## Tactical Weather Performance / De-Sync Pass — 2026-08-15

- Stopped the active presentation harness from repainting the entire tactical scene on every process frame solely for weather/light animation.
- Capped cosmetic redraws at 30 FPS normally and 24 FPS at the widest 20×17 tactical zoom; player actions, zoom changes, menus, map toggles, and other state changes still request immediate redraws.
- Static clear-weather scenes now stop continuous redraws unless an actually flickering light source is visible/active.
- Replaced repeated linear wall-array scans in weather masking with a cached wall-cell dictionary, making wall rejection effectively O(1) per fog/particle sample.
- Reworked rain, snow, and wind-debris trajectories to use deterministic seed-derived independent phases, speeds, drift rates, and sizes so the particles no longer converge into obvious synchronized bands/cycles.
- Kept all changes presentation-only: authoritative weather state, scheduler ticks, perception modifiers, indoor/outdoor rules, and fog-of-war semantics are unchanged.

## Full-Screen Overworld Map / Generation v4 — 2026-08-14

- Added one full-screen Zomboid-style overworld map presentation, opened by keyboard `M` or a Safari-safe on-screen `MAP` button; there is intentionally no minimap and no separate local-area map mode.
- The overworld uses the same generated region coordinates and shows biome terrain, road network, parking-lot footprints, building footprints, exits, and the survivor as a red dot; opening/closing it costs zero authoritative ticks and tactical actions are blocked while it is open.
- Upgraded `ProceduralRegionGenerator.gd` to generator version 4 and replaced 7×7 micro-parcels with a 10×11 bootstrap parcel grammar.
- Enlarged generated houses/shops to roughly 9×8 and downtown structures to as much as 10×10 so interiors have meaningful traversable area.
- Added real physical interior subdivision: houses/rural homes get three rooms, stores get sales + stock rooms, offices get three zones, and industrial buildings get utility + warehouse zones. Interior partitions are ordinary wall cells with ordinary door cells, not a second map schema.
- Added `building_rects` and `rooms` metadata for presentation/testing while keeping collision/LOS authority in the existing walls/doors/world state.
- Reworked commercial parking: lots use an asphalt base and only marked stalls use parking tiles; parking stall cells are prohibited from touching cardinally, guaranteeing at least one non-parking tile between adjacent marked spaces.
- Updated tactical presentation to consume per-cell wall/door/window themes so the new interior partitions and existing shell metadata render with their intended material vocabulary.
- Strengthened deterministic region validation/smoke coverage for building footprint size, room subdivisions, interior walls/doors, parking metadata, and parking-stall spacing.

## Final Environment Art Pass — 2026-08-14

- Added `final_environment_props_atlas.svg` with 128 environment-only sprites: 32 nature, 32 street/civic, 40 residential fixtures/furniture, and 24 commercial/office/industrial fixtures.
- Added `final_environment_surfaces_atlas.svg` with 64 terrain, exterior, interior-floor, wall-finish, and opening tiles.
- Defined the bootstrap art freeze: inventory items, loot, and equipment are not depicted as loose world sprites; tactical world art is reserved for surfaces, structures, fixtures, furniture, vegetation, civic infrastructure, large physical objects, and clutter.
- Routed selected legacy ground/prop names through final-pass art so current generated/authored maps immediately gain richer trees, signs, furniture, bathroom/kitchen fixtures, TVs/appliances, and floor materials without changing object identity, collision, or LOS semantics.
- Extended `TacticalTiles.gd` with stable final-atlas catalogs and caches without reindexing any prior atlas.
- Strengthened permanent region smoke coverage to require the 128-prop / 64-surface final vocabulary and both final atlas resources.
- Expanded `ART_VOCABULARY.md` as the durable no-more-broad-environment-art contract before overworld and macro-world work.

## Procedural World Art Vocabulary Pass — 2026-08-14

- Added `world_art_atlas.svg`, a 64-tile generator-support atlas covering directional paved roads, corners, T-junctions, four-way intersections, road end caps, plain/wide-road asphalt, sidewalk/curb variants, driveways, parking stalls, crosswalks, cracked asphalt, stained concrete, dirt roads, gravel, field rows, richer interior floors, building wall materials, door variants, window variants, and utility surface details.
- Added `building_props_atlas.svg` with 32 new interior/exterior sprites including stove, kitchen counter, dresser, nightstand, bathtub, shower, vanity, dining table, armchair, filing cabinet, cubicle, computer, checkout, freezer, produce bin, pallet rack, tool chest, workbench, locker, utility sink, water heater, exterior AC, electric meter, utility pole, traffic light, stop sign, parking meter, bollard, hedge, flower bed, shed, and propane tank.
- Upgraded `ProceduralRegionGenerator.gd` to generator version 3 with explicit per-road directional link masks and road-surface metadata, so horizontal roads are actually drawn horizontally and the same data contract supports corners/intersections for the upcoming macro road graph.
- Added directional sidewalk curb art and distinct paved/dirt road presentation without changing road collision or network semantics.
- Expanded procedural houses, shops, downtown buildings, industrial spaces, yards and rural parcels to use the new floor/parking/field and fixture vocabulary immediately.
- Added `door_themes` and `window_themes` alongside existing per-cell wall themes so richer building-template rendering can select residential, commercial, industrial, office and storefront openings without changing physical door/glass ownership.
- Expanded tall-object perception vocabulary for appropriate new fixtures such as freezers, filing cabinets, pallet racks, lockers, water heaters, hedges and sheds.
- Extended the shared ground language with optional `ground_cells` overrides for future sparse topology details while retaining rectangle fills for rooms/lots/fields.
- Strengthened procedural-region CI to require deterministic road links/surfaces, both horizontal and vertical road directions, directional road art, and opening-theme metadata.
- Added `ART_VOCABULARY.md` as the durable art/physics contract for the next building-template and macro-world passes.

## Upright Directional Survivor Poses — 2026-08-14

- Replaced the old directional player presentation that literally rotated one front-facing sprite by 90/180/270 degrees.
- Added `player_facing_atlas.svg` with separate upright south/front, north/back, and west/profile poses; east uses a horizontal mirror of the side profile.
- All facings keep the survivor's feet at the bottom/south side of the tile while `player.facing` still drives vision, flashlight, movement, and interaction.

## World / Navigation Foundation Audit — 2026-08-14

- Reworked procedural road generation from an arbitrary full-region grid into a connected hierarchy: biome connectors, developed local streets, rural service roads, woodland trails, and a three-tile arterial network that reaches all four edge exits.
- Moved the player spawn onto the arterial crossing and added deterministic road-network validation so every exit must be reachable from spawn and later geometry may not block road cells.
- Added road classes (`arterial`, `secondary`, `local`, `trail`), local `road_ports`, developed sidewalks, rural dirt shoulders, road-frontage requirements for developed structures, and road-facing procedural building entrances.
- Added generator version 2 metadata and strengthened region smoke coverage for deterministic roads, props, wall themes, clutter density, spawn/exit road membership, and four edge ports.
- Added `clutter_atlas.svg` with 24 new indoor/outdoor sprites: chair, desk, toilet, sink, cabinet, bookshelf, TV, lamp, tree, bush, fence, mailbox, trash can, road sign, bench, hydrant, streetlight, rug, laundry, planter, tire pile, cardboard, picnic table, and firewood.
- Expanded procedural residential, commercial, downtown, woods, and rural decoration using the new clutter while keeping visual props, movement blockers, and sight blockers as separate physical concepts.
- Added per-building wall-theme metadata and more appropriate procedural interior light types for houses, stores, and downtown/industrial structures.
- Made procedural ambient lighting biome-aware instead of treating the whole 64×64 region as one alley theme.
- Added sealed-corner LOS handling so diagonal vision/light cannot squeeze between two touching opaque orthogonal cells; trees, bookshelves, and cabinets now participate in tall-object occlusion.
- Added `WORLD_NAVIGATION_AUDIT.md` and refreshed `WORLD_GENERATION.md` / `README_CONTEXT.md` to define what is complete, what is optional before actor systems, and what should wait.

## Directional Survivor Sprite — 2026-08-14

- Activated the existing four authored survivor atlas facings instead of forcing one upright pose for every direction.
- South now shows the survivor's front, north shows the survivor's back, and east/west use their matching side profiles.
- Sprite facing reads directly from the same authoritative `player.facing` already used by vision, flashlight, interaction, and movement; no duplicate visual-facing state was added.

## Tick-Driven Calendar / Day-Night Cycle — 2026-08-14

- Added `WorldCalendar.gd` as the durable tick-to-calendar owner.
- Set initial play-test compression to 7,200 authoritative ticks per 24-hour day (5 ticks per game minute).
- Movement, turning, doors, combat proofs, and every future timed action now naturally advance visible clock/date through the same scheduler tick count.
- Added tick-driven night, dawn, day, and dusk phases; pausing does not advance the sun/calendar.
- Added dawn/dusk ambient lighting and reduced window daylight during transition phases.
- Added deterministic calendar smoke coverage for rate, phase boundaries, and date rollover.

## Procedural Region / Player Zoom / Safari First-Touch Fix — 2026-08-14

- Added a deterministic 64×64 procedural region stress slice with residential, commercial, downtown, woods, and rural zoning.
- Added seeded road hierarchy and biome-specific parcel/structure/decor rules while preserving the existing physical map schema.
- Generalized local-world bounds and perception dimensions for maps larger than the original 20×18 authored locations.
- Bounded lighting/perception work around the player so larger generated regions do not require full-map visibility scans each action.
- Added player-controlled map zoom with four presentation levels; zoom does not alter world/simulation coordinates.
- Added a Web touch autoload that detects touch-capable browsers up front and swallows synthetic mouse clicks, including the first-click-before-first-touch Safari case.
- Added deterministic region generation smoke coverage.

## Mobile Map Zoom / Clock Direction — 2026-08-14

- Increased tactical tile presentation from 28px to 31px for better mobile readability.
- Added an 18×16 player-following presentation window over the unchanged 20×18 physical map; the camera crops the outer ring but shifts near edges so exits and edge tiles remain reachable.
- Updated map tapping, weather particles, fog, lighting, props and light glows to use the cropped camera coordinates without changing simulation/world coordinates.
- Kept the current calendar-speed constant provisional; documented that action ticks and displayed calendar progression should be separate concepts so combat timing can stay second-scale while days remain playable.

## Snow / Fog / Survivor HUD Refinement — 2026-08-14

- Added `snow` as a fixed weather profile with its own snowfall intensity, cold temperature offset, visibility/light effects, wind, and silent sound-masking hook.
- Added animated snowflakes that continue moving while paused and respect the same outdoor/non-wall weather mask as rain and debris.
- Increased fog presentation density without changing the underlying fog gameplay profile.
- Refined the in-game HUD: replaced ambiguous `FAT %` with survivor-facing `STAMINA %`; raw fatigue remains an internal/deeper-info value.
- Weather is now shown in the in-game HUD only while outdoors.
- Indoor HUD temperature now shows only the local indoor temperature; it no longer exposes outside temperature or outdoor weather.
- Outdoor HUD keeps current temperature and wind speed alongside current weather.
- Expanded deterministic environment smoke coverage to validate the snow profile and cold-temperature behavior.

## Split HUD / Safari Input / Environment Readout — 2026-08-14

- Split the information display into a read-only in-game survivor/world HUD plus a separate `DEV` overlay.
- In-game HUD now shows survivor name, health, fatigue, carry weight/capacity, in-game time/date/weather, local temperature, indoor/outdoor status, outdoor wind speed, and a `Looking at:` readout for the object/tile directly ahead.
- Added HUD-ready base survivor fields to `PlayerActor.gd` without introducing inventory or body-system ownership early.
- Added developer-only world controls for HH:MM, MM/DD, and weather. HH:MM and MM/DD use native Godot `LineEdit` controls so mobile Safari can summon the keyboard; weather remains a touch button and key `6` fallback.
- Added a lightweight deterministic temperature hook from date/time/current weather plus indoor thermal buffering and wind-speed display helpers in `TacticalWeather.gd`; this is not yet weather-pattern simulation.
- Fixed the returning 180-degree-turn / double-move mobile bug by suppressing Safari's synthesized mouse click after a handled touch event, so one physical tap commits one action.
- Weather VFX now reject indoor cells and wall cells. Rain and wind debris are filtered by their current map cell; fog and storm flashes are rendered per outdoor cell rather than across whole structures.
- Moved weather VFX beneath fog-of-war so masking indoor/unseen areas does not reveal room geometry.

## Weather Selector / True Control Grid — 2026-08-14

- Rebuilt the touch deck around shared row constants so `TURN L` and `TURN R` use the exact same middle-row Y coordinate and height.
- Preserved the intentional empty upper-left slot, with `CROUCH` below `TURN L`; the right column remains `FORWARD` / `TURN R` / `BACK`.
- Added an on-screen `WEATHER: <STATE>` touch control in the center column; developer key `6` remains available.
- Strengthened presentation-only weather animation with denser moving rain, broader drifting fog, more windblown debris, and a silent visual storm-flash effect.
- Weather VFX continue running from non-authoritative presentation time while the player is auto-paused or the pause menu is open; simulation weather state still does not advance while paused.

## Weather Foundation / Touch Layout Refinement — 2026-08-14

- Added `TacticalWeather.gd` as the deterministic owner for current weather state and gameplay-facing weather modifiers; no weather-pattern forecasting or transitions are simulated yet.
- Added fixed clear, rain, storm, fog, and wind profiles with precipitation, fog, wind, visibility, ambient-light, and future sound-masking values.
- Integrated weather into perception so poor weather can reduce outdoor/daylight illumination and effective visual range without changing flashlight behavior.
- Added presentation-only rain, drifting fog, and windblown debris VFX driven by real presentation time. They continue animating while paused, while authoritative weather state remains frozen.
- Added developer key `6` to cycle weather profiles for testing; the current harness starts in rain so the VFX are immediately visible.
- Added weather invariants to the existing deterministic environment smoke test and made Pages CI require the new weather module.
- Refined mobile controls again: `TURN L` and `TURN R` are now identical size and exactly level; both are slightly shorter. The right column gives all remaining upper space to `FORWARD` and remaining lower space to `BACK`. `CROUCH` remains below `TURN L`, leaving the matching upper-left space intentionally empty.

## Touch Control Layout Correction — 2026-08-14

- Repositioned the FF-style mobile controls to match the intended layout: `FORWARD` above `TURN R`, `BACK` below `TURN R`, and `CROUCH` below `TURN L`.
- Kept all existing touch semantics, timing, perception, pause-menu behavior, and Safari-oriented large hit targets unchanged.

## Mobile Controls / Upright Player Pass — 2026-08-13

- Kept the tactical survivor paper-doll visually upright while facing continues to drive the vision cone, flashlight direction, interaction direction, and action logic.
- Added a small facing indicator so direction remains readable without rotating the body sprite.
- Expanded the logical Web/mobile viewport to 640×844 and centered a slightly smaller tactical board so a dedicated control strip fits cleanly below it.
- Restored FF-style touch controls with large `TURN L` / `TURN R` buttons and smaller `FORWARD`, `BACK`, and `CROUCH` buttons.
- Added forward/back movement that preserves facing; backing up no longer turns the survivor or perception cone.
- Added a timed crouch stance to `PlayerActor.gd`; crouched movement is slower and running is disabled while crouched.
- Added a real pause menu accessible by `MENU` or Escape. Opening it pauses the Godot tree; it can resume or exit to Google.
- Web exit uses same-tab browser navigation for Safari/mobile reliability; desktop falls back to `OS.shell_open`.
- Preserved map tapping and all existing keyboard/developer controls alongside the new touch layout.

## Milestone 0.3A — Visual Perception Restoration — 2026-08-13

- Restored the reusable First Fire tactical atlas presentation into Tick as a clean same-owner asset subset covering ground, walls, doors, windows, props, barrels, and a four-direction survivor sprite.
- Added `TacticalTiles.gd` as the Tick-native atlas renderer instead of continuing with programmer rectangles/text labels.
- Added `TacticalPerception.gd` to own line-of-sight, facing cone, opaque-prop rules, light integration, visible cells, and remembered fog state.
- Wired existing authored light markers into actual per-cell lighting using the already-ported `TacticalLighting.gd` rules.
- Added powered/unpowered environment lights, indoor/outdoor ambient light, window daylight, and a directional flashlight test profile.
- Added real LOS occlusion: walls, closed doors, and tall/opaque obstacles block sight/light; windows transmit sight and daylight.
- Added actual four-direction vision cone plus darkness-limited recognition.
- Added two-state fog of war: unseen cells are nearly black; previously seen cells remain dimly remembered.
- Added developer toggles: `F` flashlight, `4` day/night, `5` power, while preserving existing scheduler proof controls.
- Added deterministic `PerceptionSmoke.gd` coverage for door occlusion, cone direction, directional flashlight lighting, and fog memory.
- Updated CI, roadmap/context, and First Fire reuse audit to make the restored visual/perception layer part of canonical Tick rather than a deferred candidate.

## Milestone 0.2 — Action Execution Model — 2026-08-13

- Replaced the immediate tick-jump prototype with an explicit player action execution state machine.
- Added player-ready auto-pause semantics: the player is ready only before/after an action, never during committed execution.
- Added action start/end ticks, elapsed/remaining progress, phases, status, payload, and deterministic event traces.
- Added committed, resumable, canceled, and forced-failure interruption behavior.
- Added damage interruption hooks; committed actions continue through ordinary damage while resumable actions preserve exact elapsed/phase state.
- Added `TimingDummy.gd`, a minimal autonomous scheduled actor used to prove multiple actors can advance during one player action.
- Added deterministic tie ordering by next action tick then actor ID.
- Expanded scheduler CI to prove a 10-tick action permits two 4-tick dummy actions while a 3-tick action permits none.
- Added a phased reload proof that interrupts at tick 5, preserves the `mag_in` phase, then resumes to completion.
- Added a committed axe-swing proof that ordinary damage does not cancel execution.
- Updated the Web developer harness with READY/status diagnostics and keys 1/2/3 for light/heavy/reload timing demonstrations.

## Design / First Fire Reuse Pass — 2026-08-13

- Added `DESIGN.md` as the durable long-form design document for Tick Survival Lab.
- Added `ROADMAP.md` with ordered milestones from the current tick foundation through persistent island/outbreak simulation.
- Added `FIRST_FIRE_REUSE.md` documenting which First Fire systems are safe to adapt and which architecture must stay out.
- Made player/world separation an explicit design rule: player death can leave the same persistent world available for a new playable survivor.
- Defined real-time-with-auto-pause action execution and committed/resumable/canceled/forced-failure interruption policies.
- Added use-based skills, occupations as starting knowledge, and physical books/manuals/recorded training media to the design.
- Added detailed-enough injury goals including deep wounds, sutures, fractures, splints, crutches, fatal trauma and time-sensitive extremity amputation.
- Defined the long-term large island world, destroyed/bombed bridge boundaries, outbreak epicenter/spread settings, family/occupation starts, autonomous survivors/animals, emergent settlements, patrols, logistics and infrastructure reclamation.
- Ported First Fire's dependency-free tactical lighting rules into `TacticalLighting.gd` without importing First Fire inventory/UI/camp dependencies.
- Ported First Fire's tactical sound/localization helpers into `TacticalSound.gd` without faking propagation or AI ownership early.
- Added deterministic environment-rule smoke coverage to permanent CI.
- Updated README and project context to point future development at the new design, roadmap and reuse audit.

## Milestone 0.1 — Authoritative Tick Movement — 2026-08-13

- Added a central authoritative tick scheduler with explicit committed-action costs.
- Added a single player actor timing model for walk, run, turn, and door actions.
- Added fatigue/encumbrance-ready action-cost modifiers without introducing inventory or body systems early.
- Added runtime local-world state for physical collision and mutable open/closed doors.
- Replaced the static map reroll harness with a playable developer slice using WASD/arrows plus click/tap directional controls.
- Turning now costs time independently before movement when facing changes.
- Walking and running use different tick costs; blocked movement and UI mode changes do not advance world time.
- Added a visible developer HUD for world tick, movement mode, facing, last action, and last action cost.
- Added deterministic scheduler/world smoke coverage to permanent Pages CI.

## Bootstrap 0.0 — Map Foundation — 2026-08-13

- Started clean Tick Survival Lab scaffold.
- Extracted the physical tactical-location format from First Fire without camp/menu/expedition/combat dependencies.
- Seeded seven location families with two variants each.
- Added structural map validation.
- Added a disposable rerollable map preview harness.
- Added human README, durable project context, and coding/GitHub SOPs.
- Added permanent Godot 4.7.1 import/map-smoke/startup/Web-export CI and GitHub Pages deployment.