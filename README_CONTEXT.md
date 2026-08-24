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
- **23 Perception / LOS / Fog Memory** — geometric facing LOS, illumination-aware current acquisition, true-black unexplored fog, stale remembered environment/static furniture, last-seen actors and auditory presentation.
- **24 World Loot / Searchable Containers / Scavenging** — persistent virgin loot, timed search, timed TAKE/STORE and playable scavenging UI.
- **25 World Time / Ambient Daylight** — authoritative-tick-derived scenario clock and smooth outdoor daylight baseline.
- **26 Spatial Sound / Hearing** — physical acoustic propagation, listener-specific hearing/localization, onomatopoeia yellow-word cues and seen-vs-unseen player cue lifetime.
- **27 Physical Lighting / Illumination / Shadows** — Slices A+B+C implemented and bounded-query optimized: headless physical illumination, rich visible lighting, target-light-dependent observer acquisition, cached topology/optics and range-bounded local-emitter work.
- **28 Weather / Atmosphere** — **Slice A implemented; B/C deferred**: deterministic WHEN-driven weather truth, analytic wetness, low-resolution 20 Hz rain/fog, shelter masking, and tiny calm-day ambient debris.

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
12. Geometric LOS is a maximum candidate envelope; current visual acquisition may be smaller because of physical illumination.
13. Player sound presentation may temporarily preserve an uncertain heard location, but it never gains exact hidden source truth or visual exploration.
14. **Weather is simulation truth; weather animation is presentation.** Physical Weather advances only through WHEN; low-res cosmetic weather may continue during decision pause.

## System 23 perception truth

Visual states remain:

- `UNSEEN` — true black, never actually acquired;
- `REMEMBERED` — stale last-acquired observer facts;
- `VISIBLE` — current truth that passed both geometric LOS and the configured visual-acquisition gate.

Candidate geometry remains a 12-cell, 120-degree forward cone plus radius-1 all-around near awareness. Memory schema remains v2.

System 23 exposes neutral `VisualAcquisitionProvider`. The live canonical composition injects System 27's `IlluminationVisualAcquisitionProvider`.

Only acquired cells refresh environment/actor memory. A target may be geometrically clear yet remain UNSEEN/REMEMBERED because it is too dark. Re-lighting the target can make it current VISIBLE truth. Opaque geometry still blocks first.

REMEMBERED luminance follows System 25 broad ambient daylight.

System 26 auditory descriptors may appear above any visual state without revealing terrain. For player presentation, a perceived-cell VISIBLE cue fades by about one second; a REMEMBERED/UNSEEN cue latches at the same approximate perceived location until the player's next committed action/unpause.

System 28 Weather A is rendered **below** System 23, so shelter-masked precipitation cannot reveal hidden roof/building geometry through black fog.

Exact-head owner: `verify/system23-perception`.

## System 24 loot truth

> **Loot exists before you search for it.**

Searchable furniture is real System 11 container truth. Deterministic `item.*` entities are created once during virgin source initialization; System 24 owns provenance while System 11 owns current contents. Search and TAKE/STORE spend WHEN time and external acquisition respects System 13E carry limits.

Exact-head owner: `verify/system24-loot`.

## System 25 world-time / daylight truth

Candidate 001 uses 5 ticks/second, starts day 0 at 08:00:00, dawn 05:30–07:30, day 07:30–18:30, dusk 18:30–20:30 and night baseline 0.08. Time derives directly from `world_tick`; hard pause freezes it automatically.

System 27 consumes this daylight downstream. Ambient changes trigger System 23 acquisition recomputation because changing physical light can change what is currently visible without movement.

System 28 physical weather uses the same WHEN clock but owns no second independently advancing simulation time.

Exact-head owner: `verify/system25-world-time-light`.

## System 26 spatial-sound truth

> **Sound is physical. Hearing is an estimate.**

Exact transient sound truth is separated from listener observations. Material-aware propagation reads current WHAT + Door State; survivor hearing derives from existing skills/needs; localization uncertainty cannot flip true front/rear/left/right signs; simulation observation age uses WHEN ticks only.

Recognized player-facing sounds prefer onomatopoeia:

- Walk: `NOISE -> *scuff* -> *step step*`;
- Run: `NOISE -> *thump thump* -> *step step step*`;
- normal door: `NOISE -> *thunk* -> *creak*`;
- loud door: `NOISE -> *BANG* -> *SLAM*`.

Low-confidence recognition remains broad rather than inventing the wrong sound.

Player cue lifetime is presentation-only and separate from `HeardSoundObservation`:

- perceived-cell VISIBLE cue: fades to zero by ~1 real second;
- perceived-cell REMEMBERED/UNSEEN cue: latches at the stored approximate position until that listener next begins an action/unpauses;
- repeated opaque cue groups replace/update rather than leave trails;
- future AI consumes ordinary heard observations and never receives the player's presentation latch as memory.

Weather A does not yet change hearing. Rain/wind background masking belongs to System 28 Slice B.

Exact-head owner: `verify/system26-spatial-sound`.

## System 27 physical-lighting truth

> **Light is physical. Vision is observer-specific. Rendering visualizes lighting; gameplay and AI never read rendered pixels to decide what is illuminated.**

### Physical truth

Implemented facts include:

