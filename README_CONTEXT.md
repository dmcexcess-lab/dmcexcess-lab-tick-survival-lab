# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — SURVIVAL RELEASE PHASE 2 TECHNICAL COMBAT ACCEPTANCE CLOSED; REAL SAFARI ACCEPTANCE REMAINS — 2026-09-25

Phase 1 remains complete. Phase 2 commitment windows, simultaneous melee consequences, causal movement/shove/death ordering, closed mob-force core, canonical fear, bounded eight-infected callback/perception cost, coherent overlapping consequence presentation, and the real crowded-fight touch/control acceptance route are now protected.

Starting main for this operation: `94bea679b48584804f8f87f444ecdc9a883af739`.

Final functional/attribution head before documentation: `51350037bb890efc4e2684027142a939f0d4687a`.

Focused final attribution run: `36208557288` — **SUCCESS**.

Prior functional crowded-fight run: `36208495717` — **SUCCESS**.

Documentation head immediately before this final handoff write: `52f2abc96f3d4e5427b8f9afcec333b58b3fffcd`.

This `README_CONTEXT.md` commit is the final repository write for the operation. Identify its exact SHA from `main`; everything after it is read-only verification.

## Prompt-local verifier lifecycle

The previous consequence-presentation verifier/workflow were retired before this operation:

- `game/scripts/ci/Phase2ConsequencePresentationSmoke.gd`
- `.github/workflows/phase2-consequence-presentation.yml`

Fresh current pair:

- `game/scripts/ci/Phase2CrowdedFightAcceptanceSmoke.gd`
- `.github/workflows/phase2-crowded-fight-acceptance.yml`

The next code-changing prompt must delete this pair before changing code and create a fresh prompt-local verifier/workflow scoped only to the concrete new operation.

If the next operation is only the real Safari acceptance pass and no code changes are required, do not churn the verifier merely to satisfy ceremony.

## Completed — real eight-infected crowded-fight route

The fresh verifier boots the real production `gameplay.tscn` and uses:

- the actual active eight-infected resident-backed cohort;
- the actual touch-first `PlayerMovementControls` Buttons;
- the production semantic-intent routing;
- the production player action controller and input-busy ownership;
- the single WHEN/TickKernel clock;
- production perception, infected behavior, Movement, Combat, Health/death, mob pressure and consequence presentation.

The canonical island boot naturally places the eight infected roughly 40–75 cells from the player. The first focused acceptance attempt therefore produced 32 infected behavior evaluations but 0 infected action submissions; accepted empty STRIKE actions were correctly rejected as evidence of a crowd fight.

The verifier was repaired rather than production. It now uses authoritative `WorldMutationService.set_placements_batch()` solely as an acceptance-fixture setup to move those same already-hydrated production actor identities into nearby collision-valid cells. It does not fabricate actors, AI decisions, hits, damage, pressure, movement, death or presentation events.

After setup, all fight behavior and consequences are ordinary production behavior.

## Completed — automatic pause and touch-input ownership

Final route evidence:

- eight active infected;
- 2 ordinary touch-driven turn actions;
- 3 ordinary touch-driven strike actions;
- 5 accepted-action input-lock cycles;
- 27 shared world ticks;
- each accepted action leaves the decision pause;
- the touch surface remains locked while the action/world resolves;
- input re-enables only after the next legitimate decision pause;
- real physical contact occurs;
- overlapping same-timestamp consequence presentation occurs coherently;
- player remained at 100 HP in this deterministic route.

Marker:

`PHASE2_CROWDED_FIGHT_ACCEPTANCE_OK active=8 turns=2 strikes=3 overlap=true contact=true final_tick=27`

This proves the mobile/touch semantic action path without substituting desktop keyboard input.

## Completed — performance attribution without speculative rewrite

Final CI attribution route:

- accepted-action elapsed total: 1,937,370 usec across 5 accepted actions;
- max accepted action: 477,635 usec;
- route elapsed: 2,017,918 usec.

Existing exclusive counters measured:

- infected behavior evaluation: 52,684 usec;
- infected perception: 81,204 usec;
- player perception: 63,629 usec;
- active-cohort sync: 20,552 usec;
- infected intention refresh: 3,930 usec;
- infected action submission: 17,939 usec.

Shared `PerformanceTelemetry` measured:

- lighting rebuild: 262,873 usec total;
- lighting geometry rebuild: 151,494 usec;
- lighting draw: 163,862 usec;
- perception recompute: 144,833 usec;
- infected behavior evaluation: 52,684 usec.

The lighting figures overlap and must not be summed as independent phases.

