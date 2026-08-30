# Tick Survival Lab — Current Handoff

Last updated: **2026-08-30**

This file is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION** without rediscovering completed architecture.

## Current heads

- **Exact verified executable:** `b632fc709d4fcd387eccb41fdc0e0f736bd69643` — `Align watercourse smoke with global profile v7`
- **Documentation parent immediately before this handoff write:** `15d47c5a1d6f3778f937b99beec74c7ec6ceaafe` — `Record shared roadside feeder closeout`
- The commit containing this file is intentionally the **final repository write** of this operation. Commits after the executable are documentation-only.

## Completed operation — shared neighborhood electrical distribution

The local electrical network is now a real shared roadside distribution tree rather than independent substation-to-house rays.

### Power topology

- `UtilityLocalPowerTopologyPlanner` groups actual deterministic generated buildings with a target of **10 buildings per local substation**.
- Local substations are real persistent fenced compounds with a transformer and utility boxes.
- Regional source/ingress -> local substation remains logical/non-physical. No long-distance regional transmission wire is drawn or materialized.
- `NeighborhoodPowerInfrastructureMaterializer` builds a graph from actual generated `local_roads` centerlines.
- A reachable road cell nearest the substation becomes the shared feeder root.
- Deterministic root-to-customer-tap routes are calculated and unioned before physicalization.
- Overlapping route sections are deduplicated into one physical shared trunk.
- Real roadside utility poles are placed off the road at the root, customer taps, turns, junctions and deterministic spacing points.
- Each substation has one short `substation_lead` from transformer to the road-root pole.
- `shared_trunk` spans run pole-to-pole along the generated road network and fork only where topology requires it.
- Each served generated building gets one short final `service_drop` from its shared roadside tap to a customer pole near the building.
- Common route sections genuinely reuse the same poles and wire spans. There is no transformer-to-every-house starburst.

### Strict automated proof

`System33PowerInfrastructureSmoke.gd` now protects the requested topology and must not be weakened. It proves:

- zero direct substation -> customer rays;
- exactly one final `service_drop` per generated served building;
- each final drop begins at a shared roadside pole and ends at a customer pole;
- shared trunk spans record actual generated-road route cells;
- spans between route turns are cardinal;
- overlapping customer routes collapse to one physical trunk segment;
- at least one roadside pole is reused by multiple wire edges.

The physical condition/failure system remains attached to the real shared-trunk and service-drop spans. Daily line failure remains deterministic and day-boundary driven; repair preserves existing System-33 causality.

## Water contract remains current

- One island-wide municipal treatment facility serves municipal water.
- Municipal service is `island_wide_municipal`; there is no service radius and no simulated long-distance municipal pipe network.
- The municipal plant is real persistent infrastructure and intentionally does **not** require external grid power.
- A deterministic minority of actual generated rural residential buildings receive real private wells.
- Private wells have persistent identity/condition and depend on the owning building group's real electrical service.
- Wastewater/sewer/septic is **retired and not an active gameplay/planning dependency**. Do not reintroduce it to satisfy stale tests or documentation.

## Regression cleanup completed

Protected CI contained stale assumptions from older utility/global-profile contracts. Those tests were migrated narrowly without weakening the actual behavior they protect:

- `6d2de94648a5ddf468a38f66caf269288c4c796a` — streaming regression aligned with rural profile v7.
- `60f1053c0d4729fff0f5b003aec4ac9b989dd075` — retired local-water/wastewater assumptions removed from small-town smoke.
- `f7e9eb268aaa8cee1b8c9ad41a4276594a2193d6` — rural scattered smoke aligned with island-wide municipal water, zero retired wastewater constraints, and profile v7.
- `b632fc709d4fcd387eccb41fdc0e0f736bd69643` — rural watercourse smoke aligned with global profile v7 while preserving hydrology/bridge/materialization/traversal assertions.

## Key implementation lineage

- `c8028bd6a7c201c4531536035544dc556538f54a` — `Route neighborhood power through shared road trunks`
- `065cb436358c43acac108f970695fbcb01f4efca` — `Prove shared roadside neighborhood power trunks`
- `32b8b2b9c463d8d732b39bdd9fbf297e063c643b` — `Add deterministic road cell ordering helper`
- `6d2de94648a5ddf468a38f66caf269288c4c796a` — `Align streaming regression with rural profile v7`
- `60f1053c0d4729fff0f5b003aec4ac9b989dd075` — `Remove retired utility assumptions from small-town smoke`
- `f7e9eb268aaa8cee1b8c9ad41a4276594a2193d6` — `Align rural scattered smoke with current utility contract`
- `b632fc709d4fcd387eccb41fdc0e0f736bd69643` — `Align watercourse smoke with global profile v7`

## Exact executable verification

On executable `b632fc709d4fcd387eccb41fdc0e0f736bd69643`:

- **System 33 power/water:** SUCCESS — run `33326728859`, job `99298085597`.
- **System 20 / local-area generation:** SUCCESS — run `33326728733`, job `99298085110`.
- **Global world planning:** SUCCESS — run `33326728865`, job `99298085561`.
- **Performance architecture:** SUCCESS — run `33326728795`, job `99298085330`.

The earlier Pages build failure on the executable head was caused by stale handoff wording in the old context file, not game code. This handoff is intentionally rewritten cleanly rather than copying that stale text.

## Documentation updated

- `SYSTEM_DESIGNS/33_POWER_WATER_UTILITIES.md` now defines the shared roadside feeder tree, route deduplication, forks and short final service drops.
- `SYSTEM_DESIGNS/33B_POWER_PHYSICAL_NETWORK_CONDITION.md` now defines failure/repair on the physical shared-trunk and service-drop topology.
- `CHANGELOG_LATEST.md` records the shared-feeder implementation and protected-regression cleanup.

## Do not regress

- Do not draw one independent substation-to-house line per customer.
- Do not fake shared lines visually while retaining duplicate underlying spans.
- Do not draw regional source/plant -> local-substation transmission.
- Do not add local municipal-water service radii or long-distance pipe simulation.
- Do not make the municipal water plant depend on outside grid power.
- Do not reintroduce wastewater as a hidden planning/test dependency.
- Do not replace real generated buildings/infrastructure with demo markers or UI-only representations.
- Do not weaken the strict System-33 shared-topology assertions to make CI pass.

## NEXT OPERATION — human/browser Phase 3 utility playtest

Use the live Pages build and verify the actual visible/gameplay result, especially on phone/Safari as well as desktop:

1. each local substation serves roughly ten actual generated buildings;
2. distribution visibly leaves each substation as a shared roadside chain/tree, not separate rays;
3. common route sections visibly use one shared set of poles/wires;
4. forks appear only where road/customer topology needs them;
5. final service drops terminate close to the actual generated buildings they serve;
6. no visible regional source/plant -> substation transmission appears;
7. line damage/snap causes the correct outage and repair restores it;
8. municipal water plant and private wells remain physically present and behaviorally correct;
9. no black-screen, first-step hitch growth or input-backlog regression returns;
10. Safari/phone remains first-class.

If that human playtest passes, record Phase 3 human acceptance. If it exposes a defect, fix the owning implementation and preserve all current strict automated contracts.
