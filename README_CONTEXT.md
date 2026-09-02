# Tick Survival Lab — Current Handoff

Last updated: **2026-09-01**

This file is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION** without rediscovering completed architecture.

## Current heads

- **Exact verified System 34 gameplay executable:** `e07c559ad2f3eeafbf9b342c97ea2fd61f730e5a` — `Add System 34 survivor condition verification`
- **System 34 owning verification:** workflow `System 34 Survivor Condition contract`, run `33363266598`, job `99398683690` — **completed / success** on exact head `e07c559ad2f3eeafbf9b342c97ea2fd61f730e5a`.
- **Pages repair commit:** `49dcbe433c8bd3899592276aba534b0824e8b635` — `Repair Pages canonical composition validation`
- **Pages repair verification:** workflow `Build and deploy Tick Survival Lab`, run `33580686480`; build job `100094126996` and deploy job `100094432962` — **completed / success** on exact repair head.
- **Prior exact verified roadside-power executable:** `9f6e0b8e9010d73181143481a84532fbfffb93e1` — `Verify roadside pole routing contract`
- **System 00F CI consolidation:** `32ef0c7647356b773e829081795b60563fc50d2b` — `Consolidate procedural boot CI`
- The commit containing this file is intentionally the **final repository write** of this operation. This handoff write is documentation-only and does not change runtime behavior.

## Completed operation — Pages deployment repair

The Pages failure introduced alongside the System 34 composition change is repaired and the live Web export/deployment contract is green again.

Root cause:

- System 34 correctly made `System34GameMain.gd` the canonical root composition in `game/main.tscn`.
- `System34GameMain.gd` extends `UtilityGameMain`, which in turn extends `CraftingGameMain`; runtime composition remained valid.
- `.github/workflows/pages.yml` still contained a stale validation assertion requiring the old direct `UtilityGameMain.gd` reference in `game/main.tscn`.
- The failed Pages run therefore stopped in `Validate canonical project surface`; this was a CI validator defect rather than a gameplay, Godot parse, Web export or Pages-hosting defect.

Repair commit `49dcbe433c8bd3899592276aba534b0824e8b635` updates only `.github/workflows/pages.yml`:

- the canonical main-scene assertion now requires `System34GameMain.gd`;
- the workflow explicitly validates `System34GameMain.gd -> UtilityGameMain -> CraftingGameMain` inheritance;
- the System 34 design document and script are included in the canonical project-surface checks;
- existing Godot import/parse, canonical demo smoke, startup smoke, Web export, Pages configuration, artifact upload and deployment steps remain intact.

Exact owning verification on the repair head:

- Workflow: `Build and deploy Tick Survival Lab`
- Run: `33580686480`
- Context: `verify/pages-deploy` — **success**
- Build job: `100094126996` — **completed / success**
- Deploy job: `100094432962` — **completed / success**

Every build-stage step passed:

1. Checkout;
2. Validate canonical project surface;
3. Install Godot 4.7.1 and export templates;
4. Import and parse project;
5. Canonical demo integration smoke;
6. Startup smoke;
7. Export Web build;
8. Configure / enable GitHub Pages;
9. Upload Pages artifact.

The deploy job then passed `Deploy to GitHub Pages` successfully.

No runtime/gameplay source changed in this repair. The exact gameplay executable remains `e07c559ad2f3eeafbf9b342c97ea2fd61f730e5a`.

## Completed operation — System 34 Survivor Condition verification

System 34 implementation and its exact owning regression suite are complete. No repair was required after verification.

Exact owning verification for gameplay head `e07c559ad2f3eeafbf9b342c97ea2fd61f730e5a`:

- Workflow: `System 34 Survivor Condition contract`
- Workflow path: `.github/workflows/system34-survivor-condition.yml`
- Run: `33363266598`
- Job: `99398683690` — `verify/system34-survivor-condition`
- Result: **completed / success**
- Job started `2026-08-31T06:13:04Z` and completed `2026-08-31T06:13:58Z`.

