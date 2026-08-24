# Tick Survival Lab — System 27 Physical Lighting / Illumination / Shadows

Status: **DRAFT — awaiting approval**

User direction, 2026-08-23:

> **“take your time. this and actor AI are the two places this game will really stand out. give me some kind of really cool lighting that can be effected by weather, time of day, local light level inside buildings etc.”**

Follow-up clarification:

> **“we also need to do the actual backend lighting simulation, which effects vision cone and npc ai and stuff.”**

System 27 is the proposed authoritative physical-lighting domain for Tick Survival Lab.

Core rule:

> **Light is physical. Vision is observer-specific. Rendering visualizes lighting; gameplay and AI never read rendered pixels to decide what is illuminated.**

System 27 deliberately has two coordinated layers:

1. a deterministic, headless **physical illumination backend** that produces world-light truth for perception and future AI;
2. a replaceable **presentation backend** that turns the same source/occluder descriptors into darkness, colored glows, flashlight beams, portal spill and shadows.

The lighting system must still be useful with no camera and no GPU.

---

## 1. Goals

System 27 should make lighting one of the game's identity systems rather than a global tint.

Target experience:

- smoothly changing dawn/day/dusk/night from System 25;
- clear, overcast, rain, fog and storm conditions materially changing light;
- outdoor and indoor light levels being different for physical reasons;
- daylight entering buildings through windows/open doors instead of magically filling every room;
- interior lights spilling outward through windows/open doors at night;
- flashlight/headlamp beams visibly existing in the world;
- walls, doors and major props casting believable 2D shadows;
- lamps, streetlights, vending machines and neon signs creating colored pools and halos;
- wet nighttime surfaces carrying low-cost colored reflection effects;
- fog making light shafts/halos more visible while reducing useful transmitted light;
- darkness reducing what the player can currently acquire inside the existing geometric vision cone;
- future survivors/infected/animals using the same illumination truth instead of night-vision cheats;
- future AI being able to notice bright emitters or illuminated targets without receiving hidden source truth for free.

System distinction:

- **System 23 geometry:** can this observer potentially see through the current geometry?
- **System 27 lighting:** how much physical light reaches this world location, from where, and with what broad color?
- **observer perception:** given geometry + lighting + observer capability, what current truth is actually acquired?

---

## 2. Ownership

System 27 owns:

- deterministic local illumination fields/queries;
- sky/direct/local light composition downstream of System 25;
- semantic light-emitter profiles;
- deterministic light falloff;
- optical transmission through walls/doors/windows;
- local-light occlusion/shadow truth at tactical-cell resolution;
- interior sky-exposure derivation through an injected provider;
- window/door portal-light transmission;
- short-range diffuse/bounce approximation;
- merging multiple physical light contributions;
- dominant light color/direction summaries;
- atmospheric-optics input contract for future weather;
- source-availability input contract for future electricity/battery/fuel/fire owners;
- light and occluder descriptors consumed by presentation;
- a lighting renderer/backend that may use Godot 2D lights/shadows/shaders;
- semantic shadow profiles for major props where footprint-only shapes are insufficient.

System 27 reads but does not own:

- WHERE coordinates/facing/footprints/structure axis;
- WHAT terrain/entities/placements;
- Door State OPEN/CLOSED truth;
- System 25 time/daylight;
- Art Catalog semantic selections;
- future Weather atmosphere state;
- future electrical/generator/battery/fuel state;
- future equipment/item-use state that decides whether a portable light is actually on.

System 27 does **not** own:

- System 23 visual memory/observer knowledge;
- actor AI decisions;
- weather simulation;
- electrical-grid simulation;
- item-use/toggle actions;
- batteries/fuel quantities;
- building generation;
- construction/roof persistence as a general mechanic;
- wall-clock/frame-time simulation advancement;
- save-file orchestration.

Canonical dependency direction:

`WHEN -> System 25 -> atmosphere/source providers + WHERE/WHAT/Door -> System 27 -> System 23 observer acquisition -> player/NPC knowledge`

