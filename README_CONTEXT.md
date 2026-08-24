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
- **23 Perception / LOS / Fog Memory** — facing LOS, true-black unexplored fog, stale remembered environment/static furniture, last-seen actors, ambient-responsive remembered presentation.
- **24 World Loot / Searchable Containers / Scavenging** — real persistent virgin loot, timed search, timed TAKE/STORE, `USABLE/JUNK + family`, playable scavenging UI.
- **25 World Time / Ambient Daylight** — authoritative-tick-derived scenario clock and smooth outdoor dawn/day/dusk/night baseline feeding System 23 remembered-fog brightness.

## Core world rules

1. System 00D owns global coherence; local/stream partitions do not invent world-spanning truth.
2. System 20 turns global facts into local physical areas; System 19 owns building interiors.
3. Generation owns virgin creation only. WHAT and typed mechanic stores own current reality afterward.
4. Technical streaming activation is not world existence.
5. Materialization is one-way; activation is reversible.
6. Art is presentation, not physics.
7. Phone/Safari remains first-class.
8. Perception knowledge is observer-specific and never substitutes hidden current truth for stale memory.
9. WHEN owns integer simulation ticks only; downstream System 25 interprets those ticks as scenario-local clock time.

## Baseline content rules

- Current city density is horizontal, not fake upper floors.
- Lodging is roadside motel content; denser housing is townhome / one-story multi-unit content.
- Blocking props cannot occupy immediate room-side door circulation.
- Parcel building selection is deterministic and fit-aware; no clipping/reroll loop.
- Occupied residential/farmstead/commercial/civic/industrial parcels get real frontage-to-entry access.
- Environment palettes are vocabulary, not permission to invent global geography.

## System 23 perception truth

Player-facing visual knowledge:

- `UNSEEN` — fully opaque black at every time of day;
- `REMEMBERED` — stale last-observed terrain, structure/door state and anchored static `prop.*` / `fixture.*` furniture/clutter;
- `VISIBLE` — current live world truth.

Candidate 001 LOS uses a 12-cell, 120-degree facing cone plus radius-1 near awareness. Walls/closed doors block; open doors/windows transmit; malformed/unknown opacity fails closed.

Remembered static furniture stores stable ID, semantic, anchor and facing. Hidden moves/removals remain stale until re-observation. Perception-memory snapshot schema is v2.

REMEMBERED environmental luminance is now presentation-driven by current System 25 outdoor ambient daylight:

- full daylight input -> `0.30` luminance;
- zero ambient input -> `0.10` luminance;
- interpolate between them;
- Candidate 001 night ambient is `0.08`, producing remembered luminance ~= `0.116`.

Memory does not store historical lighting and ambient changes never reveal hidden current WHAT. Last-seen actor markers and auditory indicators remain separate presentation channels.

Exact-head owner: `verify/system23-perception`.

## System 24 loot truth

> **Loot exists before you search for it.**

- searchable furniture is real System 11 container truth;
- deterministic stable `item.*` entities are created once during source loot initialization;
- System 24 owns provenance, System 11 owns current contents;
- looted/empty containers never automatically repopulate;
- failed virgin initialization rolls WHAT + System 11 + System 24 back exactly;
- each loot semantic has `USABLE` or `JUNK` plus one primary family and optional tags;
- container tables are building/furniture-context aware;
- search is timed and reads current contents at completion;
- TAKE/STORE/place remain timed System 12 actions;
- external acquisition respects System 13E's hard carry ceiling;
- the live Rural Crossroads fixture exposes a phone-friendly search/TAKE/STORE panel.

System 12's neutral `ItemContainerAccessPolicy` seam allows policy-aware external world containers without weakening the original personal-container service.

Exact-head owner: `verify/system24-loot`.

## System 25 world-time / daylight truth

System 25 interprets, but never advances, authoritative WHEN time.

Candidate 001 world-time profile:

- 5 ticks / simulation second;
- 300 ticks / minute;
- 18,000 ticks / hour;
- 432,000 ticks / day;
- scenario starts day 0 at 08:00:00.

Candidate 001 outdoor daylight:

- dawn: 05:30 -> 07:30;
- full daylight: 07:30 -> 18:30;
- dusk: 18:30 -> 20:30;
- night baseline: `0.08`;
- full daylight: `1.0`.

`WorldTimeService` derives day/time directly from current `world_tick`; it owns no second clock. `OutdoorAmbientLightService` produces the normalized daylight scalar/phase and emits changes when authoritative time changes. Hard pause therefore freezes the clock/daylight automatically.

Visible-world lighting is deliberately deferred until interiors, windows, local lights, power, fire/flashlights and weather can be modeled honestly.

First fully green executable System 25 head: `6b6680c5b8eb4d8db2c4097df093abace661d5c7`.

Exact-head owner: `verify/system25-world-time-light`.

## Current performance state

The 2026-08-23 materialization razor retained modular ownership while adding coalesced WHAT terrain writes, one outer 00F rollback transaction, same-region streaming fast paths and coalesced renderer invalidation.

Known long-horizon scale seam: inactive materialized facts remain resident in WHAT and new-source 00F commits still own one full persistent-state rollback snapshot. Persistence-backed eviction/write journals remain future work when profiling justifies them.

## Major deferred seams

- population / households / causal outbreak / player story (00E);
- food/drink and medical effects;
- condition/durability/spoilage;
- visible-world/local/artificial lighting and weather attenuation;
- real spatial sound;
- infected AI/combat and firearm/ammunition mechanics;
- crafting/recycling;
- locks/keys/forced entry;
- corpse loot/decay;
- vehicles/cargo;
- NPC scavenging/ownership/theft;
- outbreak-driven virgin loot depletion;
- generic quantity/stack mechanics;
- persistence-backed streaming eviction;
- calendar date/season/latitude beyond System 25's scenario-local day/time profile.

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
- `verify/pages-deploy`
