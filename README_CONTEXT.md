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
- **23 Perception / LOS / Fog Memory** — facing LOS, true-black unexplored fog, stale remembered environment/static furniture, last-seen actors and auditory presentation.
- **24 World Loot / Searchable Containers / Scavenging** — persistent virgin loot, timed search, timed TAKE/STORE and playable scavenging UI.
- **25 World Time / Ambient Daylight** — authoritative-tick-derived scenario clock and smooth outdoor daylight baseline.
- **26 Spatial Sound / Hearing** — physical acoustic propagation, listener-specific hearing and yellow-word cues.
- **27 Physical Lighting / Illumination / Shadows** — **Slices A+B implemented**: headless physical illumination + target-light useful-range policy, plus live visible darkness/tint/glow/scatter presentation. Slice C observer acquisition remains pending.

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

## System 23 perception truth

Visual states remain `UNSEEN` true black, `REMEMBERED` stale last-observed truth, and `VISIBLE` current live truth. Current geometric LOS remains a 12-cell, 120-degree cone plus radius-1 near awareness; memory schema is v2.

REMEMBERED luminance follows System 25 broad ambient daylight. System 26 auditory observations may appear as yellow words without revealing terrain.

System 27 Slice B is rendered below System 23, so hidden current lights/glow are covered by the observer-knowledge mask. **The live System 23 visible-cell set is still not illumination-gated.** Slice C will apply the existing target-light useful-range policy without moving memory ownership out of Perception.

Exact-head owner: `verify/system23-perception`.

## System 24 loot truth

> **Loot exists before you search for it.**

Searchable furniture is real System 11 container truth. Deterministic `item.*` entities are created once during virgin source initialization; System 24 owns provenance while System 11 owns current contents. Search and TAKE/STORE spend WHEN time and external acquisition respects System 13E carry limits.

Exact-head owner: `verify/system24-loot`.

## System 25 world-time / daylight truth

Candidate 001 uses 5 ticks/second, starts day 0 at 08:00:00, dawn 05:30–07:30, day 07:30–18:30, dusk 18:30–20:30 and night baseline 0.08. Time is derived directly from `world_tick`; hard pause freezes it automatically.

System 27 consumes this daylight downstream. System 25 remains the clock/daylight owner.

Exact-head owner: `verify/system25-world-time-light`.

## System 26 spatial-sound truth

> **Sound is physical. Hearing is an estimate.**

Exact transient sound truth is separated from listener observations. Material-aware propagation reads current WHAT + Door State; survivor hearing derives from existing skills/needs; localization uncertainty cannot flip true front/rear/left/right signs; cue age uses WHEN ticks only.

First fully green executable head: `2d3dcfa6fc8646cda62a5e775beb1ac7c8d04d08`.

Exact-head owner: `verify/system26-spatial-sound`.

## System 27 physical-lighting truth

> **Light is physical. Vision is observer-specific. Rendering visualizes lighting; gameplay and AI never read rendered pixels to decide what is illuminated.**

### Slice A — physical truth

Implemented:

- neutral clear/overcast/rain/fog/storm-compatible `AtmosphericOptics` input;
- flashlight/lamp/streetlight/neon semantic profiles;
- exact active `LightEmitter` descriptors supplied by source owners;
- per-cell sky/direct/portal/local useful luminance, tint, direction, glare and scatter;
- structure-envelope enclosure/sky exposure;
- window/OPEN-door daylight portals;
- wall/door/window local-light transmission and physical tactical shadows;
- no diffuse relay through opaque walls/closed doors;
- fog extinction + scatter behavior;
- deterministic source composition;
- target-cell-light useful-range policy.

Candidate useful range maps luminance 0.0 -> 2 cells and 1.0 -> the 12-cell geometric maximum with a `sqrt(luminance)` response and protected near awareness. The **target cell's illumination** drives range, so standing under a lamp does not grant vision into distant darkness.

### Slice B — visible presentation

Implemented:

- `PhysicalLightingPresentationRenderer` builds two bounded tactical light maps from Slice A samples;
- multiplicative darkness/tint canvas shader;
- additive local/portal/glare/scatter glow shader;
- edge-aware smoothing preserves hard physical shadow discontinuities;
- emissive cores reflect semantic source tint;
- atmosphere scatter and wetness feed visible treatment;
- renderer order is current world/actors -> physical lighting -> System 23 Perception mask;
- no presentation loop advances WHEN.

The current Rural Crossroads critique build uses an explicitly DEV-only `DemoLightingSourceAdapter`: player-following flashlight plus fixed diner lamp, blue neon and streetlight. This exists only to exercise Slice B before real equipment/battery/switch/electrical/Weather source owners exist.

Physical shadows currently use structure/door/window optical geometry. Arbitrary furniture/prop optical occlusion is a future System 27 refinement rather than a fake shadow feature.

### Slice C — pending

System 23 has not yet applied target-light useful range to current acquisition. Slice C will make darkness shrink actual acquired vision and let physical illumination expand acquisition toward lit targets for both player and future AI observers.

First fully green Slice B executable head:

`a7a95466e70853d9abbd5de9ca1a1d5610672eaf`

All twelve required contexts were green on that exact head.

Slice A representative backend rebuild on the Slice B runner: `4085.20 µs` average (~4.09 ms). The full 80×96 canonical critique runtime also passed startup with Slice B enabled.

Exact-head owner: `verify/system27-physical-lighting`.

## Current performance state

Known scale seams:

- inactive materialized facts remain resident in WHAT and new-source 00F commits still own one full persistent-state rollback snapshot;
- System 26 sound must be re-profiled before large simultaneous actor populations;
- System 27 many-moving-light/population-scale fields need later profiling/caching even though the current physical fixture and full critique startup pass;
- Slice B light-map presentation is bounded to the active render window and gameplay never reads its GPU textures.

## Major deferred seams

- System 27 Slice C illumination-aware System 23 acquisition / neutral AI observer seam;
- prop/furniture optical-material classification for physical shadowing;
- Weather owner feeding System 27 atmosphere optics;
- electricity/generators/batteries/switches feeding real active light sources;
- population / households / causal outbreak / player story (00E);
- usable food/drink and medical treatment actions;
- condition/durability/spoilage;
- infected AI/combat and firearm/ammunition mechanics;
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