Rendering consumes System 27 after physical truth is resolved; it never sits in that causal chain.

---

## 3. Authoritative backend: `IlluminationSample`

The central public gameplay query is a deterministic world-space illumination sample independent of camera/GPU.

Candidate `IlluminationSample` fields:

- global cell;
- sky/diffuse contribution;
- direct/celestial contribution;
- portal contribution;
- local/artificial contribution;
- normalized useful luminance;
- broad RGB/light tint;
- dominant incoming cardinal/intercardinal direction when meaningful;
- glare/emissive pressure summary;
- atmosphere/scatter summary;
- world tick / lighting revision provenance.

Normalized luminance is gameplay-relative, not fake calibrated lux.

Suggested range:

- `0.00` — effectively no useful light;
- `0.02–0.08` — deep darkness / weak night ambient;
- `0.10–0.25` — dim but navigable/adaptable;
- `0.25–0.60` — ordinary useful room/outdoor light;
- `0.60–1.00` — bright daylight/strong local light.

Presentation energy may exceed `1.0` for HDR-looking glow. Gameplay samples remain normalized.

Core query shape:

`illumination_at(cell) -> IlluminationSample`

Additional neutral queries may include:

- `luminance_at(cell)`;
- `dominant_light_direction_at(cell)`;
- `light_signature_at(cell)` for observer-perception composition;
- bounded field snapshot/query for AI/perception batches.

---

## 4. Backend decomposition

The backend should not recompute one giant global lightmap every tick.

Candidate components:

### 4.1 `SkyExposureField`

Topology-derived, mostly static.

Answers how directly a cell is exposed to outdoor sky versus under an enclosed structure/roof approximation.

Cached until relevant structure topology changes.

### 4.2 `OutdoorLightState`

Cheap scalar/color state derived from:

- System 25 daylight/time;
- atmosphere/weather optics.

Time/weather changes update these scalars without rebuilding static geometry fields.

### 4.3 `PortalTransferField`

Cached geometry influence from windows/openings into enclosed space.

The geometric transfer shape can remain cached while current outdoor intensity/color simply rescales it.

### 4.4 `LocalEmitterField`

Per active local source or small grouped source set.

Cache key includes:

- emitter transform/profile;
- relevant optical-topology revision;
- source-state revision where necessary.

A flashlight field therefore only needs a geometric rebuild when its actor moves/turns, the flashlight toggles/profile changes, or nearby optical geometry changes.

### 4.5 `IlluminationComposite`

Combines current sky/direct/portal/local contributions into one queryable local field.

Consumers get O(1)-style cell samples after the bounded field is current.

---

## 5. Daylight / sky / direct-light model

System 25 remains authoritative for world-clock interpretation and baseline daylight.

System 27 splits daylight into two physical-looking components.

### 5.1 Diffuse sky light

Broad outdoor illumination that:

- fills exposed outdoor cells;
- keeps outdoor shadows from being absolute black;
- enters buildings indirectly through portals;
- is strongly affected by cloud/fog/storm conditions.

### 5.2 Direct celestial light

Stronger directional light used for:

- bright clear-day contrast;
- direct window/door shafts;
- stylized outdoor sun shadows;
- time-dependent direction/length.

Clear noon: high diffuse + high direct.

Overcast noon: moderate/high diffuse + low direct.

Storm noon: low diffuse + near-zero direct.

Night: low cool diffuse baseline; no requirement for strong moon shadows in Candidate 001.

### 5.3 Time-of-day color

Presentation/gameplay tint metadata may smoothly transition:

- dawn: warm direct light + cool residual sky;
- day: near-neutral direct light and subtle cool sky;
- dusk: warm/orange direct light collapsing toward cool ambient;
- night: restrained desaturated blue-gray, not saturated arcade-blue.

### 5.4 Stylized solar direction

System 27 may derive a presentation/gameplay direct-light direction from System 25 day fraction without claiming astronomical accuracy.

Intended effect:

