# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. For the next distinct repository operation, follow the normal SOP from this recorded final head.

## Current checkpoint — ISLAND ROAD HIERARCHY REALISM CLOSED — 2026-09-09

The core feature roadmap remains closed and the game remains a beta candidate. This bounded operation changed the **meaning/classification of the existing island road network** so the map reads more like a believable hierarchy while preserving the generated settlement layout and route graph.

The user-directed target was:

- sparse 4-lane major trunks/freeways;
- 2-lane paved routes through town/city centers;
- gravel secondary/side roads;
- dirt predominantly for rural/farm/home access;
- preserve the existing settlement layout;
- never regress to the historical “everything becomes gravel” failure.

Starting immutable repository tree recorded for this operation:

`07429fcdf6941e394cfa9423a6185886daa2e311`

Owning production hierarchy commit:

`fb956834f99ce7ba6d177e40e0bc0051d3a35b25`

Owning fully gated functional/regression head:

`d5c25ec8d9ff0b3583f8c7a33424f179270e220d`

Documentation head immediately before this final context write:

`7f1aa5fc1a592fc8be94fa4744549a9fb92dd464`

## Root cause

`IslandMajorRoadNetworkPlanner.gd` already generated four road identities, but geography did not give them meaningful roles:

- all four island boundary gateway spokes were `four_lane` from a settlement center all the way to the coast;
- non-primary rural routes selected gravel versus dirt from a route hash rather than from what the road served.

The map renderer was already correctly displaying road metadata, and global-to-local projection already preserved `road_type`, `lane_count`, `surface_family` and centerline metadata. Therefore this was fixed in the production world planner instead of adding renderer/map special cases.

## Implemented geographic hierarchy

`game/scripts/generation/world/IslandMajorRoadNetworkPlanner.gd` now generates the existing route graph first, then applies deterministic geographic road hierarchy.

### Major freeway axis

- The broad axis joining the two generated `smalltown` centers determines the island’s major highway orientation.
- Exactly two opposite gateway directions on that axis become the genuine freeway pair.
- Each major gateway leaves its source settlement as an ordinary paved **2-lane approach**.
- Outside the source settlement influence/approach distance, that same route widens once into a **4-lane paved trunk**.
- If the widening point lands inside an existing cardinal segment, that segment is split collinearly into `.approach` and `.freeway` pieces. The path itself does not move.
- The two perpendicular island gateways remain ordinary **2-lane paved roads**, preventing the old four-freeway-spokes look.

### Settlement and rural roads

- Primary routes serving a `smalltown` or `rural_crossroads` are paved **2-lane** roads.
- Secondary settlement-tree links between rural hamlets are **gravel**. These form the dependable secondary rural network.
- Secondary alternate/loop links between rural hamlets are **dirt**. These now read as local/farm/home-style rural access instead of being chosen by hash.

Road surface contracts remain explicit:

- `four_lane` -> 4 lanes, `paved_centerline`, painted centerline;
- `two_lane` -> 2 lanes, `paved_centerline`, painted centerline;
- `gravel` -> 1 lane, `rural_gravel`, no painted centerline;
- `dirt` -> 1 lane, `rural_dirt`, no painted centerline.

## Preserved boundaries

This operation did **not**:

- move or regenerate settlement centers;
- change settlement kinds, influence radii or area-site identities;
- replace the settlement connection tree;
- change alternate-route destinations;
- change gateway destinations;
- replace terrain-aware routing;
- change the map renderer;
- change dirt-road traversal policy;
- change vehicle movement;
- change utility/power-pole generation;
- change NPC/zombie timing, AI or performance;
- change the previously closed same-WHEN movement simultaneity behavior.

Utility pole generation is still somewhat imperfect but remains explicitly beta-acceptable unless the user promotes it again.

## Verification

Fresh prompt-local verifier pair for this operation:

- `game/scripts/ci/PromptRoadHierarchyRealismSmoke.gd`
- `.github/workflows/prompt-road-hierarchy-realism.yml`

Permanent regression updated to own the new semantics:

- `game/scripts/ci/IslandRoadHierarchySmoke.gd`

