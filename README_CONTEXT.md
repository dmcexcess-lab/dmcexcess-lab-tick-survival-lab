# Tick Survival Lab — Current Context

> Read `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, `SYSTEM_DESIGNS/README.md`, current `main`, and the relevant system design before repository changes.

## Game

> **Ultima-style turn-based mini Zomboid.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden archaeology commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## Current canonical stack

- **00A WHERE** — global integer-cell spatial truth.
- **00B WHAT** — authoritative persistent current world.
- **00C WHEN** — deterministic variable-duration tick/action/pause kernel.
- **00D** — `temperate.rural.region` v6 global planning.
- **01–18** — collision, movement, locomotion, art/rendering, doors, hands, inventory, timed item transfer, actor stats/status, carry, HUD/player shell, run/exertion and door passage.
- **19 Building Generation** — finalized 24-archetype one-story library.
- **20 Local Area Generation** — ten area profiles / seven environment palettes.
- **00F Streaming / Materialization** — settlement + dry-countryside logical sources; one-way materialization, reversible activation.
- **21 Camera** / **22 Large-Area DEV Critique Runtime** — implemented.
- **23 Perception / LOS / Fog Memory** — geometric facing LOS, physical-light/atmosphere-aware current acquisition, true-black unexplored fog, stale remembered environment/static furniture, last-seen actors and auditory presentation.
- **24 World Loot / Searchable Containers / Scavenging** — persistent virgin loot, timed search, timed TAKE/STORE and playable scavenging UI.
- **25 World Time / Ambient Daylight** — authoritative-tick-derived scenario clock and smooth outdoor daylight baseline.
- **26 Spatial Sound / Hearing** — physical acoustic propagation, listener-specific hearing/localization, yellow onomatopoeia cues, player cue lifetime, and neutral Weather background masking seam.
- **27 Physical Lighting / Illumination / Shadows** — headless physical illumination, rich visible lighting, target-condition observer acquisition, bounded-query optimization, and live Weather `AtmosphericOptics` input.
- **28 Weather / Atmosphere** — **Slices A+B implemented; C deferred**: deterministic WHEN-driven weather, analytic wetness, low-resolution 20 Hz atmosphere, shelter masking, real optics/visibility/hearing consequences, camera compensation and black technical fallback.

## Core rules

1. System 00D owns global coherence; local/stream partitions do not invent world-spanning truth.
2. System 20 turns global facts into local physical areas; System 19 owns building interiors.
3. Generation owns virgin creation only. WHAT and typed mechanic stores own current reality afterward.
4. Technical streaming activation is not world existence.
5. Materialization is one-way; activation is reversible.
6. Art/rendering is presentation, not physics.
7. Phone/Safari remains first-class.
8. Perception knowledge is observer-specific and never substitutes hidden current truth for stale memory.
9. WHEN owns integer simulation ticks only; System 25 interprets them as scenario-local clock time.
10. **Sound is physical; hearing is an estimate.**
11. **Light is physical; vision is observer-specific.** Gameplay/AI lighting never reads rendered pixels.
12. Geometric LOS is a maximum candidate envelope; current visual acquisition may be smaller because of physical illumination **or physical atmospheric extinction**.
13. Player sound presentation may temporarily preserve an uncertain heard location, but it never gains exact hidden source truth or visual exploration.
14. **Weather is simulation truth; weather animation is presentation.** Physical Weather advances only through WHEN; low-res cosmetic weather may continue during decision pause.
15. Weather feeds Lighting/Hearing through neutral environment seams; it does not become a second light, perception or sound engine.

## System 23 perception truth

Visual states remain:

- `UNSEEN` — true black, never actually acquired;
- `REMEMBERED` — stale last-acquired observer facts;
- `VISIBLE` — current truth that passed geometric LOS and the configured physical acquisition gate.

Candidate geometry remains a 12-cell, 120-degree forward cone plus radius-1 all-around near awareness. Memory schema remains v2.

System 23 exposes neutral `VisualAcquisitionProvider`; the live composition injects System 27's `IlluminationVisualAcquisitionProvider`.

Only acquired cells refresh environment/actor memory. A target may be geometrically clear yet remain UNSEEN/REMEMBERED because it is too dark **or too strongly extinguished by current atmosphere**. Opaque geometry still blocks first. Radius-1 near awareness remains protected.

Representative Weather-B full-light acquisition fixture: clear range 12 cells; physical fog extinction around 0.60 reduces the same bright-condition useful range to 5 cells.

REMEMBERED luminance continues to follow System 25 broad ambient daylight. System 28 remains below the final perception mask, so shelter/weather graphics do not reveal hidden geometry.

Exact-head owner: `verify/system23-perception`.

## System 24 loot truth

> **Loot exists before you search for it.**

Searchable furniture is real System 11 container truth. Deterministic `item.*` entities are created once during virgin source initialization; System 24 owns provenance while System 11 owns current contents. Search and TAKE/STORE spend WHEN time and external acquisition respects System 13E carry limits.

Exact-head owner: `verify/system24-loot`.

## System 25 world-time / daylight truth

Candidate 001 uses 5 ticks/second, starts day 0 at 08:00:00, dawn 05:30–07:30, day 07:30–18:30, dusk 18:30–20:30 and night baseline 0.08. Time derives directly from `world_tick`; hard pause freezes it automatically.

System 27 consumes daylight downstream. System 28 uses the same WHEN clock and now modulates that daylight through continuous atmospheric optics without owning a second clock.

Exact-head owner: `verify/system25-world-time-light`.

## System 26 spatial-sound truth

> **Sound is physical. Hearing is an estimate.**

Exact transient sound truth is separated from listener observations. Material-aware propagation reads current WHAT + Door State; survivor hearing derives from existing skills/needs; localization uncertainty cannot flip true front/rear/left/right signs; observation age uses WHEN ticks only.

Recognized player-facing sounds prefer onomatopoeia:

- Walk: `NOISE -> *scuff* -> *step step*`;
- Run: `NOISE -> *thump thump* -> *step step step*`;
- normal door: `NOISE -> *thunk* -> *creak*`;
- loud door: `NOISE -> *BANG* -> *SLAM*`.

Player cue lifetime remains presentation-only: perceived-cell VISIBLE fades by about one real second; REMEMBERED/UNSEEN latches at the approximate location until next action/unpause.

System 28 Slice B now injects one `WeatherAcousticEnvironmentModifier` into the existing neutral seam. Current policy treats rain/wind as competing background noise:

- propagation cost addition stays 0;
- detection threshold rises with precipitation/wind;
- localization quality declines modestly;
- no rain particle creates a `SoundEmission`.

Representative storm fixture: +19 detection-threshold addition relative to the underlying hearing decision.

Exact-head owner: `verify/system26-spatial-sound`.

## System 27 physical-lighting truth

> **Light is physical. Vision is observer-specific. Rendering visualizes lighting; gameplay and AI never read rendered pixels to decide what is illuminated.**

### Physical truth

Implemented facts include semantic flashlight/lamp/streetlight/neon emitters; per-cell sky/direct/portal/local luminance, tint, direction, glare and scatter; structure-envelope sky/interior treatment; window/open-door portals; structure light transmission/shadows; and target-condition useful-range policy.

System 28 Slice B now feeds continuous Weather through `WeatherAtmosphericOpticsAdapter` into the existing `AtmosphericOptics` contract:

- clear remains essentially neutral;
- cloud/overcast suppresses direct sky harder than diffuse sky;
- rain adds moderate transmission loss/scatter/extinction;
- storm strongly suppresses direct sky;
- fog produces strong scatter/extinction;
- real analytic Weather wetness drives the existing restrained wet-surface reflection factor;
- Weather environment revision becomes the optics revision.

System 27 still owns all physical illumination/shadow/portal solving.

### Observer acquisition

The provider combines target luminance with atmosphere `visibility_extinction` after opaque System 23 geometry has already admitted the candidate. Atmosphere can reduce useful distance but never extend beyond the 12-cell geometric envelope or reveal through walls.

### Optimization

Current optimized owner caches materialized/topology/optical facts, bounds local emitters to useful-range rectangles, prepares presentation queries once per map refresh and reuses lighting image buffers.

The 80×96 / four-light regression remains:

- 7,680 field cells;
- 1,676 emitter candidates;
- 688 optical-ray candidates;
- versus 30,720 naive full-field-per-emitter visits.

On the first Weather-B owner runner representative light rebuild was ~2.55 ms and focused illumination-aware perception ~9.55 ms; timing remains secondary to structural bounded-work proofs.

Exact-head owner: `verify/system27-physical-lighting`.

## System 28 Weather / Atmosphere truth

> **Weather is simulation truth; weather animation is presentation.**

Slices A+B are implemented.

### Physical Weather

`WeatherService` owns scenario-wide Candidate 001 clear/overcast/rain/storm/fog state, continuous precipitation/cloud/fog/wind values, analytic wetness, quantized environment revision, deterministic next-profile/duration selection and snapshot/restore.

There is **no per-tick Weather loop**. One meaningful transition is scheduled through WHEN; continuous state and wetness are analytically derived from authoritative tick position.

Current environment signature uses 12 quantization bands. Expensive physical refreshes happen on meaningful `weather_changed` revisions, not the 20 Hz cosmetic frames.

### Presentation

`WeatherPresentationRenderer` remains one Node2D with no per-particle child Nodes.

Caps:

- 20 Hz / 50 ms active phase;
- max four cosmetic catch-up steps;
- virtual axis <=256;
- max 180 rain candidates;
- max 36 fog patches;
- max 3 cosmetic debris records;
- calm clear max 1 debris.

Rain/fog/debris may animate while decision-paused; this advances zero WHEN ticks and changes no physical Weather/wetness.

### Camera-lag correction

Weather now receives camera presentation changes separately from its 20 Hz phase. Actual camera movement requests an immediate compensated redraw using a coarse camera offset, but advances neither Weather phase nor WHEN. Render-window shifts combine visible-origin and camera-local position so technical recentering does not produce an atmospheric jump. Rain still maps each coarse sample back to the correct world cell before shelter masking.

### Black technical fallback

Godot's viewport default clear color is explicitly true black. Outside/in-between the large render window therefore no longer appears as grey chunk rectangles against System 23 UNSEEN black. This is a presentation fallback only; no fake terrain or perception state is created.

### Physical environment integration

Weather now drives:

- System 27 `AtmosphericOptics` from continuous fields;
- real wetness into wet-surface lighting presentation;
- physical visibility extinction in current observer acquisition;
- System 26 rain/wind detection/localization masking.

Cosmetic weather itself still causes zero physical Lighting/Perception recomputes.

### DEV controls

Rural Crossroads intentionally starts in RAIN. DEV panel exposes CLR, OVR, RAIN, STM, FOG and BLOW LEAF. Forcing a profile now changes both visible weather and its physical optics/hearing environment.

### Verification

First fully green executable Weather B head:

`db4681dc53ce6955e9585f4f5b380fe8efef634c`

Focused B fixture:

- `WEATHER_B_CLEAR_RANGE=12`;
- `WEATHER_B_FOG_RANGE=5`;
- `WEATHER_B_STORM_HEARING_MASK=19`;
- `WEATHER_B_CAMERA_REDRAWS=1` with zero phase/WHEN advancement.

All 13 exact-head contexts were green on the executable head.

Exact-head owner: `verify/system28-weather`.

### Deferred Slice C

- deterministic LightningEvent;
- transient physical System 27 flash;
- low-res seeded bolt;
- System 23 acquisition consequences;
- optional ordinary System 26 thunder;
- no damage/fire until real owners exist.

## Current performance state

Known scale seams:

- inactive materialized facts remain resident in WHAT and new-source 00F commits still own one full persistent-state rollback snapshot;
- System 26 sound must be re-profiled before large simultaneous actor populations;
- System 27 retains its 1,676/688 bounded-work regression for the 80×96 four-light case;
- System 28 visuals remain bounded at 20 Hz with tiny caps, while camera correction is event-driven on actual camera changes;
- Weather physical consumers refresh on quantized environment revisions rather than cosmetic frames;
- many simultaneous moving lights and observers remain explicit future profiling/caching seams before Actor AI scales up.

## Major deferred seams

- Actor AI / infected behavior using current visual/hearing substrate;
- System 28 Slice C lightning/thunder;
- prop/furniture optical-material classification;
- `NONE / SILHOUETTE / DETAIL`, dark adaptation and observer acuity refinements;
- electricity/generators/batteries/switches feeding real active light sources;
- population / households / causal outbreak / player story (00E);
- usable food/drink and medical treatment actions;
- condition/durability/spoilage;
- combat and firearm/ammunition mechanics;
- crafting/recycling;
- locks/keys/forced entry;
- corpse loot/decay;
- vehicles/cargo;
- NPC scavenging/ownership/theft;
- outbreak-driven virgin loot depletion;
- generic quantity/stack mechanics;
- persistence-backed streaming eviction;
- calendar date/season/latitude beyond System 25;
- conventional audio playback, if ever desired.

## Required exact-head contexts

- `verify/system00d-global-world`
- `verify/system00f-streaming-materialization`
- `verify/system19-local-building`
- `verify/system20-local-area`
- `verify/system21-camera-view`
- `verify/system22-area-critique`
- `verify/system23-perception`
- `verify/system24-loot`
- `verify/system25-world-time-light`
- `verify/system26-spatial-sound`
- `verify/system27-physical-lighting`
- `verify/system28-weather`
- `verify/pages-deploy`