- long shadows around dawn/dusk;
- shorter shadows around midday;
- smooth directional change with simulation time.

Latitude/season/true solar ephemeris remain future profile inputs.

---

## 6. Weather / atmosphere contract

System 27 must not import a future Weather implementation.

Proposed neutral `AtmosphericOpticsProvider` snapshot:

- diffuse-sky transmission multiplier;
- direct-light transmission multiplier;
- local-light distance/extinction multiplier;
- fog/haze scatter strength;
- sky/light tint modifier;
- wet-surface factor for rendering;
- optional current visibility-extinction pressure;
- revision/tick provenance.

Null/default provider = clear weather.

### 6.1 Overcast

- suppress direct sunlight heavily;
- soften outdoor shadows;
- reduce contrast;
- retain broad diffuse daylight instead of turning noon into night.

### 6.2 Rain

- modest daylight/contrast loss;
- modest local-light scatter increase;
- wet-surface presentation factor;
- neon/streetlights/headlights produce stronger-looking pavement reflections.

### 6.3 Fog / mist

- increases local-light extinction with distance;
- reduces useful long-range illumination;
- increases visible halo/shaft scatter;
- later contributes to System 23 visual acquisition loss independent of darkness.

Result: the flashlight beam becomes visually more obvious in fog while actually becoming less useful at long range.

### 6.4 Storm

- low sky/direct light;
- weather may publish real lightning illumination events later;
- lightning flash must be a physical tick-timed light event, not a renderer-only reveal.

Weather animation may continue cosmetically while the simulation is paused, but the authoritative lighting/weather state does not advance unless WHEN advances.

---

## 7. Interior / sky-exposure model

A noon scalar of `1.0` must not fully illuminate every room.

System 27 consumes a replaceable `SkyExposureProvider`.

### 7.1 Candidate 001 structure-envelope provider

Until an explicit roof/construction owner exists, derive roof/enclosure from current structure topology.

Proposed algorithm:

1. choose a bounded world-space lighting neighborhood around active demand, independent of camera edges;
2. treat wall/door/window structure cells as envelope boundaries for **roof classification**, regardless of current door OPEN/CLOSED state;
3. flood outside-space from the neighborhood perimeter through non-structure cells;
4. cells not reachable from outside through that envelope are treated as roofed/enclosed baseline cells;
5. cache the result until relevant structure topology changes.

This intentionally differs from ordinary movement/LOS:

- opening a door does not remove the roof;
- a window opening does not make the room outdoor sky;
- actual light still enters through those portals separately.

Known limitation:

- a deliberately roofless enclosed courtyard cannot be distinguished from a roofed room by structure envelope alone.

A future explicit Roof/Shelter/Construction provider may replace this heuristic without changing System 27 consumers.

### 7.2 Interior baseline

Roofed cells receive:

- a very low indirect floor;
- portal-transmitted outdoor light;
- local artificial light;
- short-range diffuse spill from illuminated adjacent spaces.

They do **not** receive full outdoor sky light.

Expected emergent result:

- windowed living room: reasonably bright by day;
- central hallway: dim;
- bathroom/storage room with no window: dark;
- open front door: obvious bright portal;
- at night, a powered room can become brighter than the street outside.

---

## 8. Windows and doors as light portals

Openings are physical light interfaces, not only LOS flags.

Candidate transmission classes:

- OPEN exterior/interior door: high direct transmission;
- CLOSED ordinary door: near-zero direct transmission;
- intact window: substantial but attenuated direct transmission;
- wall: zero direct transmission;
- malformed/unknown structure: fail-dark/conservative;
- future curtains/boards/broken glass modify the same profile.

### 8.1 Daylight entering

Outdoor light at an exterior portal seeds an interior contribution.

Two components may exist:

1. **direct portal ray/shaft** — sharper and direction-dependent;
2. **diffuse portal spill** — short-range, lower-energy bounce approximation that may turn corners with aggressive decay.

This creates bright rectangles/wedges near windows and increasingly dark interiors without real global illumination.