- clear/overcast/rain/fog/storm-compatible atmosphere inputs;
- semantic flashlight/lamp/streetlight/neon emitter profiles;
- per-cell sky/direct/portal/local luminance, tint, direction, glare and scatter;
- structure-envelope interior/sky exposure;
- window and OPEN-door daylight portals;
- wall/door/window local-light transmission and tactical shadows;
- no diffuse relay through opaque walls/closed doors;
- target-cell-light useful-range policy.

Candidate useful range remains 2 cells at zero light toward the 12-cell geometric maximum at full light with `sqrt(luminance)` response and radius-1 near awareness protected.

### Presentation

Implemented:

- two bounded physical-light maps;
- multiplicative darkness/tint shader;
- additive glow/portal/scatter/wet-reflection shader;
- edge-aware smoothing preserving physical shadow discontinuities;
- current world/actors -> physical lighting -> Weather -> System 23 knowledge-mask ordering;
- DEV-only player flashlight + fixed diner lamp/neon/streetlight until real equipment/power owners exist.

### Observer acquisition

Implemented:

- neutral System 23 visual-acquisition seam;
- target illumination filters geometric candidates before `VISIBLE`;
- only acquired cells refresh memory;
- third-party light can expose a target;
- bright light cannot reveal through opaque geometry;
- camera panning cannot become gameplay vision truth.

### Optimization

Current optimized owner caches materialized/topology/optical facts, bounds local emitters to useful-range rectangles, prepares presentation queries once per map refresh and reuses lighting image buffers.

An 80×96 / four-light CI fixture proves:

- 7,680 field cells;
- 1,676 emitter candidates;
- 688 optical-ray candidates;
- versus 30,720 naive full-field-per-emitter visits.

System 28 A does not yet feed physical atmosphere values to Lighting. That is Slice B.

Exact-head owner: `verify/system27-physical-lighting`.

## System 28 Weather / Atmosphere truth

> **Weather is simulation truth; weather animation is presentation.**

Slice A is implemented.

### Physical Weather

`WeatherService` owns scenario-wide Candidate 001 state:

- clear;
- overcast;
- rain;
- storm;
- fog;
- continuous precipitation/cloud/fog/wind values;
- analytic wetness;
- environment revision;
- deterministic next-profile/duration selection;
- snapshot/restore.

There is **no per-tick Weather loop**. One meaningful transition is scheduled through WHEN, while current continuous values and wetness are analytically derived from authoritative tick position.

Current environment signature uses 12 quantization bands so future Lighting/Hearing consumers can refresh on meaningful physical changes rather than cosmetic frames.

### Shelter

`SkyExposureQuery` caches current bounds + WHAT revision and treats structure cells as the enclosure boundary. Opening a door does not make the room unroofed. Rain presentation is suppressed in enclosed cells.

### Presentation

`WeatherPresentationRenderer` is one Node2D and creates no per-particle child Nodes.

Current caps:

- 20 Hz / 50 ms active presentation step;
- max four catch-up presentation steps after a long frame;
- virtual axis max 256;
- max 180 rain candidates;
- max 36 fog patches;
- max 3 cosmetic leaf/paper/dust records;
- calm clear max 1 active debris piece.

Rain/fog/debris may animate while the survivor is decision-paused. This advances zero WHEN ticks and changes no physical wetness/weather.

Clear weather stops requesting redraws when no ambient event is active; only the cheap countdown/branch remains until a rare leaf/paper/dust event starts.

### DEV critique controls

The Rural Crossroads build intentionally starts in RAIN for immediate Weather A playtest. The DEV panel exposes:

- CLR;
- OVR;
- RAIN;
- STM;
- FOG;
- BLOW LEAF.

These are explicit test controls, not production climate logic.

### Deferred

Slice B:

- System 27 `AtmosphericOptics` mapping;
- physical fog/rain visibility extinction;
- real wet-surface lighting response;
- System 26 rain/wind masking.

Slice C:

- deterministic LightningEvent;
- physical System 27 lightning flash;
- low-res seeded bolt;
- System 23 acquisition consequences;
- optional System 26 thunder;
- no damage/fire until real owners exist.

First fully green executable Weather A head:

`dcb400b8507c23a2fc5bdaecf551bc5c0512acce`

Focused owner fixture reported:

- `WEATHER_VIRTUAL_PIXELS=1296`;
- `WEATHER_ACTIVE_DEBRIS=1`;
- `WEATHER_PRESENTATION_UPDATES=4` for a deliberately long 0.5 s test frame.

Exact-head owner: `verify/system28-weather`.

## Current performance state

Known scale seams:

- inactive materialized facts remain resident in WHAT and new-source 00F commits still own one full persistent-state rollback snapshot;
- System 26 sound must be re-profiled before large simultaneous actor populations;
- optimized System 27 continues to use the 1,676/688 bounded-work regression for the 80×96 four-light case;
- on the Weather A owner runner, representative lighting rebuild measured ~2.53 ms; timings remain secondary to structural work-count proofs;
- System 28 continuous visuals are bounded at 20 Hz with tiny hard caps, and clear-weather redraw sleeps between ambient events;
- many simultaneous moving lights and many simultaneous observers remain explicit future profiling/caching seams before Actor AI scales up.

## Major deferred seams

- Actor AI / infected behavior using current visual/hearing observation substrate;
- System 28 Slice B physical optics/visibility/hearing integration;
- System 28 Slice C lightning/thunder;
- prop/furniture optical-material classification for physical shadowing;
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
