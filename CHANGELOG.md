# Changelog

## 2026-08-31 — System 00F CI Consolidation

- Consolidated System 00F procedural-island verification so the planner/preflight 12-seed matrix runs once and the canonical playable 12-seed boot matrix runs once.
- Removed the standalone duplicate procedural boot-diagnostics workflow and removed the duplicate System-00F `PerformanceRazorSmoke`; the dedicated performance workflow remains the owner of that check.
- Retained System-00F boundary/import validation plus the settlement and countryside materialization regressions.
- Added path-aware System-00F push triggering so unrelated/docs-only pushes no longer launch the island gauntlet; edits to the owning workflow itself still trigger it.
- Consolidation commit: `32ef0c7647356b773e829081795b60563fc50d2b`.
- Verified owning run `33360162311` / job `99389828052` completed successfully on that exact head, including both 12-seed matrices and both materialization regressions; no repair was required.
- No runtime/gameplay code changed; the verified playable executable remains `9f6e0b8e9010d73181143481a84532fbfffb93e1`.
- Next step remains human browser visual acceptance; automated CI does not claim visual approval.

## 2026-08-31 — Roadside Power Pole Routing Correction

- Fixed the browser-reported shared-feeder artifact where independently chosen roadside supports could cross a road to dodge an obstacle and then immediately zig-zag back, including a crossing support landing on a generated gray driveway/access strip.
- Root cause was in real System-33 materialization rather than the renderer: utility topology carried generated roads/buildings/blocked props but omitted generated parcel driveway/parking access surfaces, while each pole independently chose its nearest legal off-road cell with no inherited road-side state.
- `UtilityLocalPowerTopologyPlanner` now carries actual generated parcel `driveway_cells` and `parking_cells` into deterministic `pole_exclusion_cells`; physical power supports cannot occupy those generated access surfaces.
- `NeighborhoodPowerInfrastructureMaterializer` now resolves support placement root-outward along the shared feeder. Straight-route children inherit their parent side; a genuinely forced crossing changes side and holds that new side for the next **two sequential pole placements** before an elective cross-back is allowed.
- Existing deterministic route-cell ordering still owns stable pole IDs. Shared-trunk deduplication, topology-driven forks, one final service drop per real building, fenced substations, nonphysical regional ingress, water behavior, renderer/lighting/LOS and input contracts were not replaced.
- Added permanent `System33RoadsidePoleRoutingSmoke.gd` plus `verify/system33-roadside-pole-routing`, covering generated access exclusions, same-side displacement, forced crossing, two-pole post-crossing hold and the real materialized shared trunk.
- Verified executable: `9f6e0b8e9010d73181143481a84532fbfffb93e1`.
- All **43/43 push-triggered exact-head workflows** passed with zero failures or pending runs, including `verify/system33-roadside-pole-routing`, `verify/system33-power-water`, `verify/system00f-streaming-materialization`, `verify/performance-architecture`, `verify/system00d-global-world` and `verify/pages-deploy`.
- Human WebGL2 desktop/phone/Safari visual acceptance remains pending; CI does not claim that the screenshot artifact is visually approved.

## 2026-08-29 — Decision-Pause Input + Startup Performance Follow-Up

- Replaced the fixed 120 ms cooldown with the authoritative WHEN decision-pause input gate.
- Kept all gameplay controls locked until the accepted action settles at the next decision pause; input at that pause is accepted immediately.
- Coalesced ambient, DEV flashlight and observer invalidations into one perception/light update per action.
- Reduced moving-light work to a camera-bounded cached presentation field and added revision-backed bounded LOS opacity/structure caching.
- Improved repeated focused FOV runs from ~11.84 ms to ~2.5-2.9 ms locally and cut the accepted-action startup profile roughly in half.
- Removed the unused Weather camera-local compatibility method.
- Renamed canonical runtime owners (`GameMain`, `CraftingGameMain`, `PlayerMovementControls`, `PlayerActionController`, `PlayerStreamingFocusAdapter`) and removed their obsolete demo/bridge files.
- Retained `DemoLightingSourceAdapter` because Phase 3 equipment/battery/switch/grid truth does not exist yet.

## 2026-08-29 — Player Input / Lighting Responsiveness Repair

- Moved playable player-action resolution out of synchronous input callbacks and into a bounded per-frame action pump.
- Dropped stale busy/cooldown input to prevent browser event backlogs from becoming unintended future movement.
- Busy-gated canonical and crafting controls while movement/turn/stance actions resolve.
- Made DEV flashlight turns invalidate physical-light presentation immediately, filtered unrelated world mutations, and suppressed duplicate same-revision light-map uploads.
- Added permanent input-responsiveness regression coverage.
- Preserved authoritative action timing, movement legality, WHAT persistence, collision, crafting and save schemas.

## Roadmap Phase 1E Content Expansion + Integration — Candidate 001 — 2026-08-27