### 8.2 Artificial light exiting

Portal transmission works outward too.

Examples:

- floor lamp beside a window colors the wall/sidewalk outside;
- lit convenience store spills through storefront glass;
- opening a lit room's door throws light into a dark hall;
- closing that door removes the spill after the truthful state change.

Portal lighting is a signature System 27 effect.

---

## 9. Local emitter profiles

System 27 defines semantic light profiles, not a generic radius.

Proposed shapes:

- `OMNI` — lamp, lantern, flare;
- `CONE` — flashlight, headlamp, work light, headlights later;
- `STRIP` — fluorescent/neon source approximation;
- `AREA` — canopy/large-room source approximation;
- `PORTAL` — transmitted light interface;
- `GLOBAL_SKY`;
- `GLOBAL_DIRECT`.

A `LightEmitterProfile` should define at least:

- physical shape;
- gameplay useful range;
- presentation range;
- base luminance;
- color/tint;
- falloff;
- cone angle/soft edge for directional sources;
- optical transmission class;
- whether it casts presentation shadows;
- shadow softness class;
- whether it gets a larger non-shadowed halo;
- whether atmospheric scatter may reveal a shaft;
- optional deterministic flicker profile;
- source-availability requirement.

System 27 uses active emitter descriptors supplied by source adapters/providers. It does not duplicate the fact that a lamp switch, generator, battery or fuel source is on.

---

## 10. Existing semantic hooks

Current project content already provides useful semantic anchors.

Art Catalog includes light-adjacent presentation semantics such as:

- neon sign;
- lamp / floor lamp;
- streetlight;
- vending machine;
- traffic/beacon-style fixtures;
- held flashlight, headlamp, lantern, glow stick and road flare artwork.

Loot currently includes:

- `item.tool.flashlight`;
- `item.electrical.batteries_pack`;
- `item.industrial.work_light`.

Lighting behavior is attached by semantic source adapters/profiles, never by inspecting atlas pixels/indices.

A sprite may look emissive; only current source truth decides whether it physically emits light.

---

## 11. Direct-light transmission / tactical shadow backend

Gameplay shadows are deterministic grid truth, not Godot shadow-map samples.

Candidate local-light solver:

1. build candidate cells from source range/shape;
2. trace deterministic supercover/grid optical paths from emitter to candidate cells;
3. multiply energy through transmissive structures;
4. walls stop direct light;
5. OPEN doors transmit strongly;
6. windows transmit partially;
7. CLOSED doors stop/nearly stop direct light;
8. atmosphere increases distance extinction where applicable;
9. source falloff reduces remaining energy;
10. store the contribution in the local emitter field.

Light generally does not bend around corners the way System 26 sound does.

A separate low-energy diffuse pass may turn corners for indoor bounce/spill.

This distinction is important:

> **direct light casts shadows; diffuse light fills them slightly.**

It lets a flashlight create a hard dark region behind a shelf while room/window bounce prevents every shadow from becoming mathematically black.

---

## 12. Flashlight identity

Flashlight lighting must be clearly different from the System 23 vision cone.

### 12.1 Physical source

A flashlight emitter is attached to the actual item/actor source and current N/E/S/W facing.

Candidate profile concept:

- bright hotspot cone;
- softer wider spill cone;
- smooth falloff;
- bright short/mid-range center;
- weaker longer-range edge/spill;
- wall/closed-door cutoff;
- reduced transmission through windows;
- projection through open doorways;
- major props cast shadows.

The rendered beam rotates cosmetically only from truthful facing changes. Physical gameplay orientation remains the current four-way model.

### 12.2 Clear air

The player mostly sees illuminated surfaces; the air beam itself is subtle.

### 12.3 Fog/mist

Atmospheric scatter makes the beam shaft and halo much more visible while physical useful range falls faster.

### 12.4 Not automatic perception

A flashlight cone does not itself reveal current truth.

System 27 says a cell is illuminated.

System 23 still decides whether the observer has geometric LOS and enough visual signal to acquire it.

