# Tick Survival Lab — Latest Changes

This compact ledger records the most recent work. `CHANGELOG.md` remains the historical archive.

## Health / Fatigue / Needs / Moodlet Alignment — 2026-09-03

Verified executable: `156ee4b0a1727a5d5d26b479cf7a0dea9e9b462a`

- Replaced the playable survivor's inverted stamina reserve with one canonical **Fatigue** pressure value: `0` is rested and `100` is physically exhausted. Legacy schema-v1 condition saves migrate by inversion.
- Kept **Rest** separate as the long-horizon sleep/recovery need. Walking and running add physical Fatigue; explicit rest/sleep actions relieve it; elapsed physical actions do not secretly recover it.
- Routed starvation, dehydration, sleep deprivation, and repeated overexertion into the existing canonical Health owner. Exhaustion can block starting a run, while ordinary walking remains available; continued overexertion can cause real HP loss down to zero.
- Removed positive/normal meter chips from the moodlet feed. Moodlets now surface only meaningful condition warnings, physical Fatigue, real injury/HP state, and real carry burden.
- Restored live `Injured` / `Badly Injured` / `No Vitality` and `Heavy Load` / `Overburdened` moodlets by deriving them directly from Health and Carry rather than storing duplicate flags.
- Updated the canonical HUD and player status shell to show Health and Fatigue directly, including Fatigue's current action-cost modifier.
- Left the existing skill, scavenging, crafting, and sound runtime unchanged. The next skill direction is recorded as four broad skills—Awareness, Stealth, Mechanical, Survival—with field actions and crafting sharing concrete tool + material + skill checks.
- Verified the executable with **51 completed exact-head workflows, 51 successes, zero failures and zero pending**, including the owning System 34 regression, protected canonical/UI/input/utility contracts, the 12-seed playable boot matrix, successful Pages deployment, and the aggregate exact-head status publisher.

## Procedural Boot / Black-Screen Recovery — 2026-08-31

Verified executable: `b94bc16e90c7699c0e1a95bb1556bf4bb0bdcd18`

- Traced the reported black screen to `UtilityGameMain` aborting during whole-island procedural utility preflight **before the first rendered frame**. The accepted renderer, physical-lighting presentation, LOS and input paths were not the cause and were not changed.
- Made semantic town-block count a morphology result rather than a fatal minimum. Actual generated road, parcel and building geometry remains authoritative, and current settlement density targets remain soft.
- Corrected rural lane-anchor rejection so two directed records describing the same physical straight road are not mistaken for intersecting "other" roads. This restores valid rural branch anchors without weakening real intersection clearance.
- Extended `ProceduralIslandSeedMatrixSmoke.gd` through resolved whole-island local-power topology, so remote settlement failures that can abort playable boot are caught before first-frame presentation.
- Updated the legacy-island seam regression to prove that the playable crossroads owns its real procedural settlement center instead of requiring a retired fixed world-center coordinate.
- Preserved the existing System-33 contract: roughly ten actual generated buildings per fenced local substation, shared roadside feeder trunks and short service drops, no physical regional source-to-substation wire, one grid-independent island municipal water plant, and persistent real private wells.
- Locally verified Godot 4.7.1 import/parse, twelve diagnostic seeds, canonical runtime boot, global/local generation, System-33 utilities, physical-lighting presentation, camera, input responsiveness and performance architecture.
- Verified executable `b94bc16e90c7699c0e1a95bb1556bf4bb0bdcd18` with **50 completed exact-head workflows, 50 successes, zero failures and zero pending**, including successful Pages deployment.
- The live deployment responds, but the available cloud browser lacks WebGL2 and therefore cannot provide valid visual gameplay acceptance. Final browser/phone human acceptance remains pending.

## Procedural-Island Completion Verification — 2026-08-30

Verified executable: `ed0596b5a06461083c5cda2d72ccfe820b713b3e`

- Closed the interrupted procedural-island continuation against the current repository rather than the stale handoff commit.
- Preserved the current rural-island hierarchy: real generated small towns, sparse rural settlements, road-linked developed/managed land, real civic/commercial structures, and the intended roughly **90% lived-in/managed vs. 10% true-wilderness** world balance.
- Confirmed local power topology is derived **after actual building generation**, targeting roughly **10 generated buildings per substation** rather than requiring one fake/global substation per settlement.
- Removed the stale System-20 assumption that every small-town site must already contain a legacy global substation node; secondary generated towns now correctly consume regional power service/corridor facts and receive their real local substations from the generated building manifest.
- Corrected island-wide municipal-water cell lookup so settlement cells resolve their explicit municipal service records instead of relying on the retired plant-radius model.
- Migrated the remaining protected `smalltown.center v2` smoke assertions to the implemented **v3** profile without weakening morphology, determinism, hydrology, or seam checks.
- Verified executable `ed0596b5a06461083c5cda2d72ccfe820b713b3e` with **51 completed exact-head checks, zero failures, zero pending checks**, including successful GitHub Pages deployment.
- Phase 3 remains automated-verified but still requires human browser acceptance for visible/game-feel behavior.

