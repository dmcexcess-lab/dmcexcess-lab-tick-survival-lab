# Tick Survival Lab — Current Handoff

Last updated: **2026-09-03**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**.

## Current verified executable

- **Exact gameplay executable:** `11035c7d0b1dd7eb01b076aec244b818d7f6fe56` — `Add bounded outdoor Survival forage`
- **Exact-head GitHub Actions:** **51 completed runs, 51 successes, zero failures, zero queued, zero running, zero cancelled**.
- Includes successful `verify/outdoor-forage`, full protected repository verification, the streaming/materialization 12-seed planner + playable boot matrices, exact-head status publishing and Pages deployment.
- **Live build:** `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
- Commits after the executable are documentation-only and do not change gameplay code.

## Completed operation — bounded outdoor Survival foraging

The primitive Survival chain now has a real outdoor acquisition seam rather than relying only on searchable containers.

### Real local opportunity truth

- `OutdoorForageState` stores sparse persistent depletion only for deterministic **8x8 world patches** that are actually touched by a valid forage request.
- Patch identity is stable from world seed + patch coordinates.
- A patch stores finite opportunity count plus deterministic stick/stone weighting; it does **not** pre-spawn or simulate hidden ground items.
- There is **no passive replenishment / respawn loop** in this implementation.

### Real environment validation

`ForageNearbyActionService` evaluates plausibility only when a forage action is requested/committed, using existing owners:

- real materialized terrain;
- canonical `SkyExposureQuery` for outdoors/enclosure truth;
- a bounded scan of the current 8x8 patch;
- actual generated tree/shrub/rock object semantics from the environment-profile catalog.

Water, unmaterialized ground, indoors, or otherwise implausible contexts hard-block without spending an opportunity. No recurring whole-world scan was added.

### WHEN + Survival

- action: `survival.forage_nearby`;
- base duration: 10 ticks;
- Survival difficulty: 2;
- canonical WHEN owns elapsed time and cancellation;
- canonical `ActorSkillCheckService` owns skill-adjusted duration, deterministic success/effectiveness and bounded XP;
- resolution uses the real WHEN action serial/context, so the service does not add a parallel RNG or free reroll seam.

Behavior:

- starting a valid action does not consume the opportunity yet;
- canceling before commit consumes nothing and creates nothing;
- a valid completed search consumes one local opportunity even if no material is recovered;
- depleted patches hard-block further attempts and do not auto-refill;
- high effectiveness may recover two physical units from one opportunity, otherwise one;
- internal commit failures use bounded compensation before mutations escape the service.

### Physical output truth

Successful recovery uses existing real semantics:

- `item.outdoors.sturdy_stick` — Sturdy Stick;
- `item.outdoors.smooth_stone` — Smooth Stone.

Outputs are created through canonical `WorldMutationService` as real persistent WHAT entities and placed on the survivor cell in the normal `LOOSE_ITEM` spatial layer.

**Forage does not directly grant inventory.** Existing pickup, hands, inventory, containment and carry-weight owners remain authoritative.

### Live surface

A compact `FORAGE NEARBY` control is composed **adjacent to** the existing survival controls. It is only a request/result surface; resource, skill, time and item truth remain in their owning systems.

## Four-skill contract remains canonical

The live player skill catalog is exactly:

- **Awareness**;
- **Stealth**;
- **Mechanical**;
- **Survival**.

Mechanical covers practical machinery work such as repair, deconstruction/reclamation and hot-wiring when those owning systems exist. Survival covers first aid, scavenging/foraging, fire-starting and primitive survival crafting.

The shared rule is:

> **Concrete physical prerequisite + owning world state + relevant broad skill + real WHEN time.**

A skill changes competence. It never substitutes for a missing physical tool/material or invents another domain's truth.

Current real skill consumers:

- System 32 crafting — concrete tools/materials + Mechanical/Survival checks;
- System 24 searchable-container scavenging — Survival timing/practice without rerolling physical contents;
- System 35 outdoor foraging — Survival duration/success/effectiveness over finite local opportunities.

Legacy six-skill schema-v1 saves migrate atomically into schema v2: Technical -> Mechanical; Survival takes the strongest accumulated progression among legacy Scavenging/Survival/Medical; Awareness and Stealth begin at 0/0; Combat/Social retire.

## Primitive Survival resources/crafting already live

Real primitive resources include:

- Sturdy Stick;
- Smooth Stone;
- Old Magazine;
- existing Rag Bundle / Dirty Rag / Old Newspaper semantics.

Existing bounded Survival recipes include:

1. **Sharpened Wooden Stake** — Sturdy Stick + Kitchen Knife;
2. **Improvised Stone Hammer** — Sturdy Stick + Smooth Stone + Dirty Rag + Scissors;
3. **Paper Tinder Bundle** — Old Newspaper + Old Magazine + Scissors.

These are real physical transformations through System 32. Do **not** infer unimplemented effects from item names:

- the stake has no invented combat damage behavior yet;
- the stone hammer is not yet a generalized replacement for normal Hammer requirements;
- tinder has no invented ignition behavior yet;
- primitive armor is not implemented by this slice.

Connect those outputs only through real combat/tool/fire/equipment owners when those consumers exist.

## Verification completed

Executable `11035c7d0b1dd7eb01b076aec244b818d7f6fe56` is exact-head automated-green.

Owning forage verification proves:

- valid outdoor request and finite depletion;
- physical loose-item outputs;
- bounded high-skill two-unit recovery;
- cancellation consumes no opportunity and creates no output;
- failed valid search consumes the opportunity, awards bounded Survival practice XP and manufactures no item;
- impossible water context hard-blocks and creates no depletion record;
- sparse depletion snapshot round-trip;
- deterministic same-seed/patch/opportunity results.

Protected exact-head verification also passed:

- Actor Skills, System 32 Crafting and System 24 World Loot;
- Health / Needs / Carry / Moodlet / Freshness domains;
- movement, running, exertion, input responsiveness and damage interruption;
- interaction/reach and spatial sound;
- System 33 power/water;
- physical lighting, perception/LOS and large visual geometry;
- procedural generation and streaming/materialization;
- full 12-seed procedural planner matrix and canonical playable boot matrix;
- canonical startup;
- Pages build/deployment and exact-head status publishing.

Final automated state: **51/51 exact-head run records successful; no failed, pending, queued or cancelled run remains.**

## Existing survivor-condition contract remains protected

- **Fatigue:** `0` rested -> `100` physically exhausted.
- **Rest:** separate high-is-good long-horizon sleep/recovery condition.
- There is no parallel live Stamina pool or Stamina HUD meter.
- Walking adds small Fatigue; running adds materially more and scales with terrain and real carried load.
- Severe Fatigue blocks starting another run but never removes ordinary walking.
- Physical action time does not secretly recover Fatigue; explicit rest/sleep actions relieve it.
- Continued exertion beyond maximum Fatigue can cause real Health damage down to zero.
- Starvation, dehydration and sleep deprivation apply bounded real HP damage through Health.
- Moodlets remain derived warnings, not duplicated stored truth.

## Protected neighboring behavior

- Preserve the accepted full 80x96 physical-light renderer, stateless LOS and input-lock/responsiveness recovery.
- Do not solve generated utility topology defects in presentation code.
- Preserve real procedural fenced substations, roughly ten generated buildings per substation, shared roadside feeder trees, short service drops and logical/non-physical regional source-to-substation links.
- Preserve the one real persistent island-wide municipal water plant with no external-power dependency and real persistent rural private wells.
- Do not reintroduce wastewater/sewer/septic.
- Do not fake items, facilities, action resources, skill outcomes or condition/moodlet truth in UI.
- Do not add frame-driven condition/skill/resource processing, per-actor timers or recurring whole-world scans.
- Do not weaken owning Skills, Forage, Crafting, Loot, Health/Carry/input/utility tests or the consolidated procedural/playable-boot matrices.

## Human acceptance status

Automated verification is complete, but human browser acceptance is still required for current visible/game-feel behavior on WebGL2 desktop and phone/Safari:

- Fatigue/rest/needs/health/moodlet feel;
- four-skill crafting and searchable-container scavenging presentation;
- `FORAGE NEARBY` usability, result messaging, finite depletion and ordinary pickup of recovered sticks/stones;
- movement responsiveness, lighting/LOS and startup baseline;
- generated System-33 power-line/substation/water/well behavior across representative fresh seeds.

## NEXT OPERATION

1. **Human-play the current Web build** on desktop WebGL2 and phone/Safari across the acceptance items above. Treat any visible/game-feel defect as the next repair before expanding scope.
2. If accepted and no newer user direction supersedes it, implement the next bounded **real primitive Survival consumer** using the now-real resources/crafted outputs. Do not invent weapon/tool/fire effects merely because an item name suggests them.
3. Remaining Phase-6 integrations, only through their real owners:
   - first aid through Health/Injury;
   - Mechanical repair and deconstruction/reclamation through actual target owners;
   - hot-wiring once vehicle ownership exists;
   - fire-starting through a real ignition/fire owner;
   - real Awareness and Stealth gameplay consumers.

Newest explicit user direction supersedes this NEXT OPERATION.
