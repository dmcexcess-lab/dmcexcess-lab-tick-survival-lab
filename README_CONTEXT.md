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
- **26 Spatial Sound / Hearing** — physical acoustic propagation, listener-specific hearing and yellow-word cues.
- **27 Physical Lighting / Illumination / Shadows** — **Slices A+B+C implemented**: headless physical illumination, rich visible lighting, and target-light-dependent observer acquisition through System 23.

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

## System 23 perception truth

Visual states remain:

- `UNSEEN` — true black, never actually acquired;
- `REMEMBERED` — stale last-acquired observer facts;
- `VISIBLE` — current truth that passed both geometric LOS and the configured visual-acquisition gate.

Candidate geometry remains a 12-cell, 120-degree forward cone plus radius-1 all-around near awareness. Memory schema remains v2.

System 23 now exposes neutral `VisualAcquisitionProvider`. The historical/default provider passes all geometric candidates; the live canonical composition injects System 27's `IlluminationVisualAcquisitionProvider`.

Only acquired cells refresh environment/actor memory. A target may therefore be geometrically clear yet remain UNSEEN/REMEMBERED because it is too dark. Re-lighting the target can make it current VISIBLE truth. Opaque geometry still blocks first.

REMEMBERED luminance follows System 25 broad ambient daylight. System 26 auditory observations may appear as yellow words without revealing terrain.

Exact-head owner: `verify/system23-perception`.

## System 24 loot truth

> **Loot exists before you search for it.**

Searchable furniture is real System 11 container truth. Deterministic `item.*` entities are created once during virgin source initialization; System 24 owns provenance while System 11 owns current contents. Search and TAKE/STORE spend WHEN time and external acquisition respects System 13E carry limits.

Exact-head owner: `verify/system24-loot`.

## System 25 world-time / daylight truth

Candidate 001 uses 5 ticks/second, starts day 0 at 08:00:00, dawn 05:30–07:30, day 07:30–18:30, dusk 18:30–20:30 and night baseline 0.08. Time derives directly from `world_tick`; hard pause freezes it automatically.

System 27 consumes this daylight downstream. Ambient changes now also trigger System 23 acquisition recomputation because changing physical light can change what is currently visible without movement.

Exact-head owner: `verify/system25-world-time-light`.

## System 26 spatial-sound truth

> **Sound is physical. Hearing is an estimate.**

Exact transient sound truth is separated from listener observations. Material-aware propagation reads current WHAT + Door State; survivor hearing derives from existing skills/needs; localization uncertainty cannot flip true front/rear/left/right signs; cue age uses WHEN ticks only.

First fully green executable head: `2d3dcfa6fc8646cda62a5e775beb1ac7c8d04d08`.

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

First fully green Slice C executable head:

`09d1c059760c06ef9791c4d405746caddc107dcf`

All twelve required contexts were green on that exact head.

Exact-head owner: `verify/system27-physical-lighting`.

## Current performance state

Known scale seams:

- inactive materialized facts remain resident in WHAT and new-source 00F commits still own one full persistent-state rollback snapshot;
- System 26 sound must be re-profiled before large simultaneous actor populations;
- System 27 physical-light fixture on the Slice C green runner: ~4.23 ms average for representative 17×17 changing-flashlight rebuild;
- legacy geometry-only System 23 FOV on that run: ~4.06 ms average;
- focused illumination-aware perception recompute: ~11.84 ms average;
- user direction is to keep current lighting/perception cost for now and see whether real later systems/actors make it materially worse before optimizing;
- many moving lights and many simultaneous observers remain explicit future profiling/caching seams.

## Major deferred seams

- Actor AI / infected behavior using the current visual/hearing observation substrate;
- prop/furniture optical-material classification for physical shadowing;
- `NONE / SILHOUETTE / DETAIL`, dark adaptation and observer acuity refinements;
- Weather owner feeding System 27 atmosphere optics;
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
