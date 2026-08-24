# Tick Survival Lab — Current Context

> Read `PROJECT_NORTH_STAR.md`, `README_SOPS.md`, `SYSTEM_DESIGNS/README.md`, current `main`, and the relevant system design before repository changes.

## Game

> **Ultima-style turn-based mini Zomboid.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden archaeology commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

## Current canonical world/gameplay stack

- **00A WHERE** — implemented global integer-cell spatial model.
- **00B WHAT** — implemented single authoritative persistent current world.
- **00C WHEN** — implemented deterministic variable-duration tick/action/pause kernel.
- **00D Global World Planning** — implemented `temperate.rural.region` v6.
- **01–18 gameplay foundation** — collision, movement, locomotion, art/rendering, doors, hands, inventory, timed item transfer, health/needs/skills/item weight/carry/moodlets, canonical player shell/HUD, run/exertion and door passage are implemented.
- **19 Building Generation** — finalized grammar plus **24 callable archetypes**: six protected rural/small-town references and 18 baseline one-story residential/lodging/commercial/civic/industrial/agricultural profiles.
- **20 Local Area Generation** — ten area profiles and seven environment palettes.
- **00F Streaming / Materialization** — settlement + dry-countryside logical sources, one-way materialization, reversible technical activation, no destructive eviction.
- **21 Camera** and **22 Large-Area DEV Critique Runtime** — implemented.
- **23 Perception / LOS / Fog Memory** — deterministic facing LOS, true black unexplored fog, stale remembered terrain/structures/doors/static furniture and last-seen living actors.
- **24 World Loot / Searchable Containers / Scavenging** — implemented Candidate 001: real persistent virgin loot, searchable physical furniture, timed search, timed TAKE/STORE through System 12, `USABLE/JUNK + family` taxonomy, one-way no-respawn initialization and playable mobile scavenging UI.

## Baseline world-content rules

1. **City density is horizontal for the current game.** Baseline buildings are one story; complexity comes from rooms, adjacency and units rather than fake upper floors.
2. **Lodging is roadside motel content**, not fake multi-story hotels. Denser housing is townhomes / one-story multi-unit rows.
3. **Multi-unit exterior access is physical.** Individual units/rooms may have separate exterior doors; one primary exterior door remains System 20's placement/access anchor.
4. **Door approaches are reserved circulation.** Blocking props do not materialize on immediate room-side door approaches.
5. **Area building selection is parcel-fit aware.** No reroll loop or clipping.
6. **All occupied land uses get real access.** Residential, farmstead, commercial, civic and industrial parcels receive road/frontage-to-entry access.
7. **Environment palette is not geography truth.** Woodland/coastal/marsh palettes do not authorize global landforms System 00D has not planned.

## Persistent world rules

1. System 00D owns global coherence; local/streaming partitions never invent world-spanning geometry.
2. System 20 converts global facts into local physical areas; System 19 owns building interiors.
3. Generation owns virgin creation only. WHAT and typed mechanic stores own current reality afterward.
4. Technical streaming activation is not world existence.
5. Materialization is one-way; activation is reversible.
6. 00F logical source identity is independent from technical stream-region geometry.
7. Water is never replaced with fake dry terrain; bridges require real System 00D bridge intent.
8. Art is presentation, not physics.
9. Phone/Safari remains first-class.
10. Perception knowledge is observer-specific and never substitutes hidden current truth for stale memory.

## System 23 perception truth

Player-facing visual knowledge has three terrain/environment states:

- `UNSEEN` — true black;
- `REMEMBERED` — dark stale last-observed terrain, structural/door state and anchored static `prop.*` / `fixture.*` furniture/clutter;
- `VISIBLE` — current live world truth.

Candidate 001 vision uses a 12-cell 120-degree facing cone plus radius-1 near awareness. Walls/closed doors block; open doors/windows transmit; unknown opacity fails closed.

