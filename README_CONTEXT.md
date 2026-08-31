# Tick Survival Lab — Current Handoff

Last updated: **2026-08-31**

This file is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION** without rediscovering completed architecture.

## Current heads

- **Exact verified executable:** `b94bc16e90c7699c0e1a95bb1556bf4bb0bdcd18` — `Align legacy seam smoke with procedural settlements`
- **Runtime recovery commit:** `a026d72288ef10fc92263e2e8590dfba70baeb7f` — `Restore procedural utility boot across island seeds`
- **Documentation parent immediately before this handoff write:** `b94bc16e90c7699c0e1a95bb1556bf4bb0bdcd18`
- The commit containing this file is intentionally the **final repository write** of this operation. Commits after the executable are documentation-only.

## Completed operation — procedural boot / reported black-screen recovery

The reported black screen was not a lighting-renderer failure. `UtilityGameMain` generated and preflighted the full procedural island before its first visible frame; some valid seeds aborted during remote local-area utility topology, so the application never reached presentation.

Two generation defects caused the abort:

1. `TownBlockPlanner` still treated fewer than two semantic town blocks as fatal even though current settlement area/structure density targets are soft and actual parcels/buildings consume real road geometry directly.
2. Global roads can expose both directions of one physical straight segment. `LocalRoadPlanner` treated the reversed twin as a different intersecting road, which rejected every rural scattered branch anchor for affected sites.

The recovery is narrow and architectural:

- available semantic town blocks are now a morphology result, not a hard boot gate;
- reversed/identical straight road twins are recognized as the same physical road for branch-anchor clearance;
- `ProceduralIslandSeedMatrixSmoke.gd` now resolves each full island through `UtilityLocalPowerTopologyPlanner`, catching remote-site utility failures before playable boot;
- `IslandLegacySeamSmoke.gd` now validates that the playable crossroads owns its real procedural settlement center instead of requiring a retired fixed global-center coordinate.

No accepted renderer, physical-lighting, LOS, camera, input, power-topology, water-contract or utility-presentation implementation was changed for this recovery.

## Renderer and input baseline remains protected

- Full **80×96** physical-light presentation remains the accepted path.
- LOS remains stateless; the rejected camera-cropped lighting/LOS cache approach must not return.
- The fake default flashlight remains removed. Flashlight presentation requires a real equipped flashlight.
- Input dispatch remains responsive without queued-step buildup.
- Camera controls and performance architecture remain unchanged and protected by their existing smoke contracts.

## Power and water contract remains current

- Local substations are planned from actual deterministic generated building manifests with a target of roughly **10 generated buildings per substation**.
- Every local substation physically materializes as a small fenced transformer/utility-box compound.
- Regional source/ingress -> local substation service is intentionally logical/non-physical: no long-distance plant-to-substation wire is drawn.
- Distribution leaves each substation through one real shared roadside feeder tree built from generated local roads, with reusable poles/trunks and one short final service drop near each served building.
- One real persistent municipal treatment plant provides island-wide radiusless municipal water and intentionally does **not** require outside grid power.
- Because municipal service is island-wide and radiusless, no generated home can fall outside a municipal plant radius. Real private wells remain separately assigned to a deterministic minority of actual rural homes and materialize with persistent entity/asset identity and damageable condition.
- Wastewater/sewer/septic remains **retired / not active**.

Do not replace these structures, poles, spans, wells or service relationships with presentation-only markers. They are generated and materialized from procedural island truth.

## Exact executable verification

Executable `b94bc16e90c7699c0e1a95bb1556bf4bb0bdcd18` completed **50/50 exact-head workflows successfully**, with zero failures and zero pending checks.

Key successful runs:

- Interactive procedural boot diagnostics: run `33356369472`
- Global world planning: run `33356369897`
- Local-area generation / System 20: run `33356369814`
- System 33 power and water: run `33356369642`
- Physical lighting: run `33356369544`
- Performance architecture: run `33356369519`
- Streaming/materialization: run `33356369621`
- GitHub Pages build/deploy: run `33356369561`

Local Godot **4.7.1** verification also passed:

- project import/parse;
- the 12-seed procedural-island aggregate and end-to-end playable boot matrix;
- small-town and rural-scattered generation;
- complete island/global/local planning and the repaired legacy seam proof;
- System-33 power infrastructure, physical network and power/water integration;
- physical-lighting logic and full presentation;
- input responsiveness, camera control and performance architecture;
- canonical playable runtime boot with `CANONICAL_DEMO_BOOT_OK`.

## Browser acceptance status

The live Pages deployment is available at `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/` and the exact executable deployment completed successfully.

An automated live-page inspection was attempted, but the available cloud browser has WebGL2 disabled and Godot correctly stopped at its WebGL2 capability screen. That environment cannot provide a valid visual gameplay verdict. **Human acceptance on a WebGL2-capable browser/phone remains pending.**

## Do not regress

- Do not change the accepted renderer/lighting/LOS/input path to solve a pre-render generation failure.
- Do not reintroduce hard settlement-count gates where the current profile defines soft morphology/density targets.
- Do not treat reversed records of one physical road as unrelated intersecting roads.
- Do not draw independent transformer-to-house starbursts or regional source-to-substation transmission.
- Do not make the municipal water plant depend on external grid power.
- Do not add a municipal service radius or simulated long-distance pipe network.
- Do not reintroduce wastewater as a hidden prerequisite.
- Do not fake generated buildings, utility compounds, poles, wire spans or wells in UI/render-only code.
- Do not weaken the seed-matrix utility preflight or System-33 physical-topology assertions.

## NEXT OPERATION — WebGL2 browser/phone acceptance

Open the live Pages build in a WebGL2-capable desktop browser and on phone/Safari, then verify:

1. a fresh island reaches a visible first frame instead of remaining black;
2. movement begins immediately and repeated input does not build a delayed queue;
3. full-window lighting, stateless LOS and real equipped-flashlight behavior match the accepted baseline;
4. multiple fresh seeds boot successfully;
5. each fenced local substation serves roughly ten actual generated buildings;
6. shared roadside poles/wires fork only where the generated road/customer topology requires them;
7. short final service drops terminate near the actual served buildings;
8. no regional source/plant -> substation transmission is visible;
9. the real municipal plant and private wells are physically present and behaviorally correct;
10. Safari/phone remains first-class.

If that playtest passes, record Phase 3 human acceptance. If it exposes a defect, fix the owning implementation while preserving all exact-head contracts above.