- Implemented the user-approved **1E-1 through 1E-3** content/integration pass under the rule **“Content extends the system that already owns its truth. Integration does not create a second owner.”** Phase 1E remains cross-system content work rather than a new System 32.
- Added `Phase1EOneStoryContentDresser.gd` and integrated it through the shared one-story building generator. The 18 baseline one-story System-19 profiles gain deterministic program-appropriate accents with a hard maximum of **two added accents per building**; the six protected historical reference archetypes remain outside the new dresser.
- Phase-1E dressed baseline output now records building content version 2 while the established structural profile definitions retain their profile identity. Existing System-19 deterministic replay, rotations, circulation and validation remain protected.
- Bound System-07B large visual geometry to the **real generated** `prop.deciduous_large` and `prop.traffic_light` semantics used by ordinary System-20 content. Historical `vegetation.deciduous_large` / `fixture.traffic_light` aliases remain supported for protected renderer fixtures.
- Existing System-20 outdoor morphology remains authoritative; Phase 1E does not create a competing exterior-generation owner. `verify/system20-local-area` remains green on the final executable.
- Expanded `LootItemCatalog` to **v3 / 97 physical item semantics**. New mundane stock broadens pantry/fresh food/drinks, medical/sanitation, office/school, hardware/tools/materials, electrical/utility, farm/outdoor, automotive-adjacent, industrial/workshop and contextual-junk vocabulary.
- Expanded `LootContainerProfileCatalog` to v2 with broader location-aware stock and explicit school, church, police and fire supply profiles. The System-24 invariant remains unchanged: **loot exists before you search for it**; search never rolls rewards into existence.
- Every shipped Phase-1E item registers positive System-13D physical weight. No generic stack/quantity system was introduced.
- Expanded `ItemFreshnessProfileCatalog` to **v2 / 10 explicit perishables**. Shelf-stable goods remain outside freshness state; no powered refrigeration, nutrition, sickness or treatment behavior is faked.
- Expanded System-31 icon coverage so all **97 current loot semantics** resolve intentionally. With STATS / INVENTORY / MENU, the semantic icon catalog reports **100 known semantics**.
- Added permanent `.github/workflows/phase1e-content-integration.yml` and `Phase1EContentIntegrationSmoke.gd`, then corrected the focused smoke parse defect exposed by the first CI run.
- Initial exact-head verification exposed two protected integration issues rather than being waived: 07B regression fixtures still used historical semantic aliases, and altered baseline building content required an explicit final content-version contract. Both were repaired while preserving the intended generated-world integration.
- Final verified executable: `6ad923d172f5a5434f94a7fdcc15da640a60a240`.
- All **19 required exact-head contexts** are green on that executable, including `verify/phase1e-content-integration`, `verify/system19-local-building`, `verify/system20-local-area`, `verify/system24-loot`, `verify/system30-item-freshness`, `verify/system31-semantic-ui-icons`, `verify/system07b-large-visual-geometry`, `verify/performance-architecture`, and `verify/pages-deploy`.
- No Crafting, Power/Refrigeration, nutrition/Health, Skills, Vehicles, combat or AI behavior was introduced as placeholder content metadata.
- Automated Phase-1E implementation is complete. A separate human visual/readability playtest of the richer content is still pending and is **not** being claimed by CI.
- Roadmap Phase 1 implementation is complete through 1E. **Phase 2 Crafting is the next bounded design target; its runtime implementation is not pre-authorized by this completion.**

## Playable Island Legacy Map + Ecology Seam Correction — 2026-08-27

- Fixed the actual remaining old-mini-map/green-belt defect rather than only moving the spawn.
- `temperate.island.region` is now v2. The central `rural.crossroads` site keeps its stable world identity/location but no longer reuses the raw world seed `20001`; its local seed is derived from world seed + site identity, so the playable island no longer regenerates the standalone historical 256×256 Rural Crossroads critique fixture.
- Tightened **island-only** settlement spacing to reduce the oversized several-hundred-cell countryside band while leaving protected `temperate.rural.region` v6 behavior unchanged.
- Hardened `rural.scattered` local-road planning with a bounded deterministic candidate search across legal lane-side/tail orientations. This fixed island-seed failures without rerolling seeds or changing inherited-road dimensions/topology.
- Added optional `AreaGenerationRequest.inherited_ecology_seed`. Globally projected island settlement requests receive the System-00D world seed for natural environmental dressing while retaining their normal site seed for roads, parcels, buildings and other local morphology.
- Added pure shared `NaturalEcologyField.gd`. Natural density patches and tree/shrub/rock family selection are evaluated from **world seed + absolute global cell**, so ecology no longer restarts at each 256×256 settlement/source origin.
- `OutdoorPropertyDressingPlanner` consumes the shared field only when upstream ecology context is present. Standalone System-20 fixtures without that context keep their historical local request-seed/local-coordinate behavior.
- `IslandSurfaceAreaGenerator` v3 now uses the same shared natural ecology field and the same rural/lush interior environmental vocabulary as settlement sites. Shore/ocean classification, road-clearance halos and source ownership remain unchanged.
- Expanded `IslandLegacySeamSmoke.gd` to prove the island central generated signature differs from the old standalone fixture, the central-to-small-town edge gap remains compact, the rectangular forest-floor palette break cannot return, and the same world-space natural `(cell, semantic)` set is produced whether the same land is planned as one rectangle or split into adjacent logical rectangles.
- Preserved System-00D roads/hydrology/bridges, System-19 building ownership, System-00F non-overlapping materialization sources, 128×128 technical streaming, WHAT/WHEN, rendering/input/UI and the no-recurring-world-scan performance boundary.
- Verified executable: `d33c69d6bd05f4c8fdbba62c6bd51bb16aad26ad`.
- All **17 required exact-head contexts** passed on that executable: `verify/system00d-global-world`, `verify/system00f-streaming-materialization`, Systems 19–31, `verify/performance-architecture`, and `verify/pages-deploy`.
- Automated verification proves deterministic identity/continuity and integration. Human visual playtest of the deployed island remains separate.

## Playable Island Continuity Correction — 2026-08-27

