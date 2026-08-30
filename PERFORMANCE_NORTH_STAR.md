# Tick Survival Lab — Performance North Star

Status: **canonical cross-cutting performance doctrine**.

> **The low-resolution 2D presentation and turn-based simulation are deliberate performance advantages. Spend that budget on simulation depth, persistence, world scale and responsiveness — not avoidable work.**

Tick Survival Lab uses low-resolution sprite-based 2D graphics and discrete player-driven time in part because those constraints buy substantial computational headroom. Performance is therefore an architectural requirement, not a cleanup phase reserved for visible slowdowns.

The intended bargain is asymmetric: presentation stays deliberately cheap so the world can become richer without ordinary play becoming expensive.

## Rules

- Recurring work is guilty until justified. Be especially suspicious of per-frame, per-tick, per-entity and full-world work.
- Prefer event-driven invalidation, dirty/revision tracking, caching, batching, analytic derivation and coarse/distance-scaled simulation over polling or repeated recomputation.
- Cost should normally scale with the **smallest relevant active set**, not with the total persistent world. A local question should use a local query.
- Turn-based simulation should do simulation work because authoritative time advanced or relevant truth changed — not merely because a render frame occurred.
- Cosmetic animation may continue independently of simulation time when appropriate, but it should use the cheapest suitable presentation path and must never become simulation authority.
- Streaming/materialization may hide a large persistent world behind bounded active work, but crossing a technical boundary must not monopolize the player's render/input frame.
- Avoid one Node, timer, `_process`, signal fan-out, scheduled event or other repeating runtime object per persistent entity when centralized/data-oriented state can express the same truth more cheaply.
- Use the GPU for genuinely parallel presentation work when it is the cheaper architecture; do not move simulation truth into shaders merely to gain speed.
- Preserve headroom. **“Fast enough on the current machine” is not a design justification for unnecessary work.** Phone/Safari is a first-class performance floor.
- Performance optimizations must preserve causality, persistence and player-visible consequences. Never fake or discard meaningful world truth merely to make a benchmark green.

When two designs preserve the same gameplay truth and one performs less repeated work, prefer the cheaper design even if both currently run acceptably.
