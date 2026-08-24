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
- **27 Physical Lighting / Illumination / Shadows** — **Slices A+B+C implemented and bounded-query optimized**: headless physical illumination, rich visible lighting, target-light-dependent observer acquisition, cached topology/optics and range-bounded local-emitter work.
- **28 Weather / Atmosphere** — **DRAFT, not implemented**: proposed deterministic weather truth with low-resolution always-animated presentation and physical lighting/sound/perception integration.

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
14. Proposed System 28 direction: physical Weather would advance only through WHEN while low-resolution weather animation may continue cosmetically during player decision pause. This remains DRAFT until approved.

## System 23 perception truth

Visual states remain:

- `UNSEEN` — true black, never actually acquired;
- `REMEMBERED` — stale last-acquired observer facts;
- `VISIBLE` — current truth that passed both geometric LOS and the configured visual-acquisition gate.

Candidate geometry remains a 12-cell, 120-degree forward cone plus radius-1 all-around near awareness. Memory schema remains v2.

System 23 exposes neutral `VisualAcquisitionProvider`. The historical/default provider passes all geometric candidates; the live canonical composition injects System 27's `IlluminationVisualAcquisitionProvider`.

Only acquired cells refresh environment/actor memory. A target may therefore be geometrically clear yet remain UNSEEN/REMEMBERED because it is too dark. Re-lighting the target can make it current VISIBLE truth. Opaque geometry still blocks first.

REMEMBERED luminance follows System 25 broad ambient daylight.

System 26 auditory descriptors may appear above any visual state without revealing terrain. For player presentation, cue lifetime is decided from the **perceived cell's** System 23 state: a VISIBLE cue fades out by about one second; a REMEMBERED/UNSEEN cue latches at the same approximate perceived location until the player's next committed action/unpause. This does not change visual memory or query the exact hidden source.

Exact-head owner: `verify/system23-perception`.

## System 24 loot truth

> **Loot exists before you search for it.**

Searchable furniture is real System 11 container truth. Deterministic `item.*` entities are created once during virgin source initialization; System 24 owns provenance while System 11 owns current contents. Search and TAKE/STORE spend WHEN time and external acquisition respects System 13E carry limits.

Exact-head owner: `verify/system24-loot`.

## System 25 world-time / daylight truth

Candidate 001 uses 5 ticks/second, starts day 0 at 08:00:00, dawn 05:30–07:30, day 07:30–18:30, dusk 18:30–20:30 and night baseline 0.08. Time derives directly from `world_tick`; hard pause freezes it automatically.

System 27 consumes this daylight downstream. Ambient changes also trigger System 23 acquisition recomputation because changing physical light can change what is currently visible without movement.

Exact-head owner: `verify/system25-world-time-light`.

## System 26 spatial-sound truth

> **Sound is physical. Hearing is an estimate.**

Exact transient sound truth is separated from listener observations. Material-aware propagation reads current WHAT + Door State; survivor hearing derives from existing skills/needs; localization uncertainty cannot flip true front/rear/left/right signs; simulation observation age uses WHEN ticks only.

Recognized player-facing sounds now prefer onomatopoeia:

- Walk: `NOISE -> *scuff* -> *step step*`;
- Run: `NOISE -> *thump thump* -> *step step step*`;
- normal door: `NOISE -> *thunk* -> *creak*`;
- loud door: `NOISE -> *BANG* -> *SLAM*`.

Low-confidence recognition remains broad rather than inventing the wrong sound.

Player cue lifetime is presentation-only and separate from the underlying `HeardSoundObservation`:

- perceived-cell VISIBLE cue: transient, fades to zero by ~1 real second;
- perceived-cell REMEMBERED/UNSEEN cue: latches at the stored approximate position until that listener next begins an action/unpauses;
- repeated opaque cue groups replace/update rather than leave trails;
- cleared/faded cue IDs are suppressed until their upstream observation disappears so they do not immediately pop back in;
- future AI still consumes ordinary heard observations and never receives this player UI latch as memory.

Latest fully green executable refinement head: `aa5e1b622c8efe555d22e5d56514b9490776be16`.

Exact-head owner: `verify/system26-spatial-sound`.

## System 27 physical-lighting truth

> **Light is physical. Vision is observer-specific. Rendering visualizes lighting; gameplay and AI never read rendered pixels to decide what is illuminated.**

### Slice A — physical truth

Implemented physical facts include:

- clear/overcast/rain/fog/storm-compatible atmosphere inputs;
- semantic flashlight/lamp/streetlight/neon emitter profiles;
- per-cell sky/direct/portal/local luminance, tint, direction, glare and scatter;
- structure-envelope interior/sky exposure;
- window and OPEN-door daylight portals;
- wall/door/window local-light transmission and tactical shadows;
- no diffuse relay through opaque walls/closed doors;
- target-cell-light useful-range policy.

Candidate useful range:

- luminance `0.0` -> 2 cells;
- luminance `1.0` -> 12-cell geometric maximum;
- `sqrt(luminance)` response;
- radius-1 near awareness protected.

The **target cell's illumination** drives range. Standing under a lamp does not grant long-range sight into an unlit target.