Another actor's flashlight may therefore illuminate a target for the player.

### 12.5 Source-state boundary

System 27 does not invent the missing flashlight toggle/battery system.

A future portable-light adapter consumes actual:

- equipped/held item truth;
- switched-on/use state;
- battery/charge availability.

Only then does it publish an active physical emitter.

A DEV Lighting Lab may inject a controlled flashlight emitter for testing without pretending those gameplay systems already exist.

---

## 13. Semantic shadow geometry

The renderer should never infer physics by analyzing sprite alpha pixels.

### 13.1 Structures

WHERE/WHAT already provides stronger geometry:

- structure cell;
- horizontal/vertical axis;
- semantic type;
- current Door State.

Presentation shadow occluders derive from that truth.

Proposed mapping:

- wall -> thin oriented occluder;
- CLOSED door -> oriented occluder;
- OPEN door -> no blocking doorway occluder;
- window -> transmissive/no opaque wall occluder;
- unknown/malformed -> conservative occluder.

### 13.2 Major props

Large props may register a semantic `ShadowProfile`:

- footprint-derived polygon or explicit simple polygon;
- facing;
- virtual height class;
- shadow-casting importance.

Good Candidate 001 casters:

- refrigerators;
- vending machines;
- shelving/racks;
- wardrobes/large cabinets;
- large furniture;
- trees/poles where visually useful;
- vehicles later.

Small clutter does not need expensive shadows.

Footprint geometry is the fallback when no explicit profile exists.

---

## 14. Presentation backend

Godot 4's 2D renderer supports point/directional 2D lights, normal/specular maps, hard/soft shadows and LightOccluder2D-backed signed-distance-field access in CanvasItem shaders. System 27 may use these capabilities, but they remain presentation only.

Proposed renderer strategy is hybrid.

### 14.1 Low-frequency authoritative light surface

Render a world-aligned low-resolution lighting texture/field derived from the deterministic backend.

Purpose:

- makes baseline visible brightness track authoritative illumination;
- handles day/night/interior/portal/weather changes consistently;
- gives stable web/mobile behavior even if rich hero effects are culled.

### 14.2 High-frequency hero lights

Use `PointLight2D`/custom cone textures/occluders for nearby visible important sources:

- flashlight;
- streetlights;
- neon;
- lamps;
- work lights;
- fire/headlights later.

These provide smooth gradients and sub-cell shadow silhouettes.

They must originate from real System 27 emitter descriptors and may not create fake illumination sources.

### 14.3 Perception layer stays separate

Lighting affects current live-world rendering below System 23's knowledge mask.

UNSEEN remains true black even if hidden world lighting exists beneath it.

REMEMBERED remains observer memory rather than current hidden-light truth.

---

## 15. Outdoor finite shadows

Native 2D directional shadows are useful, but stylized finite sun shadows may look better for this top-down game.

Preferred long-term presentation options:

1. project finite 2.5D shadow polygons from semantic footprint + virtual height + solar direction/elevation; or
2. use the Godot 2D occluder SDF in a custom finite-shadow shader.

Target effect:

- dawn/dusk: longer shadows;
- midday: shorter shadows;
- no fake 3D physics ownership;
- large objects/buildings cast readable shapes;
- outdoor direct shadow detail can be reduced/disabled under heavy overcast.

Candidate 001 may begin with local-light shadows and a simpler direct-sun shadow pass, then add finite hero outdoor shadows once the backend is proven.

---

## 16. Neon / emissive sources / glow

A luminous object should have separate visual layers.

1. **emissive core** — sign/bulb visibly bright;
2. **physical spill** — real shadow-aware illumination of nearby world;
3. **soft halo** — larger low-energy additive glow/bloom/scatter.

### 16.1 Neon

Neon profiles may define authored colors.

Target look:

- saturated emissive sign;
- colored wall/pavement wash;
- softer large halo;
- light through nearby windows;
- deterministic physical flicker only when source state says it is unstable;
- optional cosmetic sub-tick shimmer that never alters gameplay illumination.