- Fixed the live complete-island DEV spawn so the survivor starts on inherited pavement beside the central crossroads instead of deriving spawn from the rural diner parcel/door.
- Upgraded `IslandSurfaceAreaGenerator` to v2 so the large spaces between settlement sites are no longer an undifferentiated lush-grass sheet: ordinary LAND now receives globally anchored land-cover variation plus deterministic temperate-coastal trees, shrubs and rocks.
- Natural island-surface dressing uses global cell identity, stays on physical LAND, and keeps a clearance halo around inherited regional roads; it adds bounded generation/materialization work and no per-frame/per-tick world loop.
- Restored inherited painted-road centerlines in island-surface materialization so regional roads no longer visually lose their yellow line when they leave a settlement source rectangle.
- Preserved the existing five-site System-00D settlement/road graph, hydrology, explicit bridges, non-overlapping 00F logical source partition and 128×128 technical streaming geometry.
- Expanded `CompleteIslandWorldPlanningSmoke.gd` so CI now fails if spawn returns to the diner entrance, ordinary island LAND becomes blank again, natural props invade road/non-land cells, or painted inherited roads lose their centerline outside settlement sources.
- Verified executable: `505535ea7fab555f7a1871afb9f2d1e2ff92331b`.
- All **17 required exact-head contexts** passed on that executable, including `verify/system00d-global-world`, `verify/system20-local-area`, `verify/system00f-streaming-materialization`, `verify/performance-architecture`, and `verify/pages-deploy`.

## System 31 Semantic UI Icons — Candidate 001 — 2026-08-25

- Implemented the approved Roadmap Phase 1C presentation system under the rule **“UI icons visualize existing semantic truth. They never define item identity, utility, freshness, or action legality.”**
- Added one dedicated `256x128` low-resolution SVG atlas with 16x16 logical cells, normally displayed at exact 2x / 32x32 nearest-neighbor scale.
- Added one shared Node-free `SemanticUiIconCatalog` with O(1) explicit semantic lookup and cached atlas-region textures. System 31 performs zero per-frame, per-tick, per-persistent-item or world-scan work.
- Explicitly mapped all current 71 `LootItemCatalog` item semantics plus `STATS`, `INVENTORY`, and `MENU`. Intentional glyph sharing is declared directly; there is no automatic family fallback.
- Unknown future semantics retain their real text and receive an explicit unknown glyph plus diagnostic rather than silently pretending to be supported.
- Integrated icon + text header controls into `CanonicalPlayerShell`; occupied hands and carried/nested inventory rows now use the same semantic icon vocabulary without changing pause, containment, stable ID, weight or freshness truth.
- Integrated the shared catalog into scavenging `CONTENTS` and `YOUR PACK` rows. Existing TAKE/STORE controls and System-12 legality/timing remain text-only and unchanged.
- Wired one shared catalog instance through the live composition. No icon identity was added to WHAT, loot, containment or freshness records/queries.
- Corrected the header icon-width application to Godot's theme-constant API before final exact-head verification.
- Added `.github/workflows/semantic-ui-icons.yml` and `SemanticUiIconsSmoke.gd`, covering all current mappings, explicit sharing, unknown fallback, atlas bounds, cache reuse, protected System-16/24/30 regressions and canonical startup.
- Current fully green executable head: `dc83ad10b7469a629fb2ac5d86c77d386b69434d`.
- All **17 required exact-head contexts** are green, including `verify/system31-semantic-ui-icons` and `verify/pages-deploy`.
- Roadmap Phase 1C is complete. **Phase 1D Large / Multi-cell Object Visual Geometry is the next bounded design target; its implementation is not pre-authorized by this completion.**

## System 29 World Interaction Affordance / Reach — Candidate 001 — 2026-08-24

- Implemented the approved Roadmap Phase 1A foundation under the rule **“A highlight explains an already-valid interaction. It never creates interaction truth.”**
- Added neutral `WorldInteractionReachQuery.CONTACT_FORWARD`, preserving the historical System-24 actor-footprint + one-cell-forward reach exactly with no diagonal/two-cell/through-wall/auto-turn expansion.
- Removed the old private `LootInteractionReach.gd`. `LootSearchActionService` and `LootWorldContainerAccessPolicy` now consume the shared System-29 reach contract; the live playable composition injects one shared reach-query instance into both paths.
- Added read-only `InteractionOffer` / `InteractionOfferProvider` contracts and `InteractionAffordanceQuery`. Providers own real mechanic availability; System 29 never infers a USE action from art, semantic names or proximity alone.
- Added the first real provider, `LootSearchInteractionOfferProvider`, which publishes `scavenge.search_container` / `SEARCH` only for real initialized System-24 searchable containers with valid current profile/reach state.
- Candidate discovery is bounded to WHAT OBJECT occupancy in the survivor's tiny reachable-cell set. No full-world entity scan and no per-object interaction Nodes are used.
- Player-facing highlight descriptors are filtered through current System-23 `VISIBLE` knowledge. `REMEMBERED` and `UNSEEN` targets do not reveal current usability; partially visible multi-cell targets expose only currently visible footprint cells.
- Added one event-driven `InteractionHighlightRenderer` at z=90, above live world lighting/weather and below System-23 perception z=100. It draws restrained warm/yellow-white pixel corner markers and contributes no physical light.
- Multiple real offers deduplicate to one target highlight while preserving action identities. Query/presentation work consumes zero WHEN ticks.
- Candidate 001 deliberately adds no universal Interact button, no tap-selection execution and no radial/list action menu.
- Added `.github/workflows/world-interaction-affordance.yml` and `WorldInteractionAffordanceSmoke.gd`, covering forward/behind/diagonal reach, multi-cell intersection, local-only discovery, real-vs-decorative offers, VISIBLE/REMEMBERED/UNSEEN filtering, partial visibility, deterministic dedup, zero-WHEN-tick presentation and facing-change behavior.
- First fully green System-29 foundation head: `9ccbb91f167c376b6ea4a4d7ff82ede3427ae122`.
- First fully green **playable-island integration** head: `5b88d9172df51561ea760913873f62bd2cdc422a`.
- All **14 required exact-head contexts** are green on the playable integration head, including `verify/system29-interaction-affordance` and `verify/pages-deploy`.
- Roadmap Phase 1A is complete. **Phase 1B Item Freshness / Spoilage is the next bounded design target; its runtime implementation is not pre-authorized by this completion.**