Furniture/clutter memory stores stable ID, semantic, anchor and facing. Hidden moves/removals remain stale until re-observation. Perception-memory snapshots are schema v2.

Exact-head owner: `verify/system23-perception`.

## System 24 loot truth

Core rule:

> **Loot exists before you search for it.**

Candidate 001 behavior:

- eligible physical furniture is explicitly enrolled as real System 11 containers;
- deterministic virgin `item.*` WHAT entities are created and contained **once** when a physical source is loot-initialized;
- System 24 persists source/container provenance only; System 11 remains sole current-contents truth;
- initialized empty/looted containers never repopulate;
- exact WHAT + System 11 + System 24 rollback protects failed source initialization;
- loot definitions require top-level `USABLE` or `JUNK`, plus a primary practical family such as food, drink, kitchen, medical, tools, farming, construction, electrical, household, office, sanitation, industrial, etc.;
- junk is real persistent weighted item truth, not fake filler;
- location-aware profiles distinguish grocery/pharmacy/hardware/convenience/gas-station shelves and cover household fridges, pantries, vanities, dressers, medical storage, office storage, warehouse/tool/farm storage and other current furniture;
- search is a real `CANCELABLE` WHEN action and reads current contents at completion;
- search reach and world-container transfer access use actor footprint + one-cell-forward fringe;
- TAKE / STORE / placing remain System 12 item transfers and spend ticks;
- live Candidate 001 transfer timing is 5 ticks per System 12 action type;
- external container -> personal acquisition uses the existing System 13E hard carry ceiling;
- the live Rural Crossroads critique runtime initializes its deterministic buildings for loot and provides a phone-friendly search/TAKE/STORE panel.

System 12 now exposes an additive neutral `ItemContainerAccessPolicy` seam. The original `ItemTransferActionService` remains personal-only; `PolicyAwareItemTransferActionService` adds optional external access while preserving the old contract and regressions.

System 19 now exposes `GeneratedBuildingPlan.entity_id_for_role(role)` so downstream systems can refer to generated physical entities without duplicating materializer identity rules.

First fully green executable System 24 head:

`411099a3c39b7abeeb189e8a176491cb7e410b6d`.

Exact-head owner:

`verify/system24-loot`.

On that exact executable head all nine required contexts were green: System 24, 23, 22, 21, 20, 19, 00F, 00D and Pages.

## Current performance state

The 2026-08-23 performance razor preserved modular ownership while removing the measured materialization hot path:

- coalesced WHAT terrain mutation batches;
- one outer System 00F transaction snapshot instead of nested per-area/building full-world snapshots;
- same-technical-region zero-discovery/zero-materialization fast path;
- coalesced terrain renderer invalidation.

Known scale seam: inactive materialized facts remain resident in WHAT and a new-source 00F transaction still owns one full persistent-state rollback snapshot. Persistence-backed eviction/write journals remain future work when measured world-size/mobile pressure justifies them.

## Deferred seams

Major intentionally deferred domains include:

- population / households / causal outbreak / player story (00E);
- food/drink effects;
- medical treatment effects;
- item condition/durability and food spoilage;
- lighting and real spatial sound;
- infected AI/combat and firearm/ammunition mechanics;
- crafting/recycling;
- container locks/keys/forced entry;
- corpse loot/decay;
- vehicles/cargo;
- NPC scavenging/ownership/theft;
- outbreak-driven virgin loot depletion;
- generic item quantity/stack mechanics;
- persistence-backed streaming eviction.

A future 00F river-source provider remains a clean seam when continuous streamed river traversal actually requires it.

## Verification contexts

Current world/gameplay exact-head contexts:

- `verify/system00d-global-world`
- `verify/system00f-streaming-materialization`
- `verify/system19-local-building`
- `verify/system20-local-area`
- `verify/system21-camera-view`
- `verify/system22-area-critique`
- `verify/system23-perception`
- `verify/system24-loot`
- `verify/pages-deploy`
