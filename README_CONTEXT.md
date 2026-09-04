# Tick Survival Lab — Current Handoff

Last updated: **2026-09-03**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**.

## Current verified executable

- **Exact gameplay executable:** `ad975a08c5a62d178d6bf8e79c2dc21b08c4905c` — `Store recovered forage in survivor inventory`.
- **Exact-head GitHub Actions:** **51 completed runs, 51 successes, zero failures, zero queued, zero running**.
- **Pages deployment:** run `33819643054` completed successfully for exact executable `ad975a08c5a62d178d6bf8e79c2dc21b08c4905c`.
- **Live build:** `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
- The owning PR #3 forage gate passed before merge: Godot import/parse, forage behavior, real forage UI layout, protected Skills/Crafting/Loot regressions and canonical startup all succeeded.
- The full main-branch protected suite then passed, including the 12-seed planner/playable boot matrices and streaming/materialization regressions.
- Commits after `ad975a08...` are documentation/context-only and do not alter gameplay.

## Completed operation — forage finds enter personal inventory

User acceptance established that the repaired `FORAGE NEARBY` control is visible/clickable, but exposed a behavior mismatch: a successful forage result was created only as a loose item at the survivor's feet instead of appearing in personal inventory.

The root cause was in `ForageNearbyActionService`: successful recovery always committed each new Sturdy Stick / Smooth Stone through `WorldMutationService.set_placement(... LOOSE_ITEM ...)` and never used the already-existing personal-inventory admission owners.

The canonical behavior is now:

1. forage still resolves one finite local physical opportunity through WHEN + Survival;
2. success still creates a **real persistent item entity** (`Sturdy Stick` or `Smooth Stone`);
3. `ActorCarryAcquisitionPolicy` evaluates whether that new item's real mass can be admitted;
4. when allowed, `InventoryContainmentMutationService` places the real entity directly in the survivor's personal inventory container;
5. the existing inventory inspector sees it normally and `ActorCarryQuery` counts its real mass;
6. if the hard carry ceiling blocks admission, the item is not deleted or invisibly granted — it remains a normal real `LOOSE_ITEM` at the survivor's feet.

High-effectiveness two-item forage results admit each recovered entity through the same capacity policy independently.

Rollback was also repaired so a later commit/XP failure clears containment before removing a recovered entity, avoiding ghost inventory membership.

## Owning regression

`game/scripts/ci/OutdoorForageSmoke.gd` now proves all of the following together:

- capacity-allowed recovered items become direct contents of the survivor personal inventory;
- contained forage items have no simultaneous loose-world placement;
- recovered mass appears in canonical carry weight / carry item IDs;
- an artificially over-hard-cap survivor receives no invisible inventory bypass and the recovered items remain physically at their feet;
- valid forage still consumes finite depletion;
- cancellation consumes no opportunity and creates no item;
- failed valid searches consume the opportunity, grant bounded Survival practice XP and manufacture no item;
- impossible water context hard-blocks without creating depletion state;
- sparse depletion snapshot round-trip remains deterministic;
- same seed/patch/opportunity resolves the same resource.

No forage skill roll, duration, depletion, resource selection, renderer, weather, generation, loot-container or crafting semantics were weakened.

## Outdoor forage behavior remains canonical

- one sparse persistent depletion record per deterministic 8x8 world patch;
- real materialized terrain + sky exposure + bounded local natural context determine plausibility;
- no recurring whole-world scan, hidden resource population or passive resource respawn loop;
- WHEN owns time/cancellation;
- canonical Survival skill checks own duration/success/effectiveness/XP;
- valid failed searches consume finite opportunity; cancellation/impossible contexts do not;
- successful recovery creates only real Sturdy Stick / Smooth Stone WHAT entities;
- normal result destination is the survivor's real personal inventory when carry admission allows it;
- hard-capacity rejection leaves real loose items at the survivor location;
- hands, inventory, containment, physical weight and carry limits remain existing owners.

## Forage UI layout remains accepted/protected

The prior visible Weather DEV overlap repair remains in place:

- Survival — upper-left `(8, 66)`, `326x78`;
- Weather DEV — upper-right `(344, 66)`, `288x78`;
- Forage — lower-left `(8, 148)`, `326x78`;
- Utilities DEV — lower-right `(344, 148)`, `288x100`.

`ForageUiLayoutSmoke.gd` waits for the real Godot `_ready()` lifecycle, measures the actual four control layers and fails on overlap. User reported this UI repair worked in the live build before identifying the inventory-destination defect.

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

Automated verification and deployment are complete.

Already accepted by user:

- `FORAGE NEARBY` is accessible after the Weather DEV overlap repair.

Still pending after this latest executable:

- perform a successful forage in the live build and confirm the recovered Sturdy Stick / Smooth Stone appears immediately in **Inventory** under normal carry capacity;
- confirm its weight contributes normally to carried load;
- optional hard-cap check: if the survivor exceeds the hard carry admission ceiling, the found resource should remain physically at the survivor's feet rather than vanish;
- continue prior acceptance checks for Fatigue/rest/needs/health/moodlets, movement responsiveness, lighting/LOS/startup, generated System-33 utilities and desktop/phone/Safari presentation.

## NEXT OPERATION

1. **Human-play the deployed build** at `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/` and confirm a successful `FORAGE NEARBY` result now appears directly in personal Inventory and counts toward carried weight. Any visible/game-feel defect supersedes feature expansion and should be repaired first.
2. If accepted and no newer user direction supersedes it, implement the next bounded **real primitive Survival consumer** or a real **Mechanical repair/deconstruction owner integration**. Do not invent combat/tool/fire effects merely from item names.
3. Later integrations remain first aid through Health/Injury; Mechanical repair/deconstruction/reclamation; hot-wiring after vehicles exist; fire-starting through a real ignition/fire owner; real Awareness and Stealth gameplay consumers.

Newest explicit user direction supersedes this NEXT OPERATION.