## System 28 Weather / Atmosphere — Slice C + screen-space presentation correction — 2026-08-24

- Implemented approved Weather Slice C on executable head `21014fe5915e47344b4b8d5f48e52fa69c386254`.
- Replaced the prior camera-compensated world-relative Weather presentation with the simpler player-approved architecture: **rain/fog/debris are a screen-space atmosphere overlay**. Camera movement now requests zero Weather redraws, advances zero presentation steps, never clears/reseeds the field, and cannot make Weather disappear during repeated movement.
- Focused regression sends forty rapid camera-position updates and reports `WEATHER_OVERLAY_CAMERA_REDRAWS=0`.
- Shelter-aware rain remains possible by mapping each current screen sample to the corresponding world cell only when sky-exposure rejection is needed. This lookup does not make the atmosphere world-anchored and Weather remains below System 23 so hidden geometry cannot leak.
- Added `LightningEvent` and upgraded Weather snapshot/state to schema v2 with deterministic scheduled/active lightning state.
- Storm lightning is scheduled through WHEN with a deterministic 30–120 tick normal delay. The physical flash lasts one WHEN tick; DEV `STRIKE` schedules a real future event rather than forcing a renderer-only whiteout.
- Added transient physical sky-light input to System 27. The same LightningEvent that drives the bolt physically brightens the illumination field, passes through existing window/opening portal logic and can genuinely change System 23 acquisition.
- Focused physical lightning fixture: storm-night exterior **0.025 -> 0.845** useful luminance during the flash; roofed interior through a real window portal reaches **0.356**.
- Added a stable-seeded low-resolution bolt presentation tied to the same LightningEvent. Its ~0.32 s cosmetic lifetime may outlast the one-tick physical flash without keeping physical illumination active.
- Thunder remains deliberately deferred. Current lightning has no honest strike cell, so inventing a spatial System 26 thunder origin would violate **Sound is physical; hearing is an estimate.** The future geographic strike seam is also where lightning damage/fire can attach.
- Moved the DEV Weather panel below the existing STATS / INVENTORY / MENU header row and above ordinary HUD/world presentation. Controls now include CLR, OVR, RAIN, STM, FOG, STRIKE and BLOW LEAF.
- `verify/system28-weather` now covers A+B+C plus protected System 27/26/23 regressions and canonical startup.
- All **13 required executable-head contexts** were green on `21014fe5915e47344b4b8d5f48e52fa69c386254`, including `verify/pages-deploy`.

## Canonical Roadmap through Beta — 2026-08-24

- Added `ROADMAP.md` as the canonical priority order after System 28.
- Normalized the user's explicit numbering as: **1 Items/readability, 2 Crafting, 3 Power+Water, 4 physical survival/health, 5 Moodlets, 6 Skills/interactions, 7 Vehicles, 8 AI+combat+outbreak, 9 final graphics/UI -> Beta.**
- Phase 1 includes spoilage, inventory/menu icons, proximity highlighting for actually usable nearby containers/objects, and broader/multi-cell world objects such as larger stoplights and four-cell/2×2 trees.
- Phase 3 locks a causal **three-tier** utility model: robust broad main facility, semi-frequent local substation/pump-station failures, and vulnerable local distribution/service damaged by cars/trees/etc. Standalone wastewater/sewer gameplay is removed from the active roadmap; existing generated wastewater data may remain inert until deliberate cleanup.
- Phase 4's earlier roadmap wording named stamina; this is superseded by the later same-day decision that **fatigue is the stamina/endurance concept and there is no separate stamina meter**. Death from exhaustion remains an intended eventual terminal consequence.
- Phase 5 expands Moodlets beyond labels: comfort, fear, boredom and escalating hunger/thirst/sleep states may create action-speed/capability consequences while underlying physical truth remains with its owning systems.
- Phase 6 replaces the current generic skill catalog with Awareness, Sneak, First Aid, Cooking, Carpentry, Mechanical, Electrical, Fishing and Farming. Hunting is deliberately emergent from Sneak + future shooting/combat proficiency + crafted trap placement, not a separate Hunting stat.
- Phase 6 also closes broad object interactions: powered TVs/appliances/switches use real power/state first, then feed real System 27 light and localized yellow-word sound/information presentation downstream.
- Phase 7 covers cars, trucks, motorcycles, bicycles and skateboards, with eventual Mad-Max-style physical modifications for cars/trucks.
- Phase 8 groups the late actor layer: infected/survivor/follower/raider AI, all combat, mood/context follower conversations and causal outbreak/population behavior. It remains multiple bounded system designs internally rather than one monolith.
- Phase 9 is the final graphics/UI pass: control placement, mobile/desktop usability, icons/readability, item/prop shadows and final polish. **Finishing Phase 9 is the planned Beta start gate.**
- Save/load, schema policy, large-scale profiling and persistence-backed streaming eviction remain non-numbered engineering gates inserted when needed without changing gameplay phase order.

## System 28 Weather / Atmosphere — Slice B — 2026-08-24

