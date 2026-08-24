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
- **24 World Loot / Searchable Containers / Scavenging** — persistent virgin loot, timed search, timed TAKE/STORE, `USABLE/JUNK + family`, playable scavenging UI.
- **25 World Time / Ambient Daylight** — authoritative-tick-derived scenario clock and smooth outdoor daylight baseline.
- **26 Spatial Sound / Hearing** — physical acoustic propagation, stat/status-sensitive listener hearing, constrained localization uncertainty and yellow-word cues.
- **27 Physical Lighting / Illumination / Shadows** — **Slice A implemented**: deterministic headless illumination, enclosure/portal light, local emitters, atmosphere optics and target-light-driven useful vision-range policy. Rich visual lighting (B) and live Perception gating (C) remain pending.

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

Visual states remain:

- `UNSEEN` — fully opaque black;
- `REMEMBERED` — stale last-observed environment/static furniture;
- `VISIBLE` — current live truth.

Current live geometric LOS is a 12-cell, 120-degree cone plus radius-1 near awareness. Memory schema is v2.

REMEMBERED luminance currently follows System 25 outdoor ambient daylight: 0.30 at full daylight toward 0.10 at zero ambient; Candidate night ambient 0.08 yields ~=0.116.

System 23 presents System 26 auditory observations as yellow words without revealing terrain.

System 27 Slice A now exposes the physical target-light range contract, but **the live System 23 visible-cell set is not yet illumination-gated**. That integration belongs to System 27 Slice C so memory/observer knowledge remains owned by Perception.

Exact-head owner: `verify/system23-perception`.

## System 24 loot truth

> **Loot exists before you search for it.**

Searchable furniture is real System 11 container truth. Deterministic `item.*` entities are created once during source loot initialization; System 24 owns provenance while System 11 owns current contents. Empty/looted containers never automatically repopulate. Search is timed, TAKE/STORE remain System 12 actions, and external acquisition respects System 13E's hard carry ceiling.

Exact-head owner: `verify/system24-loot`.

## System 25 world-time / daylight truth

Candidate 001:

- 5 ticks / simulation second;
- 300 ticks / minute;
- 18,000 ticks / hour;
- 432,000 ticks / day;
- scenario starts day 0 at 08:00:00;
- dawn 05:30–07:30;
- full daylight 07:30–18:30;
- dusk 18:30–20:30;
- night baseline 0.08.

System 25 derives time directly from `world_tick`; hard pause therefore freezes it automatically. System 27 consumes this daylight downstream without changing WHEN.

Exact-head owner: `verify/system25-world-time-light`.

## System 26 spatial-sound truth

> **Sound is physical. Hearing is an estimate.**

Candidate 001:

- exact `SoundEmission` truth is separate from listener `HeardSoundObservation` knowledge;
- propagation is a bounded deterministic material-aware field through WHAT + Door State;
- survivor hearing derives from Survival, fatigue and sleep pressure;
- poor hearing widens uncertainty/reduces recognition without flipping true front/rear/left/right signs;
- yellow words may appear over black fog without visual exploration;
- cue age uses WHEN ticks only;
- current emitters are successful Walk steps, each Run stride and truthful Door transitions;
- neutral hearing/environment seams preserve future infected/animal hearing and weather masking.

First fully green executable head: `2d3dcfa6fc8646cda62a5e775beb1ac7c8d04d08`.

Candidate common-footstep propagation benchmark: `13268.29 µs` average across 100 fields.

Exact-head owner: `verify/system26-spatial-sound`.

## System 27 physical-lighting truth

> **Light is physical. Vision is observer-specific. Rendering visualizes lighting; gameplay and AI never read rendered pixels to decide what is illuminated.**

Slice A implements:

- `AtmosphericOptics` clear/overcast/rain/fog/storm-compatible input contract;
- semantic flashlight/lamp/streetlight/neon emitter profiles;
- exact active `LightEmitter` descriptors supplied by source owners;
- `IlluminationSample` per tactical cell with sky/direct/portal/local contributions, useful luminance, tint, dominant direction, glare and scatter;
- bounded `PhysicalLightingService` with no frame-time simulation advancement;
- structure-envelope interior/sky-exposure approximation;
- window and OPEN-door portal daylight;
- direct local-light wall/door/window transmission;
- deterministic physical flashlight shadows at cell resolution;
- small diffuse spill that cannot leak through opaque walls/closed doors;
- fog extinction + scatter behavior;
- deterministic multi-source composition;
- target-cell-light-driven useful vision range.

### Candidate 001 useful vision range

The current geometric maximum remains 12 cells. Slice A exposes a light-derived useful range:

- luminance 0.0 -> 2-cell useful range;
- luminance 1.0 -> 12-cell geometric maximum;
- response uses `sqrt(luminance)` between those endpoints;
- radius-1 near awareness remains protected;
- **the target cell's illumination drives the range**, not merely the observer's local light level.

Therefore standing under a bright lamp does not grant long-range vision into darkness; illuminating a distant target can expand useful range toward that target.

Slice C will make System 23 actually apply this policy to current visual acquisition. Slice B will visualize physical lighting with shadows/glows/beams.

First fully green Slice A executable head:

`b43b9d02d206658ce8155e485a2ab72be454cc0e`

All twelve required contexts were green on that exact head.

Representative bounded lighting rebuild benchmark: `4297.78 µs` average (~4.30 ms) on the GitHub runner.

Exact-head owner: `verify/system27-physical-lighting`.

## Current performance state

Known scale seams:

- inactive materialized facts remain resident in WHAT and new-source 00F commits still own one full persistent-state rollback snapshot;
- System 26 common sound propagation meets its current single-field budget but must be re-profiled before large simultaneous actor populations;
- System 27 bounded light rebuild is currently ~4.30 ms on the CI fixture, but many moving lights/large active AI fields require later profiling/caching before scale assumptions.

## Major deferred seams

- System 27 Slice B rich visible lighting/shadows/glow;
- System 27 Slice C illumination-aware System 23 acquisition / neutral AI observer seam;
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
- real conventional audio playback, if ever desired.

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