Every intended owning step passed on that exact head:

1. System 34 ownership-boundary validation;
2. Godot 4.7.1 import and parse;
3. focused `System34SurvivorConditionSmoke.gd` regression with `SYSTEM34_SURVIVOR_CONDITION_SMOKE_OK` required;
4. protected actor-health regression;
5. protected actor-needs regression;
6. protected actor-carry regression;
7. protected item-freshness regression;
8. protected player-input-responsiveness regression;
9. protected System 33 power/water regression;
10. canonical startup requiring `CANONICAL_DEMO_BOOT_OK`;
11. exact-head status publication.

The combined exact-head status reports `verify/system34-survivor-condition` as **success**. The Pages failure that was deliberately kept outside that bounded System 34 verification has now been repaired separately and verified green as recorded above.

## Completed operation — System 00F CI consolidation verified

The procedural-island CI consolidation is complete and required **no repair**.

Exact owning verification for consolidation commit `32ef0c7647356b773e829081795b60563fc50d2b`:

- Workflow: `Streaming and Materialization Orchestration contract`
- Workflow path: `.github/workflows/streaming-materialization.yml`
- Run: `33360162311`
- Job: `99389828052` — `streaming-materialization`
- Result: **completed / success**
- Run began `2026-08-31T05:19:56Z` and completed `2026-08-31T05:26:30Z`.

Every intended consolidated step passed on that exact head:

1. System 00F boundary validation;
2. Godot import/parse;
3. one **12-seed procedural island planner/preflight matrix**;
4. one **12-seed canonical playable boot matrix**;
5. settlement materialization regression;
6. countryside source/materialization contract.

The consolidation removed redundant verification without weakening the island contract:

- the standalone duplicate procedural boot-diagnostics workflow is gone;
- the duplicate System-00F `PerformanceRazorSmoke` invocation is gone because the dedicated performance workflow owns that check;
- System 00F still owns one full planner/preflight 12-seed matrix and one full real-game boot 12-seed matrix;
- settlement and countryside materialization smokes remain;
- System 00F push triggering is path-aware, so unrelated/docs-only pushes do not launch the procedural island gauntlet, while edits to the owning workflow itself still trigger it.

## Completed gameplay operation — roadside power pole crossing artifact

The browser screenshots exposed a real System-33 materialization defect, not a renderer defect. Roadside pole cells were chosen independently as the nearest legal off-road cell. An obstacle could therefore force one support to the opposite side of the road and the next support could independently snap straight back, producing an unnecessary diagonal zig-zag. Generated parcel driveway/parking access cells were also absent from the utility placement exclusions, so a crossing support could land directly on the narrow gray access strip.

The repair is architectural and uses generated world truth:

- `UtilityLocalPowerTopologyPlanner` carries actual generated parcel `driveway_cells` and `parking_cells` into deterministic `pole_exclusion_cells`.
- Physical utility supports reject those generated access cells; they are not identified by sprite color or renderer inference.
- Shared-feeder pole placement is resolved **root-outward** so straight-route child supports inherit the parent span's physical side of the road.
- If the current side has no legal placement and a crossing is genuinely required, the feeder changes side and holds that new side for the next **two sequential pole placements** before an elective cross-back is allowed.
- Turns and actual feeder junctions may establish a new routing direction; the side-hold rule does not invent additional forks.
- Stable pole identities remain tied to the existing deterministic route-cell ordering, so the visual-routing correction does not churn physical asset IDs.
- `System33RoadsidePoleRoutingSmoke.gd` and permanent `verify/system33-roadside-pole-routing` protect generated access exclusions, same-side displacement, forced crossings, the two-pole hold, and real shared-trunk materialization.