- Implemented the user-approved Weather B scope and folded in two A playtest defects reported with the approval: weather visibly trailed camera/player movement, and unrendered technical space appeared grey against System 23 true-black fog.
- Added `WeatherAtmosphericOpticsAdapter` as the neutral System 28 -> System 27 seam. It maps continuous precipitation/cloud/fog/wetness values into the existing `AtmosphericOptics` contract rather than making Lighting switch on Weather profile names.
- Candidate clear normalizes to essentially neutral atmosphere. Increasing cloud/rain/fog suppresses direct/diffuse sky appropriately, attenuates local light, increases scatter/extinction, and adds a restrained cool atmospheric tint. System 27 remains the physical illumination/shadow/portal owner.
- Real analytic Weather wetness now feeds the existing System 27 `wet_surface_factor`, so the already-implemented restrained wet-road/surface glow response uses physical WHEN-driven wetness rather than a DEV preset or rain-particle count.
- Extended System 27's acquisition policy from light-only range to physical **light + atmospheric visibility extinction**. Opaque System 23 LOS still resolves first; atmosphere can only reduce the 12-cell geometric envelope and radius-1 near awareness remains protected.
- Focused full-light visibility fixture: clear remains **12 cells**; representative physical fog extinction reduces the same bright-condition useful range to **5 cells**.
- Added `WeatherAcousticEnvironmentModifier` through System 26's existing neutral environment seam. Candidate B treats rain/wind as competing background noise: precipitation/wind raise hearing detection threshold and modestly reduce localization quality while adding no fake repeated rain emissions and no invented per-cell absorption cost.
- Representative storm fixture produces a **+19 detection-threshold addition** relative to the underlying hearing decision and worsens localization quality versus clear conditions.
- Physical Lighting/Perception refresh only on quantized `WeatherService.weather_changed` environment revisions. The 20 Hz cosmetic rain/fog/debris phase causes zero physical System 27/23 recomputes.
- Fixed weather movement lag without raising the 20 Hz simulation/animation budget: camera presentation changes now request an immediate compensated Weather redraw using camera/world offset. That redraw advances zero Weather presentation steps and zero WHEN ticks; shelter masking still resolves the correct world cell for each coarse rain sample.
- Render-window recentering combines `visible_origin * cell_pixels + camera_local_position`, preventing technical window shifts from becoming an atmospheric jump.
- Fixed the visible grey unrendered/chunk boundary by setting Godot's default viewport clear color to **true black**. No fake terrain, expanded render truth or System 23 streaming knowledge was introduced.
- Added `WeatherEnvironmentIntegrationSmoke.gd` and expanded `verify/system28-weather` to cover A+B boundaries, continuous optics, real wetness, fog visibility, rain/wind hearing masking, camera compensation, black unrendered fallback, System 27/26/23 regressions and canonical startup.
- System 27's optimized structural regression remained intact on the B runner: 7,680 field cells, 1,676 local-emitter candidates and 688 optical-ray candidates; representative light rebuild ~2.55 ms and focused illumination-aware perception ~9.55 ms on that runner.
- First fully green executable Weather B head: `db4681dc53ce6955e9585f4f5b380fe8efef634c`.
- On that exact executable head all **13 required contexts** were green, including `verify/system28-weather`, System 23/26/27 and `verify/pages-deploy`.
- Slice C lightning/physical flash/pixel bolt/thunder remains deferred; no fake lightning was added in B.

## System 28 Weather / Atmosphere — Slice A — 2026-08-24

- Implemented the user-approved Weather A scope with the explicit direction that weather be **low-resolution, always atmospherically alive, and low overhead**. Physical Weather and presentation-time animation remain deliberately separate.
- Added `WeatherProfile`, `WeatherState`, and `WeatherService`. Candidate 001 profiles are `clear`, `overcast`, `rain`, `storm`, and `fog`, with continuous precipitation/cloud/fog/wind values underneath the readable profile.
- Weather transitions are deterministic and event-driven through WHEN. System 28 schedules one meaningful transition event rather than running a per-tick weather simulation loop; current continuous values are analytically sampled from authoritative tick position.
- Added analytic wetness using an anchor value/tick plus profile wetting/drying rates. Rain/storm increase wetness only when WHEN advances; clear weather dries only when WHEN advances; cosmetic raindrops have no relationship to physical wetness.
- Added 12-band quantized environment signatures so future Slice B Lighting/Hearing consumers can refresh on meaningful physical Weather changes rather than every tiny interpolation or presentation frame.
- Added Weather snapshot schema v1 preserving current/target profile, transition ticks, wetness anchor, revision/serials, scheduled event serial and deterministic future transition state.
- Added cached `SkyExposureQuery` for Slice A precipitation masking. Current structure-envelope approximation treats structure cells—including door/window semantics—as enclosure boundaries, so opening a door does not magically make the whole room unroofed.
- Added one `WeatherPresentationRenderer` at z=50, above physical lighting and below System 23 Perception. Shelter-aware rain therefore cannot reveal hidden roof geometry through true-black unexplored fog.
- Weather presentation intentionally creates **zero per-raindrop/per-fog/per-debris child Nodes**. It draws one coarse procedural low-resolution field with a virtual-axis cap of 256 and nearest/blocky visual language while System 27 lighting remains smooth.
- Continuous rain/fog presentation targets **20 Hz / 50 ms** independent of display FPS. Long-frame presentation catch-up is capped to four cosmetic steps and advances zero WHEN ticks.
- Rain uses at most 180 coarse candidate streaks, 1–3 weather pixels long, with wind-driven slant and shelter rejection. Fog uses at most 36 chunky low-alpha drifting patches.
- Added calm-day ambient motion: presentation-only leaf, paper, or dust events. Calm clear weather normally has zero active debris and at most one; breezier weather may use two; hard maximum is three. These have no WHAT identity, inventory, collision, System 26 sound or AI meaning.
- Clear weather stops requesting redraws between ambient events, retaining only the cheap presentation countdown/branch until a leaf/paper/dust event starts.
- Added `WeatherDevControls`: CLEAR/OVERCAST/RAIN/STORM/FOG plus `BLOW LEAF`. The Rural Crossroads critique composition starts in DEV RAIN so Weather A is visible immediately after deployment.
- Slice A deliberately does **not** feed System 27 `AtmosphericOptics`, System 26 acoustic masking, or System 23 fog/rain extinction yet; those remain Slice B. Lightning/physical flash/bolt/thunder remain Slice C.
- Added `.github/workflows/weather.yml` and `WeatherSmoke.gd`. Focused structural output on the first fully green executable head: `WEATHER_VIRTUAL_PIXELS=1296`, `WEATHER_ACTIVE_DEBRIS=1`, `WEATHER_PRESENTATION_UPDATES=4` for a deliberate 0.5 s long-frame input.
- Existing optimized System 27 regression remained intact on the Weather owner runner: 7,680 active field cells, 1,676 local-emitter candidates, 688 optical-ray candidates; representative physical-light rebuild measured ~2.53 ms on that runner.
- First fully green executable Weather A head: `dcb400b8507c23a2fc5bdaecf551bc5c0512acce`.
- On that exact executable head all **13 required contexts** were green: `verify/system28-weather`, `verify/system27-physical-lighting`, `verify/system26-spatial-sound`, `verify/system25-world-time-light`, `verify/system24-loot`, `verify/system23-perception`, `verify/system22-area-critique`, `verify/system21-camera-view`, `verify/system20-local-area`, `verify/system19-local-building`, `verify/system00f-streaming-materialization`, `verify/system00d-global-world`, and `verify/pages-deploy`.

