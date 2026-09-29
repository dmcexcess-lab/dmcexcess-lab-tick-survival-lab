# Slice 12 — Open-World Simulation Boundary — 2026-09-29

## Outcome

Slice 12 makes the open-world actor boundary explicit without adding a new simulation architecture.

Canonical infected execution is now bounded in two stages:

1. the existing WorldStreamingCoordinator defines which streamed regions are active around the player;
2. the existing SimpleTurnController ACTIVE_RADIUS remains the local action radius inside that streamed neighborhood.

Only infected currently placed in active streamed regions are supplied to canonical local-turn execution. Far or unloaded infected remain authoritative persistent entities/state but receive no ordinary movement, pathfinding, attacks or individual actor turns.

## Activation and persistence

- Procedural infected resident records are projected once and cached rather than rescanned on every player action.
- When the streaming boundary changes, only resident homes entering active streaming space are considered for hydration.
- Existing infected that move into active space become eligible again.
- Infected leaving active space remain in WorldState/Health state and become dormant; they are not deleted or reset.
- SimpleTurnController refreshes the boundary immediately before local infected responses so a newly entered neighborhood can participate on the same action boundary.
- Technical region changes do not regenerate player-caused world consequences.

## Long actions and performance

World-time advancement remains separate from actor-turn advancement.

A long action such as eight hours of sleep still creates one ordinary local actor-response boundary. It does not iterate simulated minutes/hours or wake the rest of the island.

Ordinary same-region actions use cached streaming membership and the current active roster. No per-frame activation scan, per-entity timer, whole-island actor loop or offscreen zombie simulation was introduced.

## Verification

Fresh prompt-local verification:

- `game/scripts/ci/verify_slice12.gd`
- `.github/workflows/slice12.yml`

The verifier boots the production scene and proves:

- local active infected are eligible while far infected are excluded;
- actor work is bounded by the active roster;
- far infected remain stationary/persistent across ordinary and long-duration actions;
- idle render frames create no actor simulation;
- an eight-hour action advances authoritative Slice 11 world time without multiplying infected turns;
- moving streaming focus changes the eligible roster while preserving old-area infected state;
- durable snapshot/Continue preserves both active and dormant infected placements/identity;
- legacy TickKernel remains dormant.