No accepted renderer, physical-lighting, LOS, camera, input, municipal-water, well, substation-count, regional-ingress, shared-trunk-deduplication or one-service-drop-per-building contract was replaced.

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
- Roadside supports must avoid real generated driveway/parking/access surfaces. A forced road crossing must remain on the new side for the next two sequential support placements before an elective cross-back.
- One real persistent municipal treatment plant provides island-wide radiusless municipal water and intentionally does **not** require outside grid power.
- Because municipal service is island-wide and radiusless, no generated home can fall outside a municipal plant radius. Real private wells remain separately assigned to a deterministic minority of actual rural homes and materialize with persistent entity/asset identity and damageable condition.
- Wastewater/sewer/septic remains **retired / not active**.

Do not replace these structures, poles, spans, wells or service relationships with presentation-only markers. They are generated and materialized from procedural island truth.

## Exact prior roadside gameplay executable verification

Executable `9f6e0b8e9010d73181143481a84532fbfffb93e1` completed **43/43 push-triggered exact-head workflows successfully**, with zero failures and zero pending runs.

Key successful runs:

- Roadside pole routing: run `33358588818`
- System 33 power and water: run `33358588830`
- Streaming/materialization: run `33358588831`
- Global world planning: run `33358588703`
- System 20 local-area generation: run `33358588870`
- Physical lighting: run `33358588841`
- Performance architecture: run `33358588696`
- GitHub Pages build/deploy: run `33358588720`

## Browser acceptance status

The repaired Pages deployment is available at `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`.

Automated verification proves System 34's owning condition/regression contract, the repaired Web build/deploy pipeline, and the previously protected topology/materialization behavior, but does **not** claim human visual/gameplay acceptance. Browser/phone/Safari acceptance remains a separate manual step.

## Do not regress

- Do not let Pages canonical-composition validation hard-code an obsolete direct root script when the authoritative composition layer changes; validate the current root and its intended inheritance chain.
- Do not solve power-line placement artifacts in the renderer; support placement belongs to generated/materialized utility truth.
- Do not place roadside utility supports on generated driveway/parking/access cells.
- Do not return to independent nearest-cell pole placement that can immediately zig-zag across the road and back.
- After a forced straight-route road crossing, preserve the two-subsequent-support side hold before elective cross-back.
- Do not draw independent transformer-to-house starbursts or regional source-to-substation transmission.
- Do not change the accepted renderer/lighting/LOS/input path for utility topology defects.
- Do not make the municipal water plant depend on external grid power.
- Do not add a municipal service radius or simulated long-distance pipe network.
- Do not reintroduce wastewater as a hidden prerequisite.
- Do not fake generated buildings, utility compounds, poles, wire spans or wells in UI/render-only code.
- Do not weaken the consolidated System-00F planner 12-seed matrix, canonical playable 12-seed boot matrix, System-33 physical-topology assertions, roadside-pole regression, or System-34 condition regression.
- Do not duplicate System-34 condition truth in UI/presentation code; keep the owning condition services/queries authoritative.

## NEXT OPERATION — human browser/gameplay acceptance

Open the live build in a WebGL2-capable desktop browser and on phone/Safari, then verify the current gameplay state manually. In particular:

1. exercise System 34 survivor condition behavior and confirm health/stamina/moodlet presentation and controls behave correctly during actual play;
2. confirm protected health, needs, carry, freshness and input behavior still feels correct rather than only passing headless regression;
3. inspect roadside feeder routing across multiple fresh seeds;
4. confirm no pole/support lands on a gray generated driveway, parking connection or pedestrian/access strip;
5. confirm a forced straight feeder crossing stays on the new side for the next two support placements before an elective cross-back;
6. confirm shared trunks/forks, short final service drops, substations, municipal plant and private wells remain physically correct;
7. confirm fresh islands reach a visible first frame and multiple seeds boot successfully;
8. confirm movement remains immediate without delayed input buildup and full-window lighting/stateless LOS/real-equipped-flashlight behavior match the accepted baseline;
9. keep Safari/phone first-class.

If that playtest passes, record human acceptance. If it exposes a defect, fix the owning implementation while preserving all exact-head contracts above.