## System 27 Physical Lighting — Pre-Weather Optimization — 2026-08-24

- Implemented the requested bounded optimization pass before adding Weather, without reducing lighting resolution, useful ranges, shadow/portal rules, visual quality, or illumination-aware perception behavior.
- `PhysicalLightingService` now caches active-field materialized cells, structure classification, optical transmission and portal candidates by the appropriate world/bounds/door revisions instead of repeatedly rediscovering the same geometry during light evaluation.
- Local emitter work is now spatially bounded before expensive range/cone/optical-ray checks. Flashlight, lamp, streetlight and neon evaluate only the intersection of their useful-range square with the active field rather than scanning every active-field cell first.
- Emitter-set signatures are computed only when source adapters supply a changed emitter set. Ordinary illumination samples compare a compact emitter revision rather than rebuilding joined signatures repeatedly.
- Added `prepare_query()` / `illumination_at_prepared()` for immediate non-mutating batch readers. `PhysicalLightingPresentationRenderer` prepares System 27 once per map refresh instead of rerunning revision checks for every visible light-map cell.
- The presentation renderer now reuses its multiply/glow `Image` buffers while dimensions remain unchanged instead of allocating two fresh images per lighting refresh. Output maps/shaders are unchanged.
- Added durable work-count instrumentation and an 80×96 critique-scale regression. With four representative local emitters, the optimized solver sees 7,680 materialized cells but considers only **1,676 emitter candidate cells**, of which **688** reach optical-ray evaluation. The naive previous full-field-per-emitter loop would have visited **30,720** field cells before those checks.
- On the fully green executable head, representative 17×17 changing-flashlight rebuild measured **2,674.32 µs (~2.67 ms)** and focused illumination-aware perception measured **9,255.77 µs (~9.26 ms)**, versus the earlier Slice C reference **4,230.32 µs (~4.23 ms)** / **11,838.67 µs (~11.84 ms)**. A preceding optimized CI runner measured ~1.73 ms / ~6.49 ms, so timing remains treated as runner-noisy while the bounded work-count is the stable proof.
- Fully green optimized executable head: `5958d887807e5b64c9fc4cf5d3d45c7dfd4083d2`.
- On that exact executable head all twelve required contexts were green, including `verify/system27-physical-lighting`, System 23/26 regressions and `verify/pages-deploy`.

## System 28 Weather / Atmosphere — Design Draft — 2026-08-24

- Added `SYSTEM_DESIGNS/28_WEATHER_ATMOSPHERE.md` as **DRAFT — awaiting approval**. No Weather runtime code is implemented or authorized yet.
- Proposed core rule: **Weather is simulation truth; weather animation is presentation.** Physical weather transitions/wetness/light/sound consequences advance only through WHEN, while low-resolution pixel rain/fog may continue animating cosmetically during the player's decision pause.
- Candidate 001 proposes clear, overcast, rain, storm and fog; compact deterministic precipitation/cloud/fog/wind/wetness state; low-res nearest-scaled precipitation/fog; shelter-aware rain; System 27 `AtmosphericOptics` integration; System 26 rain/wind masking; and future visibility-extinction integration.
- Lightning is designed as a real deterministic Weather event. Its flash feeds System 27 physical illumination so windows/doors/interiors and actual System 23 acquisition respond to the same event; the visible bolt is a stable-seeded chunky pixel presentation tied to that event rather than a separate fake screen flash.
- Lightning damage/fire remains deferred until those real owning systems exist. Thunder is a future/narrow System 26 consumer of the same event and must retain normal uncertain hearing/localization.

## System 26 Spatial Sound / Hearing — Onomatopoeia + Cue Lifetime Refinement — 2026-08-24

