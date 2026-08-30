# Tick Survival Lab — Latest Changes

This compact ledger records the most recent work. `CHANGELOG.md` remains the historical archive.

## Island Utility Topology + Water Contract Revamp — 2026-08-30

Verified executable: `a0299a14d21fb907bdd363ddadb00cc3403b48f1`

- Rebuilt playable electrical distribution from the actual generated building manifests: local substations now target about **10 buildings each** instead of using one fake island substation.
- Local substations physically materialize as small fenced transformer/utility-box compounds.
- Regional source/ingress -> local substation is intentionally logical/non-physical for presentation; there is no fake long-distance source-to-substation wire.
- Visible local spans originate at substations and terminate at customer poles placed near the real generated buildings they serve.
- Replaced continuous analytic line wear with one deterministic day-boundary snap pass: **0.01% base per eligible span/day, +0.01% per quiet day, 1.00% cap, first snap ends the day's pass and resets quiet days**.
- A snapped real span creates a causal local outage through existing System-33 service links and emits the spatial text sound `*SNAP*`; physical repair restores only outage state owned by that fault.
- Replaced the old radius/mixed potable-water contract with **one island-wide municipal treatment facility near the shore**. Municipal service has no radius and no simulated long-distance pipe network.
- The municipal plant is a real persistent fenced facility with one critical asset; plant failure removes island-wide municipal water and repair restores it.
- The municipal plant intentionally does **not** require external grid power.
- A deterministic minority of actual generated rural homes receive real private wells: **15% target, bounded to 10–20%**. Wells have persistent physical condition and depend on the owning building group's real power service.
- Removed stale live wastewater dependencies from global generation/validity, System-20 planning constraints and the global-planning regression. Wastewater/sewer/septic is explicitly retired, not a hidden prerequisite of water.
- Migrated global planning verification to the current **rural v7** water contract and removed old wastewater/radius/local-trunk assertions.
- Fixed an unrelated Pages title-guard substring false positive so ordinary words such as `ultimately` no longer block deployment.
- Exact-head `verify/system33-power-water`, global-world-planning and Pages build/export/deploy are green on `a0299a1`.
- Full implementation record: `CHANGELOG_SYSTEM33_UTILITY_TOPOLOGY_REVAMP.md`.
- **Human browser playtest remains required before Phase 3 is marked HUMAN ACCEPTED.**

## Stage B — Earlier Physical Power Network Foundation — 2026-08-29

Earlier verified executable: `7ddee8df0e638cbe14897d83632b62513d5fc574`

- Established stable physical wire-span/support identity and causal mapping into System-33 service links.
- Added `UtilityNetworkConditionStore`, direct damage/repair seams, persistent visible topology while de-energized, and renderer endpoint caching.
- That version's continuous analytic-wear scheduler is now superseded by the 2026-08-30 once-per-game-day snap model. The physical identity, causal outage and repair foundations remain current.

## Powered Non-Bloom Room Lighting — 2026-08-29

Verified executable: `c7592c956a44c31b082db84ae597f43c643231c4`

- Added one persistent invisible `fixture.room_light` WHAT entity per generated room.
- Room fixtures bind to real System-33 service for their cell and feed physical System-27 illumination only while powered.
- `light.room_ambient.candidate001` raises physical luminance while suppressing presentation glow/bloom.
- Ordinary visible lights retain glow and the player flashlight still requires real equipped flashlight truth.

## Truthful Lighting / Performance Recovery — accepted lineage

- Fake default flashlight and demo-coordinate fixed-light sources were removed from gameplay ownership.
- Fixed lights now derive from persistent WHAT fixture identity and actual placement.
- The human-accepted full-window physical-light path and responsiveness/black-screen recovery remain protected by System-33 regressions.

## Project Status

- Roadmap Phase 1 remains complete.
- Roadmap Phase 2 / System 32 Crafting remains **COMPLETE + CI VERIFIED**.
- Compact-island/world-seam cleanup and the responsiveness/black-screen recovery are **HUMAN ACCEPTED**.
- Phase 3 / System 33 is **IMPLEMENTED + EXACT-HEAD AUTOMATED VERIFIED** on executable `a0299a14d21fb907bdd363ddadb00cc3403b48f1` with local substations, physical service drops, day-boundary line snaps, island-wide municipal water, real rural wells, truthful lighting and refrigeration integration.
- Wastewater/sewer/septic is **RETIRED / NOT ACTIVE**.
- **Phase 3 human acceptance remains pending browser play of the current utility behavior.**
