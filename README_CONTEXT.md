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
- **19 Building Generation** — finalized current rural/small-town building grammar/library.
- **20 Local Area Generation** — implemented current profiles:
  - `rural.crossroads` v5;
  - `smalltown.center` v1;
  - `rural.scattered` v1;
  - `rural.open` v1;
  - `rural.watercourse` v1;
  - environment `temperate.rural` v3.
- **00F Streaming / Materialization** — implemented settlement + dry-countryside logical sources, one-way materialization, reversible technical activation, registry snapshot schema v1, no destructive eviction.
- **21 Camera** and **22 Large-Area DEV Critique Runtime** — implemented. Live presentation remains the Rural Crossroads critique world.

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

## Next development choice

There is **no automatically active next design** after the cleanup pass.

The project has enough world substrate to justify shifting attention back toward the playable survival loop. Before adding more generation/streaming infrastructure, prefer a gameplay-value review of systems such as perception/LOS, spatial sound, infected/AI/combat, scavenging/search pressure, or population/outbreak behavior.

A future **00F river-source provider** remains a known clean seam when continuous streamed river traversal is actually needed; it is not the default next task merely because System 20 watercourse generation now exists.

## Verification contexts used for protected world-stack changes

- `verify/system00d-global-world`
- `verify/system00f-streaming-materialization`
- `verify/system19-local-building`
- `verify/system20-local-area`
- `verify/system21-camera-view`
- `verify/system22-area-critique`
- `verify/pages-deploy`
