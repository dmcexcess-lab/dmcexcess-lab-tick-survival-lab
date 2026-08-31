# Tick Survival Lab — Current Handoff

Last updated: **2026-08-31**

This file is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION** without rediscovering completed architecture.

## Current heads

- **Exact verified executable:** `9f6e0b8e9010d73181143481a84532fbfffb93e1` — `Verify roadside pole routing contract`
- **Roadside pole implementation commits:** `37abaa803516094a2e92922a15557a844205dc8e` — `Carry generated access surfaces into utility topology`; `e4c1ee334d28473a9a9e1d8e5c7b1d7b5eb3ff00` — `Keep roadside power poles on stable legal sides`
- **Documentation parent immediately before this handoff write:** `1adad0f79c0ce90bba4790745ad78d924ac8659f` — `Record roadside pole routing correction [skip ci]`
- The commit containing this file is intentionally the **final repository write** of this operation. Commits after the executable are documentation-only.

## Completed operation — roadside power pole crossing artifact

The browser screenshots exposed a real System-33 materialization defect, not a renderer defect. Roadside pole cells were chosen independently as the nearest legal off-road cell. An obstacle could therefore force one support to the opposite side of the road and the next support could independently snap straight back, producing an unnecessary diagonal zig-zag. Generated parcel driveway/parking access cells were also absent from the utility placement exclusions, so a crossing support could land directly on the narrow gray access strip.

The repair is architectural and uses generated world truth:

- `UtilityLocalPowerTopologyPlanner` now carries actual generated parcel `driveway_cells` and `parking_cells` into deterministic `pole_exclusion_cells`.
- Physical utility supports reject those generated access cells; they are not identified by sprite color or renderer inference.
- Shared-feeder pole placement is resolved **root-outward** so straight-route child supports inherit the parent span's physical side of the road.
- If the current side has no legal placement and a crossing is genuinely required, the feeder changes side and holds that new side for the next **two sequential pole placements** before an elective cross-back is allowed.
- Turns and actual feeder junctions may establish a new routing direction; the side-hold rule does not invent additional forks.
- Stable pole identities remain tied to the existing deterministic route-cell ordering, so the visual-routing correction does not churn physical asset IDs.
- `System33RoadsidePoleRoutingSmoke.gd` and permanent `verify/system33-roadside-pole-routing` now protect generated access exclusions, same-side displacement, forced crossings, the two-pole hold, and real shared-trunk materialization.

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

## Exact executable verification

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

The dedicated roadside regression proves:

- real generated driveway/parking access cells are present in utility pole exclusions;
- real materialized local power poles do not occupy those cells;
- an obstructed preferred support can move while remaining on the same road side;
- a fully blocked side can force a real crossing;
- the next two straight-route support placements remain on the new side;
- the real shared trunk obeys the same post-crossing hold behavior.

The protected exact-head suite also retained procedural island boot coverage, System-33 physical infrastructure/service truth, physical lighting, performance architecture, input responsiveness, streaming/materialization and Pages deployment.

## Browser acceptance status

The exact executable Pages deployment is available at `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`.

Automated verification proves topology/materialization behavior but does **not** claim visual acceptance of the reported screenshot artifact. **Human acceptance on a WebGL2-capable desktop browser and phone/Safari remains pending.**

## Do not regress

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
- Do not weaken the procedural seed matrix, System-33 physical-topology assertions or roadside-pole regression.

## NEXT OPERATION — WebGL2 browser/phone acceptance

Open the live Pages build in a WebGL2-capable desktop browser and on phone/Safari, then verify:

1. reproduce/inspect roadside feeder routing across multiple fresh seeds;
2. no pole/support lands on a gray generated driveway, parking connection or pedestrian/access strip;
3. when a straight feeder must cross the road, it stays on the new side for the next **two support placements** before an elective cross-back;
4. the immediate across-and-back zig-zag visible in the reported screenshots is gone;
5. shared roadside poles/wires still reuse common trunks and fork only where generated road/customer topology requires them;
6. short final service drops still terminate near the actual served buildings;
7. each fenced local substation still serves roughly ten actual generated buildings and no regional source/plant -> substation transmission is visible;
8. fresh islands reach a visible first frame and multiple seeds boot successfully;
9. movement remains immediate without delayed input buildup, and full-window lighting/stateless LOS/real-equipped-flashlight behavior match the accepted baseline;
10. the real municipal plant and private wells remain physically present and behaviorally correct;
11. Safari/phone remains first-class.

If that playtest passes, record Phase 3 human acceptance. If it exposes a defect, fix the owning implementation while preserving all exact-head contracts above.