### 16.2 Streetlights

Streetlights create pools, not globally bright roads.

Future semantic profile variants may include:

- warm sodium-vapor;
- neutral/cool LED;
- damaged/failing fixture.

### 16.3 Vending/screens/small emitters

Small colored light pools become disproportionately important after dark and can create strong mood without large simulation cost.

---

## 17. Wet-surface reflection presentation

Full screen-space reflections are unnecessary.

When atmosphere/weather reports meaningful wetness, the renderer may derive cheap reflection smears from:

- a real current light source;
- real wetness;
- compatible receiving ground semantics.

Good receivers:

- asphalt;
- concrete;
- tile;
- later puddle/wet-road semantics.

Target look:

- elongated soft colored reflection under/opposite source;
- strongest for neon/streetlights/headlights;
- aggressively faded/clipped;
- purely presentation unless physical backend already accounts for the same light.

This can make rainy night streets visually distinctive without ray tracing.

---

## 18. System 23: light-dependent visual acquisition

This is a required backend integration, not an optional visual flourish.

Current System 23 geometric FOV remains the **maximum candidate visibility envelope**.

System 27 does not replace the 120-degree cone / walls / doors / memory model.

Proposed acquisition sequence:

1. System 23 geometric LOS identifies candidate currently unobstructed cells;
2. System 27 supplies physical illumination for each candidate cell;
3. observer capability/adaptation + distance convert illumination to visual signal;
4. System 23 decides what current truth was actually acquired;
5. only acquired truth refreshes observer memory.

### 18.1 Light affects useful range, not basic facing geometry

Darkness does not rotate or widen/narrow the physical facing cone arbitrarily.

Instead, low light causes distant/low-contrast cells inside that cone to fail acquisition.

Strong local light can restore useful range in a portion of the cone.

Therefore a flashlight produces a bright useful corridor **inside** the broader geometric vision cone rather than replacing the cone.

### 18.2 Proposed acquisition levels

A future System 23 extension may use at least:

- `NONE` — no current visual acquisition;
- `SILHOUETTE` — coarse large shape/movement only;
- `DETAIL` — current terrain/structure/entity identity eligible to refresh normal memory.

Different content can require different signal:

- large wall/door silhouette: easiest;
- living actor movement/body: medium;
- small loose item/text/detail: hardest.

This gives darkness meaningful uncertainty without needing a biologically detailed eye model.

### 18.3 Dark adaptation seam

Observer-specific adaptation belongs to System 23/perception, not physical lighting.

Recommended later behavior:

- entering darkness adapts gradually over simulation time;
- bright glare reduces dark sensitivity;
- dark-adapted actors can acquire lower-luminance silhouettes/details;
- traits/injury/equipment may modify thresholds later.

System 27 exposes luminance/glare; it does not own observer adaptation.

---

## 19. Future NPC / infected visual AI contract

NPC AI must not query framebuffer pixels or receive System 27's hidden emitter list as omniscient knowledge.

Preferred architecture:

1. the actor has a visual-perception profile;
2. observer perception uses the same geometry + System 27 illumination backend;
3. the actor receives `VisualObservation` records only for physically acquired information;
4. AI decisions consume those observations.

Consequences:

- a zombie may fail to see a player in deep darkness despite geometric LOS;
- the same player crossing a streetlight pool may suddenly become visually detectable;
- another survivor's flashlight can illuminate the player/zombie for third-party observers;
- bright light sources themselves may be visible from farther away than the detail they illuminate;
- a flashlight is tactically useful but may advertise activity.

A later AI-specific design owns how infected react to light observations. System 27 only makes honest information possible.

---

## 20. Luminous source visibility / light signatures

Physical sources can be visually salient even when their surrounding surfaces are dark.

System 27 should expose a neutral **light-signature descriptor** for perception composition, not direct AI access.

Descriptor may include:

- source cell/shape internally;
- apparent emissive strength;
- color;
- directional cone orientation if applicable;
- atmosphere/scatter visibility;
- current active state.

