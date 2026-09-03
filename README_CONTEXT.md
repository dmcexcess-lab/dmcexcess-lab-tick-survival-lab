# Tick Survival Lab — Current Handoff

Last updated: **2026-09-03**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**.

## Current repository / executable state

- **Latest gameplay source candidate:** `c0b1464cbe478cea174d78f33d5510b5e62a24f1` — forage UI overlap repair.
- **Last exact-head automated-green executable:** `11035c7d0b1dd7eb01b076aec244b818d7f6fe56` — bounded outdoor Survival forage before the UI-only repair.
- `11035c7d0b1dd7eb01b076aec244b818d7f6fe56` completed **51/51 exact-head GitHub Actions runs successfully**, with zero failures, queued, running or cancelled, including `verify/outdoor-forage`, full protected repository verification, 12-seed planner/playable boot matrices, Pages deployment and exact-head status publishing.
- The commits after `c0b1464cbe478cea174d78f33d5510b5e62a24f1` are documentation-only; they do not change gameplay code.
- **Live build URL:** `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
- **Important:** do not assume the live Pages build contains the UI repair yet. GitHub created zero Actions runs for the connector-authored repair commits, so Pages did not redeploy from this tool session.

## Completed source repair — forage hidden by Weather DEV controls

User reported that the new forage button was blocked by the Weather DEV options.

The root cause was exact and local:

- `WeatherDevControls` occupied `(344, 66)` with size `288x78` on CanvasLayer 35.
- `ForagePlayerControls` occupied `(340, 66)` with size `292x78` on CanvasLayer 34.
- The two panels were therefore almost perfectly stacked, and the higher-layer Weather DEV panel visually/input-wise covered forage.

### Repair now in source

`ForagePlayerControls.gd` now uses the unused lower-left compact-control slot:

- Survival: upper-left `(8, 66)`, `326x78`;
- Weather DEV: upper-right `(344, 66)`, `288x78`;
- **Forage: lower-left `(8, 148)`, `326x78`;**
- Utilities DEV: lower-right `(344, 148)`, `288x100`.

Additional repair details:

- forage panel geometry is exposed as stable constants;
- the live panel has stable node name `ForagePanel`;
- button width was adjusted to the wider left-column panel;
- no forage simulation, depletion, timing, skill, item, weather or utility behavior changed.

### New regression

Added `game/scripts/ci/ForageUiLayoutSmoke.gd`.

It instantiates the **actual**:

- `ConditionPlayerControls`;
- `WeatherDevControls`;
- `ForagePlayerControls`;
- `UtilityDevControls`.

It asserts their canonical rectangles and fails if forage intersects Weather, Survival or Utilities. `.github/workflows/outdoor-forage.yml` now runs this layout smoke in addition to the existing forage behavior, skill, crafting, loot and canonical-startup regressions.

## Verification limitation for the UI repair

The source repair is committed on `main`, but exact-head Actions verification could not be triggered from the available GitHub connector.

Observed facts:

- source commit `4c18feef6cf4356ce7b32b03301ebaa5e32121c4` moved `main` successfully but produced **0 GitHub Actions runs**;
- a second normal Contents-API source commit, `c0b1464cbe478cea174d78f33d5510b5e62a24f1`, also produced **0 GitHub Actions runs**;
- repeated exact-head Actions queries returned zero runs/statuses for those SHAs;
- the installed GitHub connector exposes workflow/run reads and reruns, but **no workflow-dispatch/start-new-run action**;
- local fallback is unavailable in this session: no local Godot executable and the container cannot reach GitHub normally for a clone/download.

Therefore:

- **do not call `c0b1464...` exact-head CI green yet;**
- **do not call the live Pages build repaired yet;**
- the last fully automated-green executable remains `11035c7d...`;
- the UI source change itself is narrow and statically clear, but its new Godot layout smoke still needs an actual Actions execution.

## Outdoor forage behavior remains canonical

The already-verified forage system remains unchanged by the UI repair:

- one sparse persistent depletion record per deterministic 8x8 world patch;
- real materialized terrain + sky exposure + bounded local natural context determine plausibility;
- no recurring whole-world scan or resource respawn loop;
- WHEN owns time/cancellation;
- canonical Survival skill checks own duration/success/effectiveness/XP;
- valid failed searches consume finite opportunity; cancellation/impossible contexts do not;
- success creates real `Sturdy Stick` / `Smooth Stone` WHAT entities as ordinary `LOOSE_ITEM` objects at the survivor location;
- pickup, hands, inventory, containment and carry weight remain existing owners.

## Four-skill contract remains canonical

The live skill catalog is exactly:

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

Human acceptance remains pending. Once the repaired source is actually built/deployed, explicitly verify:

- `FORAGE NEARBY` is visible and clickable while Weather DEV controls are present;
- Survival / Weather / Forage / Utilities occupy four distinct compact slots without overlap;
- forage result messaging and finite depletion still feel correct;
- recovered sticks/stones use ordinary pickup behavior;
- Fatigue/rest/needs/health/moodlet feel;
- movement responsiveness, lighting/LOS/startup baseline;
- generated System-33 power/substation/water/well behavior on representative fresh seeds;
- desktop WebGL2 and phone/Safari layouts.

## NEXT OPERATION

1. **First close the verification/deployment gap for source `c0b1464cbe478cea174d78f33d5510b5e62a24f1`.** Trigger or observe a genuine GitHub Actions event (user-originated push, workflow dispatch, or future tool path that emits the event). Require at minimum `verify/outdoor-forage` with `FORAGE_UI_LAYOUT_SMOKE_OK`, canonical startup, and Pages deployment to complete successfully. If any gate fails, repair it and repeat.
2. Human-play the deployed build and confirm the forage control is no longer covered by Weather DEV or any neighboring panel.
3. Only after that gate—or newer explicit user direction—resume feature expansion. The next bounded implementation should be a **real** primitive Survival consumer or a real Mechanical repair/deconstruction owner integration. Do not invent combat/tool/fire effects merely from item names.
4. Later integrations remain first aid through Health/Injury; Mechanical repair/deconstruction/reclamation; hot-wiring after vehicles exist; fire-starting through a real ignition/fire owner; real Awareness and Stealth gameplay consumers.

Newest explicit user direction supersedes this NEXT OPERATION.
