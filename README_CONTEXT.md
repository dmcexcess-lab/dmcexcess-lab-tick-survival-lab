# Tick Survival Lab — Current Handoff

Last updated: **2026-09-03**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**.

## Current verified executable

- **Exact gameplay executable:** `fd8913df39113356bfd908377c357bbb91d54e60` — `Fix forage UI layout smoke lifecycle`.
- **Exact-head GitHub Actions:** **50 completed runs, 50 successes, zero failures, zero queued, zero running**.
- The dedicated final-head `Outdoor forage` gate passed forage behavior, the real UI-layout smoke, protected Skills/Crafting/Loot regressions and canonical startup.
- **Pages deployment:** run `33818678774` completed successfully for exact executable `fd8913df39113356bfd908377c357bbb91d54e60`.
- **Live build:** `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
- Commits after the executable are documentation/context-only and do not alter gameplay.

## Completed operation — forage / Weather DEV overlap repair

The user reported `FORAGE NEARBY` was blocked by the Weather DEV controls. The defect was literal layout overlap:

- Survival: upper-left `(8, 66)`, `326x78`;
- Weather DEV: upper-right `(344, 66)`, `288x78`;
- old forage: `(340, 66)`, `292x78`, almost directly underneath Weather;
- Utilities DEV: lower-right `(344, 148)`, `288x100`.

The repaired canonical compact-control grid is now:

- Survival — upper-left `(8, 66)`, `326x78`;
- Weather DEV — upper-right `(344, 66)`, `288x78`;
- **Forage — lower-left `(8, 148)`, `326x78`;**
- Utilities DEV — lower-right `(344, 148)`, `288x100`.

`ForagePlayerControls.gd` now exposes stable panel geometry constants and uses stable node name `ForagePanel`. No forage simulation, depletion, timing, skill, item, weather or utility behavior changed.

## Verification repair and permanent gate

`game/scripts/ci/ForageUiLayoutSmoke.gd` instantiates the actual:

- `ConditionPlayerControls`;
- `WeatherDevControls`;
- `ForagePlayerControls`;
- `UtilityDevControls`.

The first genuine main-branch Actions run exposed a test-harness lifecycle bug: the smoke measured the CanvasLayers in `_initialize()` before Godot delivered their `_ready()` callbacks, so the panels had not been built. The existing forage behavior smoke itself passed.

The harness was repaired to `await process_frame` before measuring the real controls. PR #2 then passed the complete owning `verify/outdoor-forage` gate before merge. The final main executable `fd8913df39113356bfd908377c357bbb91d54e60` subsequently passed all 50 exact-head runs and Pages deployment.

The dedicated `.github/workflows/outdoor-forage.yml` now runs on both:

- `push` to `main`;
- `pull_request` targeting `main`.

That gives future forage/layout work a genuine pre-merge owning gate instead of relying only on connector-authored main writes.

## Outdoor forage behavior remains canonical

The UI repair did not change the already-established forage model:

- one sparse persistent depletion record per deterministic 8x8 world patch;
- real materialized terrain + sky exposure + bounded local natural context determine plausibility;
- no recurring whole-world scan or resource respawn loop;
- WHEN owns time/cancellation;
- canonical Survival skill checks own duration/success/effectiveness/XP;
- valid failed searches consume finite opportunity; cancellation/impossible contexts do not;
- success creates real `Sturdy Stick` / `Smooth Stone` WHAT entities as ordinary `LOOSE_ITEM` objects at the survivor location;
- pickup, hands, inventory, containment and carry weight remain existing owners.

## Four-skill contract remains canonical

The live player skill catalog is exactly:

- **Awareness**;
- **Stealth**;
- **Mechanical**;
- **Survival**.

Mechanical covers practical machinery work such as repair, deconstruction/reclamation and hot-wiring when those owning systems exist. Survival covers first aid, scavenging/foraging, fire-starting and primitive survival crafting.

Shared rule:

> **Concrete physical prerequisite + owning world state + relevant broad skill + real WHEN time.**

A skill changes competence. It never substitutes for a missing physical tool/material or invents another domain's truth.

Current real skill consumers:

- System 32 crafting — concrete tools/materials + Mechanical/Survival checks;
- System 24 searchable-container scavenging — Survival timing/practice without rerolling physical contents;
- System 35 outdoor foraging — Survival duration/success/effectiveness over finite local opportunities.

## Primitive Survival resources/crafting already live

Real primitive resources include Sturdy Stick, Smooth Stone, Old Magazine and existing Rag Bundle / Dirty Rag / Old Newspaper semantics.

Existing bounded Survival recipes include:

1. **Sharpened Wooden Stake** — Sturdy Stick + Kitchen Knife;
2. **Improvised Stone Hammer** — Sturdy Stick + Smooth Stone + Dirty Rag + Scissors;
3. **Paper Tinder Bundle** — Old Newspaper + Old Magazine + Scissors.

Do not infer unimplemented effects from item names: the stake has no invented combat damage yet; the stone hammer is not a generalized hammer substitute; tinder has no invented ignition behavior; primitive armor is not implemented by this slice.

## Existing survivor-condition contract remains protected

- **Fatigue:** `0` rested -> `100` exhausted.
- **Rest:** separate high-is-good long-horizon sleep/recovery condition.
- No parallel live Stamina pool/HUD meter.
- Walking adds small Fatigue; running adds materially more and scales with terrain/load.
- Severe Fatigue blocks starting another run but never removes ordinary walking.
- Explicit rest/sleep relieves Fatigue; physical action time does not secretly recover it.
- Continued overexertion can cause real Health damage down to zero.
- Starvation, dehydration and sleep deprivation apply bounded real HP damage through Health.
- Moodlets remain derived warnings, not duplicate stored truth.

## Protected neighboring behavior

- Preserve the accepted full 80x96 physical-light renderer, stateless LOS and input-lock/responsiveness recovery.
- Do not solve generated utility topology defects in presentation code.
- Preserve real procedural fenced substations, roughly ten generated buildings per substation, shared roadside feeder trees, short service drops and logical/non-physical regional source-to-substation links.
- Preserve the one real persistent island-wide municipal water plant with no external-power dependency and real persistent rural private wells.
- Do not reintroduce wastewater/sewer/septic.
- Do not fake items, facilities, action resources, skill outcomes or condition/moodlet truth in UI.
- Do not add frame-driven condition/skill/resource processing, per-actor timers or recurring whole-world scans.
- Do not weaken owning Skills, Forage, Crafting, Loot, Health/Carry/input/utility tests or consolidated procedural/playable-boot matrices.

## Human acceptance status

Automated verification and deployment are complete. Human browser acceptance is still required for visible/game-feel behavior:

- confirm `FORAGE NEARBY` is visible and clickable while Weather DEV controls are present;
- confirm Survival / Weather / Forage / Utilities occupy four distinct compact slots without overlap;
- confirm forage result messaging and finite depletion still feel correct;
- confirm recovered sticks/stones use ordinary pickup behavior;
- continue prior acceptance checks for Fatigue/rest/needs/health/moodlets, movement responsiveness, lighting/LOS/startup and generated System-33 utilities;
- check desktop WebGL2 and phone/Safari presentation.

## NEXT OPERATION

1. **Human-play the deployed build** at `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/` and confirm the forage control is no longer covered by Weather DEV or any neighboring panel. Any visible/game-feel defect supersedes feature expansion and should be repaired first.
2. If accepted and no newer user direction supersedes it, implement the next bounded **real primitive Survival consumer** or a real **Mechanical repair/deconstruction owner integration**. Do not invent combat/tool/fire effects merely from item names.
3. Later integrations remain first aid through Health/Injury; Mechanical repair/deconstruction/reclamation; hot-wiring after vehicles exist; fire-starting through a real ignition/fire owner; real Awareness and Stealth gameplay consumers.

Newest explicit user direction supersedes this NEXT OPERATION.
