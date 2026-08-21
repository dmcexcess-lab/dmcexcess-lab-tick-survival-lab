# Tick Survival Lab — System 00D Slice 004 Regional Electrical Infrastructure

Status: **APPROVED**

Date: 2026-08-21

## 1. Goal

Add deterministic regional electrical-infrastructure planning facts to System 00D after geography, hydrology, settlements, roads and bridge intents exist, while preserving the accepted local Candidate 006 and keeping tactical electrical behavior downstream.

Canonical Slice 004 order:

`global request -> geography -> hydrology -> settlements/sites -> hydrology-aware major roads -> bridge intents -> regional electrical infrastructure -> planning regions -> validation -> global plan`

The regional power network is a logical planning fact in global tactical coordinates. It does not energize buildings, place tactical poles, render wires or mutate WHAT.

## 2. Approved scope

Approved by the user on 2026-08-21:

1. Add one regional electrical-grid ingress.
2. Add one small-town-associated regional substation/distribution hub.
3. Add one settlement service node for each of the five current settlements.
4. Add one connected regional feeder network reaching every settlement.
5. Route the feeder network by reusing the existing major-road graph rather than independently inventing cross-country utility paths.
6. Keep ridge avoidance inherited and independently verified.
7. Expose read-only power facts through `System20AreaRequestProjector.power_constraints_for_bounds()` without changing `AreaGenerationRequest`.
8. Keep Candidate 006, System 19, System 20 local generation/materialization, WHAT, WHEN, renderer/art, camera/player and tactical electrical behavior unchanged.
9. Bump `temperate.rural.region` from v3 to v4 because same-seed global output gains canonical infrastructure facts.

## 3. Non-goals

Slice 004 does not implement:

- energized/de-energized runtime state;
- outages or grid failure simulation;
- transformers, breaker panels or house service drops;
- tactical utility-pole placement;
- tactical wire rendering;
- local building wiring;
- generators, batteries or solar;
- electrocution or electrical hazards;
- electrical repair gameplay;
- water/sewer infrastructure;
- WHAT materialization;
- streaming/save ownership;
- population/outbreak behavior.

The old frozen runtime contained roadside power-line presentation. That history is a future recovery source, not permission to wire presentation into this planning slice.

## 4. Owners

Pure System 00D owners under `game/scripts/generation/world/`:

- `GlobalPowerInfrastructurePlanner.gd` — creates regional power nodes and road-following feeder segments;
- `GlobalPowerInfrastructureQuery.gd` — read-only power-network queries;
- `GlobalPowerInfrastructureValidator.gd` — independently verifies power-network correctness;
- `GeneratedGlobalWorldPlan.gd` — stores power planning facts and includes them in deterministic signatures;
- `GlobalWorldPlanner.gd` — orchestrates power planning after roads/bridges and composes base + power validation;
- `GlobalWorldProfileCatalog.gd` — owns Slice 004 profile version/route costs.

Separate downstream adapter:

- `game/scripts/generation/integration/System20AreaRequestProjector.gd` — read-only local-window projection seam only.

## 5. Public global-plan contract

`GeneratedGlobalWorldPlan` gains:

- `power_nodes: Array[Dictionary]`;
- `power_segments: Array[Dictionary]`.

### Power node record

Each node stores:

- unique stable `id`;
- `network_id`;
- semantic `kind`:
  - `regional_ingress`;
  - `substation`;
  - `settlement_service`;
- global tactical `cell`;
- optional `settlement_id` association.

Exactly one ingress and one substation exist in the current profile. Exactly one service node exists for every current settlement.

### Power segment record

Each feeder segment stores:

- unique stable `id`;
- `network_id`;
- semantic `power_class` (`regional_feeder` in Slice 004);
- cardinal `start` / `end` global tactical cells;
- stable `ordinal`;
- `source_road_id` and `source_route_id` showing which existing major-road geometry the feeder follows.

Power records store no art, atlas index, runtime voltage/state, pole spacing, wire sag or local service-drop geometry.

## 6. Routing model

The major-road network is already globally connected, geography-aware, hydrology-aware and ridge-free. Slice 004 therefore treats it as the regional utility corridor graph instead of running a second independent terrain router.

1. Collect road endpoints, road intersections, settlement centers and candidate boundary gateways as graph vertices.
2. Split existing cardinal major-road segments into atomic road-aligned graph edges between those vertices.
3. Choose exactly one deterministic boundary ingress from legal major-road gateway points using a named world-seed domain.
4. Use the small-town settlement center as the regional substation location.
5. Create one service node at each settlement center.
6. Find deterministic minimum-cost paths along the road graph from the ingress to the substation and every settlement service node.
7. Union those required paths into one feeder network.
8. Merge only exact duplicate atomic edges; no off-road shortcut is allowed.
9. Primary-road edges are slightly preferred over secondary-road edges where multiple legal road-graph paths exist, but both remain legal.
10. Power segments inherit road geometry only; later local materialization may place roadside poles offset from the carriageway rather than physically on the road centerline.