- Implemented the user direction **“lets replaces some or most of them with their onimonapias. like *step step* for seen noises they fade after a sec, for unseen sounds they stay in the aprrox position until the next unpause.”** Physical propagation, hearing thresholds and localization uncertainty are unchanged.
- Replaced most recognized generic movement/door labels with readable onomatopoeia while keeping low-confidence recognition honest and broad: Walk `NOISE -> *scuff* -> *step step*`; Run `NOISE -> *thump thump* -> *step step step*`; normal door `NOISE -> *thunk* -> *creak*`; loud door `NOISE -> *BANG* -> *SLAM*`.
- `HeardSoundObservation` now preserves display-word case/punctuation instead of forcing all text uppercase. Observation snapshot structure remains unchanged.
- `SpatialSoundService.presentation_descriptors()` now supplies stable opaque `cue_id` and `group_id` values. They allow presentation replacement/suppression while still exposing neither exact source cell nor hidden source entity ID.
- Added a neutral listener action-start lifecycle signal. Player presentation uses it to identify the next decision unpause without changing Movement/Door source semantics or turning the renderer into a WHEN owner.
- Player cue lifetime now uses the **perceived/estimated cue cell's System 23 visibility state**, not hidden exact source visibility. This preserves the rule that presentation never gets extra source truth merely to decide how long a word should remain.
- If that perceived cell is `VISIBLE` when the cue arrives, the yellow word is a short transient: full-strength briefly, fading after ~350 ms and reaching zero by ~1 real second. The real-time timer is presentation-only, runs only while a visible cue is fading and advances zero WHEN ticks.
- If the perceived cell is `REMEMBERED` or `UNSEEN`, the cue latches at that same uncertain location while the player is paused deciding. It may outlive the underlying transient heard observation's normal tick expiry for display purposes, then clears when the controlled listener starts the next action/unpauses.
- Repeated cues in the same opaque group replace/update one marker instead of leaving a breadcrumb trail. Cleared/faded cue IDs are suppressed until the upstream observation disappears so an already-dismissed marker cannot instantly reappear because of observation-store lifetime.
- Underlying System 26 `HeardSoundObservation` remains authoritative listener knowledge for future AI/save semantics and still ages only by WHEN ticks. The seen fade/unseen latch is player presentation only; future AI never receives the renderer's latch as memory.
- Extended `SpatialSoundSmoke.gd` and `PerceptionFogMemorySmoke.gd` to prove onomatopoeia vocabulary, opaque descriptor identity, no exact-source leakage, one-second fade math, listener-unpause lifecycle, unseen marker persistence after upstream expiry/removal, configured VISIBLE-vs-UNSEEN classification, unpause clearing and no visual exploration.
- First fully green executable refinement head: `aa5e1b622c8efe555d22e5d56514b9490776be16`.
- On that exact executable head all twelve required contexts were green: `verify/system27-physical-lighting`, `verify/system26-spatial-sound`, `verify/system25-world-time-light`, `verify/system24-loot`, `verify/system23-perception`, `verify/system22-area-critique`, `verify/system21-camera-view`, `verify/system20-local-area`, `verify/system19-local-building`, `verify/system00f-streaming-materialization`, `verify/system00d-global-world` and `verify/pages-deploy`.

## System 27 Physical Lighting / Illumination / Shadows — Slice C — 2026-08-23

- Implemented the user-approved Slice C under the explicit direction **“we keep it for now, lets move on and see if it gets worse the more systems we add. approved for C.”** Current lighting/perception cost is therefore measured and retained rather than pre-optimized before real Actor AI/population workloads exist.
- Added neutral `VisualAcquisitionProvider.gd` to System 23. Geometry-only pass-through remains the default so historical/focused Perception compositions do not silently import or depend on System 27.
- Added `IlluminationVisualAcquisitionProvider.gd` as the System 27 -> System 23 adapter. It uses the existing target-cell physical-light useful-range policy; System 23 still owns `VISIBLE`, memory refresh and observer knowledge.
- `ObserverPerceptionService` now resolves **geometry first -> acquisition second -> memory last**. Only geometric candidates accepted by the configured acquisition provider enter `VISIBLE`, refresh environmental memory or refresh current actor observations.
- The live canonical Rural Crossroads composition now injects the System 27 illumination provider. A distant geometrically clear target may therefore remain unseen in darkness, become current truth when physically illuminated, and return to stale REMEMBERED knowledge when light falls.
- Third-party physical light can illuminate a target for the controlled observer. Bright targets still cannot be acquired through opaque geometry because System 23 LOS is resolved before the light gate.
- Radius-1 near awareness remains protected through the existing Candidate 001 range policy. Current light response remains 2 useful cells at luminance 0.0 toward the 12-cell geometric maximum at luminance 1.0 with `sqrt(luminance)` response.
- The first C implementation passed the focused illumination/perception contract but failed canonical startup because the new provider initially required a lighting field that Slice B's renderer had not established yet. Investigation exposed the more important architecture issue that gameplay lighting could not depend on camera/render initialization.
- Repaired the boundary so `IlluminationVisualAcquisitionProvider` guarantees the observer's complete physical-light query envelope itself. Candidate 001 uses a 25×25 observer-centered field when the current presentation field does not already contain the survivor's full 12-cell geometric vision envelope.
- Normal camera-following play reuses the existing presentation field when it already contains that envelope; camera panning elsewhere triggers the bounded observer query field instead. Camera position can therefore neither grant nor remove gameplay vision, without forcing an unconditional second lighting rebuild every normal turn.
- System 25 ambient changes now also request observer recomputation because time-of-day light can change current visual acquisition even when no actor or door moved.
- Added `IlluminationPerceptionSmoke.gd` and extended both System 23 and System 27 workflows. Coverage proves dark-target rejection, protected near awareness, no memory refresh from unacquired darkness, lit-target acquisition, stale actor/environment memory after losing light, third-party illumination, opaque-geometry priority, camera-independent query demand, zero WHEN-tick cost and canonical startup.
- First fully green executable Slice C head: `09d1c059760c06ef9791c4d405746caddc107dcf`.
- On that exact executable head all twelve required contexts were green: `verify/system27-physical-lighting`, `verify/system26-spatial-sound`, `verify/system25-world-time-light`, `verify/system24-loot`, `verify/system23-perception`, `verify/system22-area-critique`, `verify/system21-camera-view`, `verify/system20-local-area`, `verify/system19-local-building`, `verify/system00f-streaming-materialization`, `verify/system00d-global-world` and `verify/pages-deploy`.
- Performance markers on the fully green System 27 runner: representative 17×17 physical-light rebuild **4,230.32 µs (~4.23 ms)**; legacy geometry-only FOV **4,058.41 µs (~4.06 ms)**; focused illumination-aware perception recompute **11,838.67 µs (~11.84 ms)**. These are explicit baselines for later Actor AI/population profiling, not a request to optimize now.

