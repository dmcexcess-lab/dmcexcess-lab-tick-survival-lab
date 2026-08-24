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
- **23 Perception / LOS / Fog Memory** — facing LOS, true-black unexplored fog, stale remembered environment/static furniture, last-seen actors and auditory presentation layer.
- **24 World Loot / Searchable Containers / Scavenging** — real persistent virgin loot, timed search, timed TAKE/STORE, `USABLE/JUNK + family`, playable scavenging UI.
- **25 World Time / Ambient Daylight** — authoritative-tick-derived scenario clock and smooth outdoor dawn/day/dusk/night baseline feeding remembered-fog brightness.
- **26 Spatial Sound / Hearing** — deterministic physical acoustic propagation, stat/status-sensitive listener hearing, constrained localization uncertainty and yellow-word auditory cues.

## Core rules

1. System 00D owns global coherence; local/stream partitions do not invent world-spanning truth.
2. System 20 turns global facts into local physical areas; System 19 owns building interiors.
3. Generation owns virgin creation only. WHAT and typed mechanic stores own current reality afterward.
4. Technical streaming activation is not world existence.
5. Materialization is one-way; activation is reversible.
6. Art is presentation, not physics.
7. Phone/Safari remains first-class.
8. Perception knowledge is observer-specific and never substitutes hidden current truth for stale memory.
9. WHEN owns integer simulation ticks only; System 25 interprets them as scenario-local clock time.
10. **Sound is physical; hearing is an estimate.** Exact sound-source truth is not observer knowledge.

## System 23 perception truth

Visual states remain:

- `UNSEEN` — fully opaque black;
- `REMEMBERED` — stale last-observed environment/static furniture;
- `VISIBLE` — current live truth.

Candidate LOS is a 12-cell, 120-degree cone plus radius-1 near awareness. Memory schema is v2.

REMEMBERED luminance follows current System 25 outdoor ambient daylight: 0.30 at full daylight toward 0.10 at zero ambient; Candidate night ambient 0.08 yields ~=0.116 remembered luminance.

System 23 now presents live System 26 auditory descriptors as yellow words above any visual knowledge state. Auditory cues never reveal terrain or mark visual exploration.

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

System 25 derives time directly from `world_tick`; hard pause therefore freezes it automatically. Visible-world lighting remains deferred.

Exact-head owner: `verify/system25-world-time-light`.

## System 26 spatial-sound truth

> **Sound is physical. Hearing is an estimate.**

Candidate 001:

- exact `SoundEmission` physical truth is separated from listener `HeardSoundObservation` knowledge;
- listener observations contain perceived position/strength/word/certainty but no exact hidden source cell/entity;
- propagation is one bounded deterministic weighted eight-neighbor acoustic field per emission through materialized WHAT + Door State;
- cardinal/diagonal travel costs are 10/14;
- open door/window/closed door/wall attenuation additions are 4/36/64/124, unknown structure 132;
- high-loss barriers can be heard through when sufficiently loud, while the solver chooses cheaper routes around them when available;
- survivor hearing derives from base 50 + Survival (up to +40) - fatigue (up to -15) - sleep pressure (up to -20);
- poor hearing mainly widens range/bearing uncertainty and reduces recognition specificity;
- **hard localization rule:** true front/rear/left/right signs can never flip; a sound behind the survivor cannot be displayed in front;
- localization is deterministic per event/listener, never rerolled by rendering;
- yellow words include `NOISE`, `MOVEMENT`, `FOOTSTEPS`, `IMPACT`, `THUD` and may appear over black fog;
- off-screen words clamp to the edge using the perceived location, not exact source truth;
- cue age uses WHEN ticks only, so auto/hard pause preserves cues while the player decides;
- repeated source/category groups refresh one cue;
- live physical emitters are successful Walk steps, each Run stride and truthful Door transitions; no fake ambient threat noises are generated;
- neutral `HearingProfileProvider` and `AcousticEnvironmentModifier` seams preserve future infected/animal hearing and weather/background masking.

First fully green executable System 26 head:

`2d3dcfa6fc8646cda62a5e775beb1ac7c8d04d08`.

On that exact head all eleven required contexts were green.

Candidate common walk-footstep propagation benchmark on that runner: `13268.29 µs` average across 100 fields, under the 16 ms target but explicitly a future many-emitter scale seam.

Exact-head owner: `verify/system26-spatial-sound`.

## Current performance state

The 2026-08-23 materialization razor retains coalesced WHAT writes, one outer 00F rollback transaction, same-region streaming fast paths and coalesced renderer invalidation.

Known scale seams:

- inactive materialized facts remain resident in WHAT and new-source 00F commits still own one full persistent-state rollback snapshot;
- Candidate 001 sound propagation meets its single-field budget but needs re-profiling before large simultaneous infected/NPC populations.

## Major deferred seams

- population / households / causal outbreak / player story (00E);
- usable food/drink and medical treatment actions;
- condition/durability/spoilage;
- visible-world/local/artificial lighting and weather attenuation;
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
- `verify/pages-deploy`