This is deliberately a planning model, not an electrical load-flow simulation.

## 7. Geography / hydrology relationship

Because every Slice 004 feeder segment must be contained by a real global major-road segment:

- ridge crossings remain forbidden;
- road geography decisions remain authoritative;
- power does not invent a second terrain-routing truth;
- river crossings are legal wherever the chosen road corridor crosses the river.

A future local infrastructure/materialization system may decide whether a crossing uses ordinary overhead spans, specialized structures or another physical treatment. Slice 004 records only the feeder path.

## 8. Determinism / variation

- Same world request/profile version/seed must produce byte-stable power node + segment signatures.
- Ingress choice uses a named deterministic seed domain, never call-order RNG.
- Different legal seeds may choose a different boundary ingress and will also inherit legal variation from geography/roads.
- Stable semantic IDs are derived from role/order, not Godot Node identity.

## 9. Independent validation

`GlobalPowerInfrastructureValidator` independently verifies:

- exactly one regional ingress;
- exactly one substation;
- one service node for every settlement and no unknown settlement association;
- substation belongs to the small-town settlement;
- all node cells are inside global bounds and lie on the major-road network;
- ingress is on the world boundary;
- no other feeder endpoint reaches the world boundary unless it is the ingress;
- every feeder segment is non-zero, cardinal and inside bounds;
- every feeder segment references a real source road/route and lies completely on that road geometry;
- no feeder segment crosses ridge geography;
- no duplicate undirected feeder edge exists;
- the feeder graph is connected from the ingress;
- every substation/service node is reachable from the ingress;
- IDs are unique across the power collection;
- the current canonical fixture contains all expected node roles.

`GlobalWorldPlanner` treats failure of either the existing global-world validator or the focused power validator as generation failure.

## 10. System 20 projection seam

`System20AreaRequestProjector` gains:

`power_constraints_for_bounds(plan, bounds)`

It returns read-only clipped power facts for a valid global planning window:

- `segments` — feeder segments clipped to the requested bounds while retaining semantic/source IDs;
- `nodes` — power nodes whose cells lie in the requested bounds.

`project_site()` remains unchanged. No power facts are inserted into `AreaGenerationRequest` in Slice 004.

Candidate 006 may therefore expose its global service node/feed corridor through the read-only query while its currently rendered/materialized local area remains exactly unchanged.

## 11. Performance

Planning runs only during deterministic world-plan creation on the small existing regional road graph. Graph construction and shortest-path work are bounded by the current small set of road segments/vertices and add no per-frame work.

Projection is a bounded read-only scan over the small power collection.

## 12. Failure behavior

Generation fails honestly on:

- missing required settlement roles;
- no legal road gateway ingress;
- settlement/service node not lying on the road network;
- disconnected road graph preventing power service;
- off-road power geometry;
- ridge-crossing power geometry;
- duplicate/orphan power records;
- invalid boundary egress;
- power validation failure.

No local deletion or presentation trick may hide an invalid network.

## 13. Acceptance criteria

Dedicated exact-head `verify/system00d-global-world` must prove:

1. profile v4 is recorded;
2. same-seed replay includes identical power nodes/segments;
3. alternate seed produces a legal power network and meaningful legal variation;
4. one ingress exists and is on a real road boundary gateway;
5. one small-town substation exists;
6. all five settlements have service nodes;
7. every power node is reachable from ingress;
8. every power segment follows a real major-road segment;
9. no power segment crosses ridge geography;
10. no unintended additional boundary feeder endpoint exists;
11. Candidate 006 `project_site()` request and generated System 20 semantic output remain unchanged;
12. `power_constraints_for_bounds()` exposes Candidate 006 global power facts read-only;
13. hydrology/bridge regressions remain valid;
14. unsupported `smalltown.center` / `rural.scattered` local profiles still fail honestly;
15. pure System 00D retains no dependency on System 19/20 owners, WHAT mutation, renderer/art, camera/player or streaming.

## 14. Future extension seams

Later approved systems may consume these planning facts for:

- local utility-pole placement and recovered wire presentation;
- transformer/service-drop planning;
- building electrical service;
- runtime grid energized state and cascading outages;
- generator/solar/battery islanding;
- repair/maintenance gameplay;
- outage-driven lighting/refrigeration/security consequences;
- causal outbreak infrastructure failure;
- streaming/coarse simulation.

Those systems consume the stable network rather than redefining regional topology.

## 15. North-star fit

The North Star explicitly requires utilities/infrastructure to be globally coherent before local materialization and streaming partitions. Slice 004 adds the smallest causal electrical-planning model that preserves that coherence: one region-wide road-following network with real settlement service relationships, while deferring tactical poles, runtime electricity and failure simulation to their proper owners.