## System 27 Physical Lighting / Illumination / Shadows — Slice B — 2026-08-23

- Implemented the user-approved Slice B following the exact approval **“Approved B.”** Slice B is presentation downstream of the already-authoritative Slice A physical-light backend; rendering does not become gameplay or AI lighting truth.
- Added `PhysicalLightingPresentationRenderer.gd` as the focused visible-world lighting composite. It consumes `PhysicalLightingService` illumination samples and active emitter descriptors without re-solving or inventing physical light.
- Added a low-resolution tactical light-map presentation path rather than per-pixel gameplay physics. One RGBA map carries physical useful luminance + tint into a multiplicative darkness/color pass; a second map carries local/portal/glare/scatter energy into an additive glow/scatter/reflection pass.
- Added `physical_lighting_multiply.gdshader` with edge-aware neighborhood smoothing. Similar light values blend softly, while large physical illumination discontinuities preserve hard tactical shadow boundaries instead of visually bleeding light through walls/closed doors.
- Added `physical_lighting_glow.gdshader` for soft local-light halo, portal glow, atmosphere scatter and a restrained wet-surface reflection cheat driven by the existing `AtmosphericOptics.wet_surface_factor`.
- Active emitter cells receive emissive-core energy using the canonical emitter profile tint/base luminance. Flashlight, warm lamp/streetlight and blue neon therefore produce materially different visible washes from the same physical source descriptors.
- Inserted physical lighting at renderer-stack z=40, above live ground/structures/props/actors and below System 23 Perception at z=100. True-black UNSEEN and stale REMEMBERED presentation therefore remain the final knowledge mask and hidden current lights cannot leak unseen world truth through glow.
- The canonical Rural Crossroads critique build now constructs the real `PhysicalLightingService` and visual renderer. System 25 daylight changes refresh both remembered-fog presentation and current visible-world physical lighting.
- Added clearly labeled `DemoLightingSourceAdapter.gd` because real batteries, equipment toggles, electrical switches/utilities and Weather do not exist yet. It supplies an always-on player-following flashlight plus fixed diner lamp/neon/streetlight descriptors solely so Slice B can be exercised; it does not claim canonical power/battery state and can be replaced later without changing the solver or renderer.
- The DEV flashlight follows the controlled actor's real WHAT cell/facing, so turning/moving changes the physical emitter descriptor and the rendered beam/shadow field rather than rotating a decorative overlay.
- Current physical shadows are driven by the backend's implemented structure/door/window optical truth. Arbitrary furniture/prop optical occlusion is not faked; adding optical-material classification for props remains a later System 27 refinement.
- Slice C remains separate: current System 23 visual acquisition still uses its geometric LOS envelope and does not yet apply the already-implemented target-light useful-range policy. Visible darkness is now real presentation; darkness affecting what becomes `VISIBLE` comes next in Slice C.
- Added `PhysicalLightingPresentationSmoke.gd` and extended `.github/workflows/physical-lighting.yml`. Verification proves shader/import validity, light-map creation, rain wetness input, fog scatter input, zero-WHEN-tick presentation rebuilds, DEV source tracking and—critically—that visual flashlight shadow contrast comes from backend illumination behind a real wall rather than a decorative beam.
- First fully green executable Slice B head: `a7a95466e70853d9abbd5de9ca1a1d5610672eaf`.
- On that exact executable head all twelve required contexts were green: `verify/system27-physical-lighting`, `verify/system26-spatial-sound`, `verify/system25-world-time-light`, `verify/system24-loot`, `verify/system23-perception`, `verify/system22-area-critique`, `verify/system21-camera-view`, `verify/system20-local-area`, `verify/system19-local-building`, `verify/system00f-streaming-materialization`, `verify/system00d-global-world` and `verify/pages-deploy`.
- Slice A representative 17×17 moving/revision-changing flashlight rebuild on this runner measured **4,085.20 µs average (~4.09 ms)**. The full 80×96 canonical critique build also passed startup with the Slice B presentation stack enabled. Many simultaneous moving emitters remain an explicit future profiling/caching seam before population-scale assumptions.

## Prior changelog

Detailed history through System 27 Slice A is preserved in `CHANGELOG_ARCHIVE_THROUGH_SYSTEM27_SLICE_A.md`.

Earlier history remains in `CHANGELOG_ARCHIVE_THROUGH_2026-08-22.md` and `CHANGELOG_ARCHIVE_THROUGH_2026-08-17.md`.