System 23 still applies observer LOS and knowledge rules before creating an observation.

This supports future situations such as:

- seeing a distant neon sign before seeing the building details;
- seeing a flashlight source in darkness;
- noticing a moving bright beam/illuminated patch before identifying its holder.

---

## 21. REMEMBERED-memory leak rule

System 23 memory must not poll hidden current local lighting to reveal hidden state changes.

Required rule:

- global daylight/weather may alter overall remembered presentation because those conditions are globally/environmentally knowable;
- current hidden local emitters do **not** brighten/darken remembered cells merely because they changed while unseen;
- remembered local-light appearance may later store last-observed illumination if desired;
- if a hidden source physically spills light into a currently visible cell, that current spill is observable and may affect that visible cell;
- seeing light spill does not automatically reveal the hidden source entity/location beyond what perception can infer.

This preserves the existing rule that memory is observer knowledge, not hidden-current-world polling.

---

## 22. Source/power-state boundary

System 27 must not fake power.

Proposed `PhysicalLightSourceProvider` contract returns current active emitter descriptors.

Future providers may include:

- electrical fixtures + switch/power-grid state;
- generators;
- portable battery items;
- vehicle lights;
- fire/flare/glow-stick state;
- weather lightning event source;
- DEV lighting fixture provider.

System 27 combines the resulting physical emitters but does not persist duplicate switch/battery/fuel truth.

---

## 23. Performance / streaming strategy

Lighting is physical world truth and may not depend on the current camera rectangle, but detailed computation remains bounded to active simulation demand.

Rules:

- no full-world per-frame CPU light scan;
- no one-Node-per-cell lighting simulation;
- static sky-exposure/optical topology caches invalidate only on local structure changes;
- time/weather scalar changes rescale cached geometry where possible;
- local source fields rebuild on source move/turn/state/profile or local topology change;
- renderer only instantiates rich GPU lights/occluders within camera + safety margin;
- backend may retain illumination fields for nearby active AI outside camera;
- distant/coarse simulation can later use region-level light summaries rather than tactical fields;
- technical stream-region boundaries never become visible light boundaries.

Candidate CI profiling targets should include at least:

- local field rebuild with representative walls/windows/doors;
- one moving/turning flashlight update;
- several simultaneous static local sources;
- repeated O(1)-style cell sampling for many observers.

If profiling requires incremental/region caches, optimize the owner rather than weakening physical rules.

---

## 24. DEV Lighting Lab

Because Weather, electricity, fixture switches and portable-light item-use are not yet fully implemented, System 27 needs an explicit DEV test composition rather than fake production behavior.

Lighting Lab should allow controlled testing of real System 27 physics with:

- time-of-day slider/presets using System 25-compatible time input;
- clear / overcast / rain / fog / storm-optics DEV presets through the neutral atmosphere provider;
- controlled flashlight emitter and facing;
- controlled interior lamp;
- streetlight;
- neon source;
- window + open/closed door portal cases;
- shelving/fridge/large prop shadow cases;
- indoor hallway/deep-room case;
- wet-surface presentation toggle via DEV atmosphere wetness;
- current cell illumination debug readout;
- backend field visualization mode separate from the normal pretty renderer.

The lab is clearly DEV-only and does not imply fake live electricity/weather/item-use systems.

---

## 25. Candidate implementation slices under one System 27 contract

System 27 is one cohesive identity system, but implementation should be staged so each layer can be verified rather than arriving as one opaque visual rewrite.

### Slice A — authoritative headless illumination backend

- `IlluminationSample` / field service;
- outdoor sky/direct composition from System 25;
- structure-envelope sky exposure;
- wall/door/window optical transmission;
- local emitter profiles;
- portal transfer;
- atmosphere/source provider seams;
- flashlight/local source deterministic fields;
- DEV backend visualization/readout;
- headless contract/performance tests.