## Shared Roadside Power Feeder Closeout — 2026-08-30

Verified executable: `b632fc709d4fcd387eccb41fdc0e0f736bd69643`

- Replaced the remaining transformer-to-customer visual starburst with one **shared road-following feeder tree per local substation**.
- The feeder graph is built from the actual generated `local_roads` centerlines. Customer root-to-tap paths are unioned so overlapping road sections become one real shared trunk rather than duplicate wires.
- Real roadside utility poles are placed at the feeder root, customer taps, turns, junctions and deterministic spacing points, off the road surface.
- Each substation now has one short transformer-to-road `substation_lead`, deduplicated `shared_trunk` spans, and one short final `service_drop` per actual generated served building.
- Forks occur only where road/customer topology requires them; common route sections reuse the same physical poles and wire spans.
- Added strict System-33 regression coverage proving zero direct substation-to-customer rays, one final service drop per served building, real generated-road route cells, deduplicated shared trunks and actual roadside-pole reuse.
- Preserved the target of roughly **10 actual generated buildings per substation** and the intentionally non-physical regional source/ingress -> local-substation relationship.
- Migrated remaining protected rural regressions from stale global profile-v6 / retired utility assumptions to the current profile-v7 contract without weakening morphology, hydrology, determinism or physical-network assertions.
- Rural scattered projection now verifies one island-wide municipal water service fact, no invented local municipal-water facility/corridor and no retired wastewater constraints.
- Wastewater/sewer/septic remains retired and was not reintroduced to satisfy stale tests.
- Exact executable-head verification is green for `verify/system33-power-water`, local-area generation/System 20, global-world-planning and performance architecture on `b632fc7`.
- Human browser playtest remains required before Phase 3 is marked HUMAN ACCEPTED.

## Island Utility Topology + Water Contract Revamp — 2026-08-30

Earlier verified executable: `a0299a14d21fb907bdd363ddadb00cc3403b48f1`

- Rebuilt playable electrical distribution from the actual generated building manifests: local substations now target about **10 buildings each** instead of using one fake island substation.
- Local substations physically materialize as small fenced transformer/utility-box compounds.
- Regional source/ingress -> local substation is intentionally logical/non-physical for presentation; there is no fake long-distance source-to-substation wire.
- Replaced continuous analytic line wear with one deterministic day-boundary snap pass: **0.01% base per eligible span/day, +0.01% per quiet day, 1.00% cap, first snap ends the day's pass and resets quiet days**.
- A snapped real span creates a causal local outage through existing System-33 service links and emits the spatial text sound `*SNAP*`; physical repair restores only outage state owned by that fault.
- Replaced the old radius/mixed potable-water contract with **one island-wide municipal treatment facility near the shore**. Municipal service has no radius and no simulated long-distance pipe network.
- The municipal plant is a real persistent fenced facility with one critical asset; plant failure removes island-wide municipal water and repair restores it.
- The municipal plant intentionally does **not** require external grid power.
- A deterministic minority of actual generated rural homes receive real private wells: **15% target, bounded to 10–20%**. Wells have persistent physical condition and depend on the owning building group's real power service.
- Removed stale live wastewater dependencies from global generation/validity, System-20 planning constraints and the global-planning regression. Wastewater/sewer/septic is explicitly retired, not a hidden prerequisite of water.
- Migrated global planning verification to the current **rural v7** water contract and removed old wastewater/radius/local-trunk assertions.
- Full implementation record: `CHANGELOG_SYSTEM33_UTILITY_TOPOLOGY_REVAMP.md`.

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
- Phase 3 / System 33 is **IMPLEMENTED + EXACT-HEAD AUTOMATED VERIFIED** on executable `b94bc16e90c7699c0e1a95bb1556bf4bb0bdcd18`, including generated local substations, shared roadside feeder trees, physical service drops, day-boundary line snaps, island-wide municipal water, real rural wells, truthful lighting/refrigeration integration, the current procedural-island settlement hierarchy, and full playable-boot preflight across the protected seed matrix.
- Wastewater/sewer/septic is **RETIRED / NOT ACTIVE**.
- **Phase 3 human acceptance remains pending browser play of the current utility behavior and procedural-island presentation.**
