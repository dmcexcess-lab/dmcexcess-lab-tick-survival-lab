# Phase 1D Closeout + Phase 1E Design Changelog — 2026-08-27

## Roadmap Phase 1D / System 07B — complete

- Implemented presentation-only large / multi-cell visual geometry under the rule: **physical footprint answers where the object is; visual geometry answers how it is drawn**.
- Added Node-free visual span/pivot descriptors and a shared cached stable-entity visual plan.
- Preserved exact historical 1x1 geometry for unmapped props.
- Added a bounded two-cell visual-overhang discovery halo with visual-AABB culling; no whole-world object scan.
- Added a z=35 optional foreground/overhang pass between actors and physical lighting while retaining the z=20 base prop pass.
- Added dedicated large deciduous-tree base/canopy art and large traffic-light pole/signal-head art.
- Traffic-light orientation remains derived from System 07A / authoritative facing.
- Expanded the existing System-27 physical-light presentation shader to a soft two-ring emitter-derived bloom. Bright art itself does not create illumination or glow truth.
- No collision, reach, LOS, WHEN, streaming, save-state or gameplay-light ownership changed.
- The initial System-07B workflow had two CI-only startup assertion mistakes: first it referenced a nonexistent smoke script; after switching to canonical project startup it still grepped an obsolete success string. Both were corrected without gameplay changes.
- Final verified executable/workflow head: `d5e33b43fb732835b4a996ae4bec3a562cfa75f3`.
- All **18 required exact-head contexts** are green there, including `verify/system07b-large-visual-geometry`, `verify/system27-physical-lighting`, `verify/performance-architecture` and `verify/pages-deploy`.
- Automated verification is complete. Separate human visual acceptance for the new large-object art/glow is not yet recorded.

## Roadmap Phase 1E — design complete, awaiting approval

- Added canonical draft `SYSTEM_DESIGNS/PHASE_1E_CONTENT_EXPANSION_INTEGRATION.md`.
- Phase 1E is explicitly a **cross-system content/integration phase, not System 32**.
- Candidate implementation order:
  1. `1E-1` World clutter + location identity through existing Systems 19/20/04/07B.
  2. `1E-2` Mundane loot + perishable breadth through Systems 24/13D/30/31.
  3. `1E-3` Integration/readability/performance acceptance through the existing perception/interaction/lighting/presentation seams.
- All 24 current System-19 building archetypes receive an intentional content audit; outdoor/area profiles receive bounded deterministic exterior identity without disturbing roads, bridges, water, access or ecology boundaries.
- New loot remains real deterministic persistent System-24 content: **loot exists before you search for it**.
- Every new item must have positive System-13D weight and an explicit System-31 icon; every new perishable must have an explicit System-30 freshness profile.
- No fake Crafting, Power/Refrigeration, nutrition/Health, Skills, Vehicles, firearms/combat or AI behavior is authorized by Phase 1E.
- Proposed permanent implementation context: `verify/phase1e-content-integration`, making 19 required exact-head contexts once 1E is implemented.
- Phase 1E stops at DESCRIBE until explicit approval.
