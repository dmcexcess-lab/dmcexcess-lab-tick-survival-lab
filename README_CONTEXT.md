# Tick Survival Lab — Current Handoff

Last updated: **2026-09-04**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**. Newer explicit user direction supersedes this handoff.

## Current repository / executable truth

- **Verified + deployed gameplay executable:** `0f12cfcd1e5efb85bf5261fcbd92a497a44387e2`.
- The current `main` after this handoff is the documentation-only commit containing this file; it does not change the executable relative to `0f12cfcd...`.
- Exact executable head `0f12cfcd...` completed **51 successful Actions runs** with **0 failed, 0 cancelled, 0 queued and 0 running**.
- Pages run **`33892432702`** completed successfully for exact executable head `0f12cfcd...`.
- **Live build:** `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
- `CHANGELOG_LATEST.md` records the town-first island and crash repair. Later documentation-only heads do not change the executable relative to `0f12cfcd...`.
- Actual Godot project root is **`game/`**.

## Completed operation — settlement-first island and browser startup repair

The settlement-first island and population work is published. Current generation creates:

- two 640×640 town-scale sites intended to resemble settlements in the 1,000–5,000-person range;
- three village/crossroads sites intended to resemble 50–100-person settlements;
- six rural home/farm sites;
- an island envelope derived after settlement placement rather than a fixed coast rectangle that constrains the towns.

Every settlement aggregate is derived from its real deterministic residential building manifest. Household records retain building ID, archetype and capacity. `infected + survivors == residents` is an enforced invariant. This is authoritative population truth for future zombie actor hydration; do not add an independent spawn-count source.

The first published town-first executable could stall/crash in browsers before the first frame. The repaired boot path now:

- generates one compact structural manifest for all eleven sites;
- stores it on `GeneratedGlobalWorldPlan`;
- has population and utility topology consume the same building/road/driveway/parking/structural-prop truth instead of independently regenerating the island;
- omits only the irrelevant empty-cell natural-ecology noise scan from that boot manifest; normal streamed area generation remains fully dressed;
- selects the major-road settlement tree geometrically and runs terrain-aware A* only for selected physical roads, instead of pathfinding hundreds of discarded candidate edges.

The follow-up exact-head System-33 gate exposed duplicate physical trunk spans where separate neighborhood service groups overlapped. `NeighborhoodPowerInfrastructureMaterializer` now reuses the same real roadside poles and physical trunk span across groups and unions their affected service IDs, preserving correct damage/outage causality without duplicate wires.

Local Godot 4.7.1 verification passed complete-island planning, the 12-seed procedural matrix, System-33 power/water, roadside routing, physical network and infrastructure smokes, plus an actual seed-28028 game launch reaching `CANONICAL_DEMO_BOOT_OK` after deterministic rerolls.

## Completed operation — canonical ownership / legacy scaffold cleanup

User approved the prior repository audit and explicitly directed implementation. This operation removed obsolete live ownership and stale demo scaffolding without pretending the remaining gameplay-closure features are complete.

### System 34 is the only live survivor condition / Fatigue owner

Normal gameplay composition no longer constructs:

- `ActorNeedsState`;
- `ActorNeedsMobilityModifierProvider`;
- legacy `MovementExertionService`;
- legacy `ActorMoodletService`.

`System34GameMain` now installs the canonical condition mobility/exertion/moodlet path directly instead of creating old ownership in `GameMain` and disconnecting it later.

Historical Needs classes and focused old tests remain in the active tree as recovery/test substrate only. Do **not** infer that they are live gameplay owners. Retire/migrate them only when their useful assertions have been preserved elsewhere.

`ActorStatusSummaryQuery` supports canonical System-34 condition directly. Its legacy Needs path is optional only for isolated historical fixtures.

### Awareness has a real live consumer

`SurvivorHearingProfileProvider` now derives live survivor hearing competence from canonical **Awareness** rather than using Survival as a generic perception stat.

- canonical System-34 Fatigue/rest still physically reduce hearing performance;
- production hearing is Awareness-backed;
- the historical legacy-Needs fixture comparison retains its old Survival path only until that fixture is retired.

This does **not** complete the full Awareness/Stealth closure. Awareness still needs broader noticing/acquisition integration through existing perception ownership, and Stealth still needs a real detectability consumer.

### Utility repair vocabulary is Mechanical

The physical utility condition/network owner no longer exposes a nonexistent `electrical_skill` requirement.

- utility condition repair requirement key is `mechanical_skill`;
- failure reason is `insufficient_mechanical_skill`;
- `UtilityPowerNetworkRuntime` / `UtilityGameMain` use Mechanical terminology.

Important: this is still a **low-level owner seam**. Do **not** claim player-facing utility repair is complete. The final interaction closure still needs a real target action with a concrete tool, concrete material entity/entities, Mechanical check and WHEN duration before mutating this owner.

### Production scene / DEV scaffold cleanup

Normal `game/main.tscn` now roots at **`TickSurvivalGame`**, not `CanonicalDemo`.

Removed from normal production boot:

- automatic `WeatherDevControls` scene node;
- automatic `UtilityDevControls` construction;
- empty `DemoLightingSourceAdapter`.

The Weather/Utility DEV tool classes may remain available for deliberate development injection, but they are not normal gameplay UI/ownership.

Fresh gameplay weather no longer forces the old rainy critique state at boot; `WeatherService` starts from its normal generated clear-state ownership.

The empty demo-light adapter was deleted. Lighting CI/smokes were migrated so they protect the real owners instead:

- physical flashlight shadow;
- real room-light fixtures;
- real powered fixed fixtures;
- outage / restore truth;
- glow/presentation maps;
- illumination-aware perception.

Do not recreate a compatibility shim merely to satisfy old naming.

### Stale protection contracts repaired from evidence

The first cleanup heads correctly exposed CI assumptions that explicitly required `DemoLightingSourceAdapter`. Those failures were stale contract failures, not a reason to restore the adapter.

Migrated:

- `.github/workflows/system33-lighting-truth.yml`;
- `.github/workflows/physical-lighting.yml`;
- `System33LightingTruthSmoke.gd`;
- `PhysicalLightingPresentationSmoke.gd`.

One intermediate Actor Stats failure was an external runner download reset (`curl 35`, connection reset by peer) before Godot import/test; it recurred successfully on the final exact head with no source workaround.

## Canonical app composition — remaining structural debt

Current production inheritance stack remains:

`VehicleGameMain -> System34GameMain -> UtilityGameMain -> CraftingGameMain -> GameMain`

This works and is protected, but it is still a patch-stack composition architecture. Later cleanup should flatten this into one explicit composition/install sequence once the practical interaction closure is complete. Do **not** create another subclass layer for the next gameplay consumer unless there is a compelling independent owner/lifecycle reason.

`GameMain` still uses `GeneratedIslandCritiqueFixture.gd` as a live production dependency. Despite the name, it currently supplies real canonical generated-world/bootstrap state, so **do not delete it yet**. Productionize/rename/replace its ownership first, prove the replacement, then retire the old fixture seam.

`_boot_canonical_demo()` and the `CANONICAL_DEMO_BOOT_OK` marker remain compatibility naming used by existing startup gates. They are naming debt, not a second demo runtime.

## Four-skill contract — canonical

Exactly:

- **Awareness**
- **Stealth**
- **Mechanical**
- **Survival**

Shared gameplay rule:

> **Concrete physical prerequisite + owning world state + relevant broad skill + real WHEN time.**

Skill changes competence. It never replaces missing tools/materials, bypasses another subsystem's truth, or invents a hidden parallel resource.

Current real examples:

- crafting — Mechanical / Survival;
- searchable-container scavenging — Survival;
- outdoor foraging — Survival;
- vehicle hot-wire / repair / modification — Mechanical;
- hearing competence — Awareness.

## System 36 Vehicles — protected current truth

Vehicles remain implemented and deployed. Preserve the accepted recent user decisions:

- skateboard, bicycle, motorcycle, car, truck only;
- car real footprint **1x3**;
- truck real footprint **2x3**;
- dedicated class sprites;
- car sprite art fills its real 1x3 footprint;
- true-vehicle left/right action traces three cells using 30°, 60°, 90° headings and completes a 90° turn;
- reverse = one checked cell backward, heading preserved, ends stopped;
- brake remains separate two-cell stop;
- no Driving skill;
- Mechanical owns hot-wire/repair/modification competence.

Honest remaining vehicle limits:

1. intermediate 30°/60° collision still resolves through the nearest-cardinal WHAT footprint vocabulary; do not claim arbitrary-angle collision polygons/cell masks are complete;
2. gas-can refuel is whole-item transfer, not partial fluid quantity;
3. generated parked population is bounded near the current playable start, not island-wide streaming materialization;
4. physical battery/spare-wheel items exist but dedicated replacement consumers are not implemented;
5. cargo rack is the only real installed modification so far;
6. cross-owner vehicle-placement + mounted-actor placement does not yet have full transactional rollback if the second commit unexpectedly fails;
7. human browser/game-feel acceptance is still pending.

## Construction rule — authoritative

> **No freeform base building. Construction is limited to reinforcing existing doors/windows and repairing broken existing objects.**

Do not implement open-land walls/floors/roofs/base structures. Existing places may be occupied, repaired and fortified through real target owners.

## Protected neighboring behavior

Do not regress:

- accepted decision-pause input locking / no input backlog;
- full physical-light renderer and stateless LOS;
- real utility topology, local substations and grid-independent municipal water plant / rural wells;
- forage direct-to-personal-inventory behavior with hard-cap loose-item fallback;
- canonical inventory/containment/item-weight ownership;
- canonical Health/Injury + System-34 Fatigue/needs/moodlet ownership;
- no live Stamina resurrection;
- real vehicle persistence/cargo/fuel/lighting/sound/crash consequences;
- no frame-driven skill/condition/resource/vehicle simulation;
- no per-entity timers or recurring whole-world scans;
- no UI-owned fake repair/fire/first-aid/vehicle truth;
- no wastewater/sewer/septic resurrection unless explicitly redesigned later.

## Final skills / crafting / items / usable-object closure — still pending

The structural cleanup above is complete. The practical gameplay consumers found by the audit are **not** all complete. Reuse existing owners rather than inventing parallel systems.

Pending closure targets:

1. generalized usable-item/action effects where useful, reusing real WHAT inventory items + WHEN + owning condition/health state rather than one-off fake buttons;
2. cooking through real ingredients, tools/work surface, real heat source and Survival;
3. first aid / medicine through real treatment items, Health/Injury, Survival where appropriate and WHEN;
4. real fire lifecycle through tinder/fuel/ignition prerequisites, weather interaction, heat/light ownership and Survival;
5. Mechanical repair of broken world objects through actual target state + real tool/material + WHEN;
6. deconstruction/reclamation only for actual existing targets, with real tools/material outputs and Mechanical; no freeform construction loophole;
7. player-facing utility repair routed through the existing physical utility condition owner instead of accepting abstract material counts from UI;
8. primitive crafted outputs connected to real consumers where those owners now exist;
9. broader usable furniture/utilities: beds, sinks/water, refrigeration, stoves/ovens, lights/switches, workbenches, generators, doors/windows and vehicle components through existing interaction/affordance ownership;
10. broader Awareness integration into noticing/acquisition without cheating LOS or creating a second perception system;
11. real Stealth detectability integration through existing perception/sound owners;
12. richer vehicle component maintenance only through real installed/component owners.

Existing food/drink sustainment is already substantially real: it consumes actual carried entities after WHEN completion, checks freshness, uses truthful water-source injection and bed/sleep-surface ownership. Extend that substrate rather than rebuilding food/drink from scratch.

## Cleanup still pending after practical closure

After the real consumers above are connected and protected:

- migrate useful assertions from legacy Needs/exertion tests, then remove the dead historical runtime classes from active source if nothing needs them;
- review/remove `IslandLegacySeamSmoke` and other explicitly legacy seams only when their underlying seam is actually gone;
- consolidate duplicate historical world-planning smoke variants where assertions overlap;
- productionize/rename `GeneratedIslandCritiqueFixture` and remaining canonical-demo naming;
- flatten the app-composition inheritance onion into explicit composition;
- continue vehicle fidelity/transaction hardening.

Git history remains the recovery source; do not keep dead active adapters merely because they once had tests.

## Human acceptance still pending

Automated verification is green but human acceptance remains necessary for:

- vehicle sprite proportion/offset/turn/reverse/brake feel;
- generated parking plausibility and vehicle panel/cargo UX;
- headlights/crash presentation;
- current condition/Fatigue/rest/needs/moodlet feel;
- forage personal-inventory/carry presentation;
- representative generated utility behavior on fresh seeds;
- desktop browser and phone/Safari presentation.

## NEXT OPERATION

Unless newer user direction supersedes this:

1. Obtain human browser acceptance of executable `0f12cfcd...`, especially whether it now reaches the first playable frame without crashing/stalling. If it still fails, capture the browser console/error and seed marker and diagnose that exact failure before expanding scope.
2. Inspect the new settlement proportions, residential density, roads/coast and utility physicalization on multiple fresh seeds. Treat visible generation defects as real generator/materializer defects rather than renderer patches.
3. Wire future zombie hydration/movement to `GeneratedGlobalWorldPlan.population_settlements`; do not add an independent spawn count. Use bounded active/streamed actor hydration against the authoritative aggregate rather than instantiating the entire island population at once.
4. Then begin the **practical usable-object closure** rather than another scaffold refactor.
5. First establish/reuse one narrow generalized action/effect seam only where it genuinely reduces duplication: real carried/target item + prerequisite tool/resource + broad skill + WHEN + owning-state commit.
6. Close **first aid / medicine and fire / cooking** against existing Health/Injury, condition, freshness, crafting, lighting/weather and inventory owners.
7. Close **Mechanical world-object repair/deconstruction** and route player-facing utility repair through real tools/material entities + WHEN into the existing utility condition owner.
8. Wire broader **Awareness** and first real **Stealth** consumers into the existing perception/sound owners without bypassing LOS.
9. Extend real furniture/utility affordances and vehicle component maintenance only where authoritative target/component state exists.
10. Run owning/protected regressions, verify exact executable head and Pages, then retire only the historical classes/tests whose assertions have been migrated.
11. After this closure, proceed toward Actor/NPC AI + combat/causal outbreak, then final graphics/UI overhaul -> Beta, subject to newer user direction.