### Slice B — presentation

Implemented:

- two bounded physical-light maps;
- multiplicative darkness/tint shader;
- additive glow/portal/scatter/wet-reflection shader;
- edge-aware smoothing preserving physical shadow discontinuities;
- current world/actors -> physical lighting -> System 23 knowledge-mask ordering;
- DEV-only player flashlight + fixed diner lamp/neon/streetlight until real equipment/power/Weather source owners exist.

Physical shadows currently use structure/door/window optical truth. Arbitrary furniture/prop optical classification remains deferred.

### Slice C — observer acquisition

Implemented:

- neutral System 23 `VisualAcquisitionProvider` seam;
- System 27 `IlluminationVisualAcquisitionProvider` adapter;
- geometric candidates are filtered by target illumination before becoming `VISIBLE`;
- only acquired cells refresh memory;
- third-party light can expose a target;
- bright light cannot reveal through opaque geometry;
- previously observed cells return to `REMEMBERED` when light falls;
- stale last-seen actors are not magically tracked through darkness;
- the lighting adapter guarantees an observer-centered 25×25 query envelope when the camera's current presentation field does not cover the whole 12-cell vision envelope, so camera panning cannot change gameplay vision;
- when the presentation field already covers the observer envelope, C reuses it instead of forcing a second normal lighting rebuild.

No Actor AI behavior is implemented yet, but the observer seam is ready for future survivor/infected/animal perception.

### 2026-08-24 optimization

The physical rules and visual output were intentionally preserved while avoidable work was removed:

- field/materialized-cell lists and structure classification are cached by world/bounds revision;
- door/window/opaque transmission is cached and only door-dependent optics rebuild on Door State revision;
- portal transfer iterates cached portal candidates instead of rescanning every field cell;
- emitter signatures are computed when emitter sets change, not on every sample query;
- each local emitter evaluates only its useful-range intersection rectangle before radius/cone/ray tests;
- `prepare_query()` / `illumination_at_prepared()` let immediate presentation batches validate lighting state once instead of once per rendered cell;
- the presentation renderer reuses its two `Image` buffers while size is unchanged.

A dedicated 80×96 CI fixture with flashlight/lamp/streetlight/neon proves **7,680** materialized field cells but only **1,676** local-emitter candidates and **688** optical-ray candidates. The previous naive full-field-per-emitter approach would have visited **30,720** field cells before range checks.

Latest fully green optimized executable head:

`5958d887807e5b64c9fc4cf5d3d45c7dfd4083d2`

All twelve required contexts were green on that exact head, including Pages.

Exact-head owner: `verify/system27-physical-lighting`.

## System 28 Weather / Atmosphere draft

> **Weather is simulation truth; weather animation is presentation.**

`SYSTEM_DESIGNS/28_WEATHER_ATMOSPHERE.md` is DRAFT and awaiting approval. Proposed Candidate 001 includes:

- clear, overcast, rain, storm and fog;
- compact deterministic cloud/precipitation/fog/wind/wetness state scheduled through WHEN;
- intentionally low-resolution nearest-scaled rain/fog presentation;
- rain/fog animation that may keep moving while the survivor is paused deciding, without advancing physical weather or world time;
- roof/sky-exposure-aware precipitation so rain does not simply draw through enclosed buildings;
- System 27 `AtmosphericOptics` integration for actual daylight, local-light extinction, scatter, wet reflections and visibility consequence;
- System 26 environment masking for heavy rain/wind rather than fake repeated rain sounds;
- deterministic lightning events whose physical flash is rendered by System 27 and can therefore temporarily change real System 23 acquisition;
- a stable-seeded low-res pixel bolt tied to the same physical lightning event;
- lightning damage/fire deferred until their real owners exist.

No System 28 runtime code exists yet.

## Current performance state

Known scale seams:

- inactive materialized facts remain resident in WHAT and new-source 00F commits still own one full persistent-state rollback snapshot;
- System 26 sound must be re-profiled before large simultaneous actor populations;
- old pre-optimization System 27 Slice C reference: ~4.23 ms representative 17×17 changing-flashlight rebuild and ~11.84 ms focused light-aware perception;
- optimized exact head `5958d887...` measured ~2.67 ms / ~9.26 ms on its runner; the immediately preceding optimized runner measured ~1.73 ms / ~6.49 ms, demonstrating normal CI timing noise but a consistent material reduction;
- the durable performance regression is structural: four local lights in an 80×96 field are bounded to 1,676 candidate cells / 688 ray cells instead of 30,720 naive full-field visits;
- many simultaneous moving lights and many simultaneous observers remain explicit future profiling/caching seams;
- sound cue fading adds only a short-lived presentation timer while a visible word is fading; latched unseen markers have no continuous simulation scan.

## Major deferred seams

- Actor AI / infected behavior using the current visual/hearing observation substrate;
- prop/furniture optical-material classification for physical shadowing;
- `NONE / SILHOUETTE / DETAIL`, dark adaptation and observer acuity refinements;
- System 28 Weather implementation if/when its current draft is approved;
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
- `verify/pages-deploy`