Lighting is the largest currently measured bounded phase, but the existing measurements still do not explain most end-to-end accepted-action time. The operation therefore did **not** reopen performance architecture or optimize on inference alone. A later performance change requires a concrete bounded attribution, not the residual itself.

No protected mob-force, fear, infected scheduling, Perception, combat-ordering or consequence-presentation architecture changed in this operation.

## Safari boundary

The production touch/mobile action path is CI-proven.

GitHub Actions runs on Linux and does not provide an actual Safari/WebKit browser session. The repository therefore does not claim Safari itself was executed or accepted by CI.

This leaves exactly one Phase 2 release-acceptance blocker:

**Run the deployed Pages build in real Safari and verify the already-proven decision loop on the actual browser.**

The Safari pass should verify:

1. touch/click activation of the production controls;
2. viewport/control fit and legibility;
3. accepted action locks input during resolution;
4. controls return only at the legitimate next decision pause;
5. crowded consequence moments remain readable and non-blocking;
6. no Safari-specific focus/background/input regression appears.

If Safari shows a concrete defect, repair that defect narrowly and verify it with a fresh prompt-local route. Do not reopen combat architecture merely because Safari acceptance is external.

If Safari passes, Phase 2 is fully accepted and the release roadmap advances to Phase 3: durable save/leave/continue.

## Durable documentation updated

- `ROADMAP.md` records technical Phase 2 crowded-fight closure, measured timing attribution and the single real-Safari acceptance blocker.
- `CHANGELOG_LATEST.md` records the initial no-engagement finding, bounded acceptance fixture, successful fight route and telemetry.
- `SYSTEM_DESIGNS/37_TACTICAL_COMBAT_PHYSICAL_IMPACT.md` records the production touch-route acceptance contract and performance evidence.

## Current release direction

Core loop remains:

**scavenge -> fight -> craft -> survive**

on the persistent map with day/night, weather, power, water and vehicles.

A base remains an existing fortified house/building with supplies, generator and well.

Human survivor society, raiders and human followers remain outside release scope. Pets remain future bounded scope.

Phase-2 defining technical work now complete includes:

1. commitment windows / points of no return;
2. simultaneous same-tick melee consequences;
3. terminal death after already-earned spatial consequences;
4. causal `S_t -> transition -> S_t+1` ordering;
5. deterministic same-tick movement/space arbitration;
6. shove as shared forced trajectory;
7. aggregate multi-body mob pressure;
8. canonical Calm/fear;
9. bounded eight-infected callback/perception path;
10. coherent overlapping consequence presentation;
11. real eight-infected crowded-fight touch/control acceptance and end-to-end attribution.

## NEXT OPERATION

Perform the **real Safari release-acceptance pass** on the deployed GitHub Pages build.

This is acceptance, not architecture work.

Do not reopen mob force, fear, infected scheduling, Perception, combat ordering, consequence presentation or general performance unless the Safari run exposes a concrete defect.

If Safari passes the six checks above, mark Phase 2 fully accepted and advance directly to **Phase 3 — durable save, leave and continue**.

If Safari exposes a defect, identify exactly one browser-specific failure, make the narrowest production repair, use one fresh prompt-local verifier/workflow for that repair, deploy, and re-run Safari acceptance.

## Protected behavior

Preserve:

- WHERE / WHAT / WHEN authority and one clock;
- `S_t -> transition -> S_t+1` causal ordering;
- commitment windows;
- simultaneous melee hit/damage/death behavior;
- deferred terminal death after earned current-tick consequences;
- deterministic movement/space contests;
- mob-force core;
- canonical fear;
- responsive walk/run/shove/snap-fire escape actions;
- event-driven Perception freshness;
- lighting acquisition revision correctness;
- cached geometric LOS;
- one bounded shared player + active-infected acquisition field;
- active cohort size 8;
- simple independent infected intentions;
- no horde brain/scheduler/group coordination;
- resident-backed infected identity;
- coherent same-timestamp consequence presentation;
- no presentation-owned gameplay truth or time advancement;
- touch-first semantic input routing;
- input locked until legitimate decision pause;
- hard application pause;
- player movement, Health/injury, inventory, condition/moodlets, skills/equipment;
- day/night, Weather, utilities and vehicles;
- persistence/terrain/streaming;
- STATS / INVENTORY / CRAFT / MENU ownership;
- no player-facing ZOMBIES / ZOMBIES NEARBY indicator;
- LOADING behavior unless explicitly replaced later.

Historical gameplay suites and the retired twelve-seed matrix are not current gates.