**Acceptance:** the backend can prove that noon outside > deep interior, a window brightens a room, a closed door blocks a flashlight, fog reduces useful beam distance, and a wall creates a darker tactical shadow without any renderer.

### Slice B — rich lighting presentation

- world darkness/light composite;
- semantic occluder generation;
- local PointLight2D/cone hero lights;
- smooth shadows;
- emissive cores/halos;
- neon/streetlight/lamp look;
- portal spill presentation;
- fog shaft/halo presentation seam;
- wet-surface reflection cheat;
- phone/Web performance controls.

**Acceptance:** renderer visibly matches the backend and creates the desired dramatic lighting without becoming gameplay authority.

### Slice C — System 23 physical vision integration

- illumination-aware current visual acquisition;
- darkness-dependent useful range/detail;
- optional silhouette/detail acquisition levels if implementation proves they are the smallest clean model;
- hidden-local-light memory leak protection;
- neutral observer profile seam for future AI;
- NPC/perception-facing observation contract, but **no Actor AI behavior itself**.

**Acceptance:** a target inside geometric LOS can remain unacquired in darkness, become acquired under a streetlight/flashlight, and the same contract can later be used by infected/NPC observers.

All slices remain one approved System 27 design, not three peer systems.

---

## 26. Verification requirements

Dedicated System 27 verification must prove physical behavior headlessly before presentation assertions.

Backend tests should cover at minimum:

- System 25 day/night changes outdoor light deterministically;
- hard pause changes no lighting simulation time;
- roofed interior is darker than adjacent exterior at noon;
- window portal increases interior daylight;
- OPEN door portal increases transmission;
- CLOSED door reduces/blocks direct flashlight light;
- wall blocks direct flashlight light and produces a shadow region;
- window transmits flashlight at reduced strength;
- short-range diffuse pass creates weak corner spill but never stronger than direct source;
- fog decreases useful distant light while increasing scatter descriptor;
- overcast suppresses direct sunlight more than diffuse sky;
- multiple sources combine deterministically;
- local source ordering does not change final result;
- hidden local emitter changes do not mutate System 23 memory by themselves;
- illumination queries consume zero WHEN ticks;
- snapshot/restore of owning mutable lighting state, if any, is deterministic;
- technical streaming/camera boundaries do not become physical darkness seams;
- representative rebuild/query performance budget.

System 23 integration tests should additionally prove:

- geometric LOS alone is insufficient in deep darkness;
- bright local light can restore acquisition inside LOS;
- light cannot reveal through opaque geometry;
- another actor/source can illuminate a target for an observer;
- UNSEEN remains true black in presentation;
- REMEMBERED never reads hidden current local light truth.

Presentation tests should validate descriptor/occluder construction and canonical startup; visual tuning still requires human playtest.

---

## 27. Deferred extensions

System 27 intentionally leaves clean seams for:

- explicit roof/shelter/construction truth;
- curtains/blinds/boards/broken-glass optical state;
- smoke/fire and particulate lighting;
- electrical grid / utility restoration;
- battery charge and flashlight durability;
- vehicle headlights/taillights;
- generators and emergency lights;
- true seasons/latitude solar profile;
- richer surface reflectance/material response;
- authored normal/specular maps;
- AI attention to moving light/beam patterns;
- coarse distant-region illumination summaries;
- fire/light attraction behavior;
- eye injury/night-vision equipment.

These should extend provider/query contracts rather than move physics into rendering.

---

## 28. North-star fit

Lighting is explicitly one of the systems the North Star says deserves more depth because it creates game identity.

This design follows the mini-Zomboid rule:

- no photon/path-traced global illumination simulation;
- no sprite-pixel physics;
- no full 3D world hidden beneath the 2D game;
- but real causal relationships remain: time/weather -> outdoor light; enclosure/portals -> interiors; active sources -> transmitted light/shadows; illumination -> observer perception; observer knowledge -> AI decisions.

The intended gameplay question is not merely **“is it night?”**

It is:

> **What is actually illuminated here, what can this actor physically make out, and what risk does creating light introduce?**