The road gates verify:

- all four island gateway routes remain;
- exactly two opposite gateways contain 4-lane freeway trunks;
- major freeway routes begin at their settlement as 2-lane and widen only once;
- the perpendicular gateway pair remains entirely 2-lane;
- town/crossroads routes remain paved 2-lane;
- gravel secondary rural routes exist;
- dirt rural/local routes exist and terminate at rural hamlets;
- all four road types keep correct lane/surface/paint metadata;
- every generated settlement remains attached to the road graph;
- every route remains geometrically contiguous after freeway transition splitting;
- the road network cannot collapse to all gravel.

Focused workflow results:

- run `34434454261` on `e2254f18b73e6351a7a1e193e1a982f60c4294bf` — **SUCCESS** after project class-cache import; prompt acceptance passed.
- run `34434543382` on `d5c25ec8d9ff0b3583f8c7a33424f179270e220d` — **SUCCESS**; both prompt acceptance and permanent road regression passed.

An earlier standalone smoke launch failed before assertions because bare Godot `--script` execution had not built the global class cache. The normal Web export was already green, proving production parsed. The prompt workflow was corrected to import the project once before running standalone smokes; no production road behavior was weakened to satisfy the harness.

Pages/Web proof during this operation:

- run `34434334637` on `75995be1f2ddaa8101285b03b9b899bb7c090c8f` — Web build **SUCCESS**, artifact upload **SUCCESS**, deploy **SUCCESS** with the production hierarchy code present.
- Later Pages runs were superseded/cancelled by subsequent direct-to-main verifier/documentation writes under the repository’s Pages concurrency policy. After this final context commit, verify the newest exact final-head Pages run read-only; no further repository writes are permitted in this operation.

## Documentation

Operation-specific closure ledger:

- `CHANGELOG_ROAD_HIERARCHY_REALISM.md`

Documentation commit immediately before this final context write:

`7f1aa5fc1a592fc8be94fa4744549a9fb92dd464`

## Established systems to preserve

Unless concrete evidence requires a bounded repair, preserve:

- the single authoritative WHEN clock;
- same-WHEN deterministic movement batching and decision-pause semantics;
- current settlement-first procedural island, building-derived population and streaming architecture;
- the geographic road hierarchy described above;
- dirt-road traversability and painted/unpainted road material contracts;
- observer-scoped infected/survivor perception and existing survivor/infected population ownership;
- day/night, generated weather, physical lighting and night-only streetlights;
- power/water infrastructure and current roadside pole behavior;
- inventory/equipment/sustainment/crafting/skills/doors/windows/utilities/vehicles/combat systems already closed;
- dedicated vehicle rendering without the retired purple diagnostic artifact;
- no generated rivers/wastewater/sewer/septic resurrection;
- no routine broad seed matrices for ordinary bounded prompt closure.

## Known beta observations still available for later bounded polish

Not part of this road operation:

- zombie/infected presence can cause significant slowdown; the `ZOMBIES` overlay is intentional diagnostic context, not itself the performance bug;
- some delegated/world interactions can still show `Unknown` as a top-HUD action label;
- foraged inventory labels can expose internal deterministic generated IDs;
- mounted mobile controls deserve a real touch acceptance pass;
- utility pole generation remains imperfect but currently beta-acceptable.

## NEXT OPERATION — wait for the next explicit bounded target

The road-hierarchy realism pass is closed. Do not broaden it automatically into new road geometry, interchanges, traffic simulation, pole cleanup or zombie performance work.

For the next **code** operation, retire this prompt-owned verifier pair first:

- `game/scripts/ci/PromptRoadHierarchyRealismSmoke.gd`
- `.github/workflows/prompt-road-hierarchy-realism.yml`

Keep the permanent `game/scripts/ci/IslandRoadHierarchySmoke.gd` regression.

Then create a fresh prompt-local verifier for only the newly requested behavior and follow the normal direct-to-main closure SOP.

This `README_CONTEXT.md` commit is the **FINAL repository write for the island road hierarchy realism operation**. After it lands, perform read-only exact-head and CI/Pages verification only.