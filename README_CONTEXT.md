# Tick Survival Lab — Current Context

> Read `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, `SYSTEM_DESIGNS/README.md`, current `main`, and the relevant system design before repository changes.

## Game

> **Ultima-style turn-based mini Zomboid.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden archaeology commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## Current canonical world stack

- **00A WHERE** — implemented global integer-cell spatial model.
- **00B WHAT** — implemented single authoritative persistent current world.
- **00C WHEN** — implemented deterministic tick/action/pause kernel.
- **00D Global World Planning** — implemented `temperate.rural.region` v6: geography, five settlements/sites, major roads, river/bridge intent, regional electrical, potable-water and wastewater/septic planning.
- **19 Building Generation** — finalized grammar plus **24 callable archetypes**: six protected rural/small-town references and 18 baseline one-story residential/lodging/commercial/civic/industrial/agricultural profiles.
- **20 Local Area Generation** — implemented ten area profiles:
  - `rural.crossroads` v5;
  - `smalltown.center` v1;
  - `rural.scattered` v1;
  - `rural.open` v1;
  - `rural.watercourse` v1;
  - `suburban.neighborhood` v1;
  - `urban.mixed` v1;
  - `commercial.corridor` v1;
  - `industrial.district` v1;
  - `civic.campus` v1.
- **20 Environment profiles** — `temperate.rural` v3 plus suburban, urban, industrial, woodland, coastal and marsh v1 palettes.
- **00F Streaming / Materialization** — implemented settlement + dry-countryside logical sources, one-way materialization, reversible technical activation, registry snapshot schema v1, no destructive eviction.
- **21 Camera** and **22 Large-Area DEV Critique Runtime** — implemented. Live presentation remains the Rural Crossroads critique world.
- **23 Perception / LOS / Fog Memory** — implemented Candidate 001: deterministic facing-based LOS, true black unexplored fog, stale remembered environment, per-observer memory, last-seen living-actor observations, and perception-layer support for future auditory cues.

## Baseline world-content rules

1. **City density is horizontal for the current game.** New baseline buildings are one story; complexity comes from useful rooms, adjacency, units and realistic circulation rather than fake upper floors.
2. **Lodging is roadside motel content, not a fake multi-story hotel.** Denser residential content is represented as townhomes or one-story multi-unit rows.
3. **Multi-unit exterior access is physical.** Individual units/rooms may have separate exterior doors; one designated primary exterior door remains System 20's placement/access anchor.
4. **Door approaches are reserved circulation.** Blocking props do not materialize on room cells immediately adjacent to a door.
5. **Area building selection is parcel-fit aware.** Baseline profiles deterministically choose from their allowed System 19 archetypes that physically fit the parcel; no reroll loop or clipping is used.
6. **All occupied land uses get real access.** Residential, farmstead, commercial, civic and industrial buildings receive finalized frontage-to-primary-entry access paths.
7. **Environment palette is not geography truth.** Woodland/coastal/marsh palettes are reusable local vocabulary only; they do not authorize System 20 to invent a forest/coast/marsh that System 00D has not planned.

First exact executable head with the expanded System 19/20 baseline libraries and the complete protected stack green: `2e7a6e0da27a02f8058a3a79538cd9cb55a48cef`.

## Important world rules

1. System 00D owns global coherence; local/streaming partitions never invent world-spanning geometry.
2. System 20 converts global facts into local physical semantic terrain/areas; System 19 owns building internals.
3. Generation owns virgin creation only. WHAT and typed mechanic stores own current reality after materialization.
4. Technical streaming activation is not world existence.
5. Materialization is one-way; activation is reversible.
6. 00F logical source identity is independent from technical stream-region geometry.
7. Current 00F source kinds are settlement sites and catalog-v1 dry countryside. Physical river/bridge terrain now exists in System 20, but the river corridor intentionally has no 00F logical source kind yet.
8. Water is never replaced with fake dry terrain; bridges require actual System 00D bridge intent.
9. Art is presentation, not physics.
10. Phone/Safari remains first-class.
11. Perception knowledge is observer-specific and never substitutes hidden current world truth for stale memory.

## Current architecture cleanup state

Active process/design authority is intentionally small:

- North Star;
- design-decision log;
- this current-state index;
- one SOP/workflow document (`README_SOPS.md`);
- the System Design status ledger;
- current canonical per-system designs;
- changelog/history.

Completed candidate/slice discussion docs are not active peer systems once their rules have been folded into the owning canonical system design.

Materialization source adapters follow one common provider contract instead of requiring coordinator fields/branches per source kind.

## Current performance state

The 2026-08-23 performance razor preserved the modular ownership model and optimized the actual hot path instead of merging systems:

- initial terrain materialization uses coalesced WHAT terrain mutations rather than one change/revision/signal per cell;
- standalone building/area materializers remain transactional, while an enclosing System 00F transaction reuses one outer WHAT + Door State + registry rollback snapshot instead of taking another full-world snapshot per area/building;
- moving focus within the same technical streaming region uses a zero-discovery/zero-materialization fast path;
- `GroundLayerRenderer` understands coalesced terrain dirty geometry so one relevant terrain batch requests one redraw rather than one redraw per cell.

On the same GitHub runner class and the same 00F regression workloads, the settlement suite improved from about **55.6s to 13.9s** (~75% faster / ~4.0× throughput) and the countryside suite from about **63.4s to 10.7s** (~83% faster / ~5.9× throughput). These are multi-scenario CI regression timings, not literal player-facing load latency.

Known scale seam: System 00F still intentionally owns one full persistent-state snapshot for an atomic new-source batch, and inactive materialized facts remain resident in WHAT. Persistence-backed residency/eviction or a write-journal transaction model remains future work when measured world-size/mobile memory pressure justifies it.

Verified performance code head: `0b10957bb586162634e9da3c1a4415aef528fd2d`.

## System 23 Perception / LOS / Fog Memory

Status: **IMPLEMENTED — Candidate 001**.

Canonical player-facing knowledge model:

- **UNSEEN / true fog** — completely black visual world information;
- **REMEMBERED fog** — darkened stale last-observed terrain and structural shell, including the last observed door state;
- **VISIBLE** — normal current live world truth;
- **last-seen living actors** — stale remembered markers that do not secretly follow hidden actors;
- **sound indicators** — the perception layer can accept future auditory cues over visible, remembered, or completely unexplored true black fog without revealing the terrain underneath or marking a cell explored.

Candidate 001 uses a 12-cell deterministic 120-degree facing cone plus radius-1 all-around near awareness. Walls and closed doors block LOS; open doors and windows transmit. Unknown/malformed structure opacity fails closed. Persistent memory is maintained per stable observer actor ID; the current canonical demo maintains full memory for the controlled survivor.

Existing live renderers remain current-truth renderers. `PerceptionOverlayRenderer` blacks all non-visible cells and redraws only stored remembered snapshots above the black mask, preventing hidden live state from leaking through memory.

The first fully green executable System 23 head after the final LOS fixture correction is `87fb517265ba1defc395068d09ccb7059e16d114`. On that exact code head, `verify/system23-perception` and all seven protected exact-head contexts were green.

## Deferred seams

The baseline suburb/urban/commercial/industrial/civic profiles are reusable System 20 content, not proof that the current System 00D rural-region fixture already contains those district types. Future global geography/settlement work may select them when its own planning truth authorizes them.

A future **00F river-source provider** remains a known clean seam when continuous streamed river traversal is actually needed; it is not the default next task merely because System 20 watercourse generation exists.

Real Spatial Sound is a natural gameplay follow-up because the System 23 contract already defines hearing as independent from sight. Lighting, infected AI/combat, scavenging/search pressure, and population/outbreak remain later choices rather than being silently bundled into perception.

## Verification contexts used for protected world-stack changes

Owning/current contexts:

- `verify/system19-local-building`
- `verify/system20-local-area`
- `verify/system23-perception`

Protected exact-head stack:

- `verify/system00d-global-world`
- `verify/system00f-streaming-materialization`
- `verify/system19-local-building`
- `verify/system20-local-area`
- `verify/system21-camera-view`
- `verify/system22-area-critique`
- `verify/pages-deploy`