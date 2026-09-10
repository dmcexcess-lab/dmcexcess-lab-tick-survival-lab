# Road Hierarchy Realism Pass — 2026-09-09

## Goal

Make the existing procedural island road network read as a geographic hierarchy without moving settlements or replacing the route graph:

- sparse 4-lane major trunks/freeways;
- 2-lane paved routes through towns and crossroads;
- gravel secondary rural connectors;
- dirt predominantly for rural/local/farm/home access;
- preserve traversability and prevent the historical all-gravel regression.

## Production change

`game/scripts/generation/world/IslandMajorRoadNetworkPlanner.gd` now applies road hierarchy after the existing deterministic route graph is generated.

- The axis joining the two generated small towns determines the major highway orientation.
- Exactly two opposite island gateway directions form the freeway axis.
- A freeway gateway leaves its source settlement as a normal paved 2-lane approach, then widens once outside the settlement influence area into a 4-lane trunk.
- The two perpendicular island gateways remain paved 2-lane roads rather than becoming additional freeways.
- Primary settlement routes touching a small town or rural crossroads remain paved 2-lane roads.
- Secondary settlement-tree rural links are gravel.
- Secondary alternate/loop rural links are dirt, giving rural/local access a deterministic geographic meaning instead of selecting gravel versus dirt by route hash.
- When a freeway transition falls inside an existing cardinal road segment, the segment is split collinearly at the transition. Endpoints and path geometry remain unchanged.

## Preserved contracts

- Settlement centers, kinds, influence radii and area-site identities are unchanged.
- The settlement connection tree, alternate-route destinations, gateway destinations and terrain-aware routing are unchanged.
- Global-to-local road projection already preserves per-segment `road_type`, `lane_count`, `surface_family` and centerline metadata; no map-renderer workaround was added.
- Existing dirt-road traversal support remains authoritative.
- Utility/pole generation was intentionally not changed by this pass.

## Verification

Fresh prompt-local acceptance:

- `game/scripts/ci/PromptRoadHierarchyRealismSmoke.gd`
- `.github/workflows/prompt-road-hierarchy-realism.yml`

Permanent regression:

- `game/scripts/ci/IslandRoadHierarchySmoke.gd`

The gates verify:

- four island gateway routes remain;
- exactly two opposite gateways contain 4-lane freeway trunks;
- freeway routes begin as 2-lane settlement approaches and widen only once;
- the perpendicular gateway pair remains 2-lane;
- town/crossroads routes remain paved 2-lane;
- gravel secondary rural routes exist;
- dirt rural/local routes exist and serve rural hamlets;
- all four road types have valid lane/surface/paint metadata;
- every generated settlement remains attached to the road graph;
- route geometry stays contiguous after freeway transition splitting;
- the network cannot collapse to all gravel.

Prompt acceptance and permanent regression both passed on `d5c25ec8d9ff0b3583f8c7a33424f179270e220d` after importing the Godot project class cache. The normal Godot Web export/Pages pipeline had already passed the production hierarchy change before documentation closure.
