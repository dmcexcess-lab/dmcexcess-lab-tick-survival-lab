# Tick Survival Lab — System 29 World Interaction Affordance / Reach

Status: **DRAFT — awaiting approval**

Roadmap owner: **Phase 1A — Interaction affordance + reach foundation**.

User direction, 2026-08-24:

> **“highlight containers and objects close enough to use”**

Core rule:

> **A highlight explains an already-valid interaction. It never creates interaction truth.**

The player should be able to glance at the tactical view and immediately understand which nearby, currently perceived physical objects can actually be acted on from the survivor's present position/facing. The renderer must not guess this from sprite type, semantic name, proximity alone, or hidden WHAT truth.

---

## 1. Why this is a separate foundation

Current System 24 already contains a proven reach rule in `LootInteractionReach`:

- actor footprint;
- plus the one-cell-forward fringe in current facing;
- target must be a current placed OBJECT.

Both timed search and world-container TAKE/STORE access reuse that rule.

The roadmap will shortly add many other real interactions: crafting workstations, utility hardware, switches, TVs/appliances, vehicle access, treatment stations and other world objects. Duplicating a slightly different reach/highlight rule inside each owner would create drift.

System 29 therefore generalizes **reach + available-interaction presentation**, while each mechanic still owns whether its action actually exists and whether it is currently legal.

---

## 2. Ownership

System 29 owns:

- neutral actor-to-world-object interaction reach vocabulary;
- current reachable-cell calculation for supported reach profiles;
- a neutral read-only interaction-offer descriptor;
- composition/query of offers supplied by real mechanic owners;
- knowledge-safe filtering of offers for player presentation;
- low-resolution nearby-object highlight presentation;
- deterministic offer/highlight ordering and bounded local discovery;
- presentation invalidation/lifecycle for movement, facing, perception and provider-state changes.

System 29 does **not** own:

- search, TAKE, STORE or container contents — Systems 24/12/11;
- doors or automatic passage — Systems 18/06A;
- future appliance/TV state;
- crafting/workstation state;
- power/water truth;
- vehicle access/state;
- item use/eating/treatment;
- actor perception or memory — System 23;
- world-object existence/placement — WHAT;
- action timing — owning mechanic + WHEN;
- input selection or a universal `USE` action in Candidate 001;
- semantic prop art;
- AI interaction decisions.

---

## 3. Candidate 001 reach profile

First profile:

`CONTACT_FORWARD`

Reachable cells are exactly the current System-24 rule:

1. every cell in the actor's current physical footprint;
2. every corresponding cell one cardinal step forward in current actor facing.

A target is geometrically reachable when any of its current physical footprint cells intersects that set.

This preserves existing System-24 search/external-container behavior exactly while moving the rule to a reusable owner.

Candidate 001 deliberately does **not** add:

- diagonal reach;
- two-cell reach;
- through-wall reach;
- automatic turning;
- click-anything-from-across-the-room behavior.

Future action owners may request additional explicitly designed reach profiles if a real mechanic needs them. They do not hand System 29 arbitrary distance numbers per call.

---

## 4. Neutral interaction offers

System 29 needs a presentation-safe descriptor similar in spirit to the existing sound/perception descriptors.

Proposed `InteractionOffer` fields:

- `actor_id`;
- `target_entity_id`;
- opaque/semantic `action_id`;
- readable short label such as `SEARCH`;
- reach profile ID;
- copied current target footprint cells;
- presentation priority;
- optional compact presentation category such as `container`, `fixture`, `vehicle`;
- `available = true` only when the owning provider says the real action is currently available.

An offer contains **no mutation callback** and no direct renderer-to-gameplay function reference.

System 29 does not infer offers from `prop.*`, `fixture.*`, `item.*` names. A refrigerator is highlighted because a real owner publishes a legal offer for that stable entity, not because its sprite resembles a refrigerator.

---

## 5. Provider seam

Proposed neutral provider contract:

`InteractionOfferProvider.offers_for_actor(actor_id, candidate_target_ids) -> Array[InteractionOffer]`

Providers remain owned by their mechanic domains.

Candidate 001 provider:

### System 24 searchable-container provider

It may offer:

`SEARCH`

only for current physical containers that:

- are initialized/enrolled real System-24 searchable containers;
- still exist in WHAT on OBJECT;
- pass the shared System-29 reach query;
- satisfy any existing System-24 action preconditions that are safe/read-only to expose.

System 24's actual search service remains authoritative at request and commit. A highlight is never a promise that state cannot change before the action commits.

Later providers can attach without changing the highlight renderer.

---

## 6. System-24 migration

`LootInteractionReach` is currently the duplicated-domain candidate to retire or reduce to a compatibility-free internal migration.

System 24 search validation and `LootWorldContainerAccessPolicy` should consume the System-29 reach contract instead.

Acceptance requirement:

> Every previously reachable/unreachable System-24 container remains exactly reachable/unreachable after the migration.

This is a behavior-preserving ownership refactor, not a stealth rebalance of looting range.

---

## 7. Perception / hidden-information rule

System 23 remains the sole owner of visual knowledge.

For player-facing highlight presentation:

- a target with no currently `VISIBLE` physical footprint cell produces **no highlight**;
- `REMEMBERED` is not sufficient for a current-use highlight because it is stale knowledge;
- `UNSEEN` is never highlighted;
- if a multi-cell object is only partially visible, presentation draws only currently visible portions/cells unless later visual-geometry metadata safely supports a better clipped outline;
- an offer may exist mechanically in the query layer while being suppressed from player presentation by System 23 knowledge.

Thus highlighting cannot reveal a dark refrigerator, hidden cabinet, object behind a wall, or an unrendered/unexplored structure merely because WHAT says it is in reach.

System 29 never changes System-23 memory/exploration state.

---

## 8. Candidate 001 highlight presentation

Visual target:

- low-resolution/pixel-native;
- restrained rather than neon-gamey;
- readable on phone;
- presentation only.

Proposed first style:

- 1–2 screen-pixel outline/tick marks around the target's **real visible footprint cells**;
- warm/yellow-white readability color consistent with the current interaction/sound vocabulary without pretending to be physical emitted light;
- optional very slow presentation-only alpha pulse while the game waits at decision pause;
- no bloom and no System-27 light contribution;
- one highlight command per stable target, even if multiple actions/providers refer to it.

The highlight renderer should sit above live world lighting but below modal/UI surfaces and remain constrained by System-23 knowledge.

Exact z-order will be chosen against the current Tactical renderer stack during implementation; the rule is semantic, not a hardcoded draft number.

---

## 9. Multiple targets / multiple offers

Several nearby objects may be usable simultaneously.

Candidate ordering:

1. presentation priority;
2. target anchor distance within the tiny reachable set;
3. target stable ID;
4. action ID.

The renderer may highlight more than one reachable target. Candidate 001 does **not** automatically choose or execute one.

If a later player-control design adds an `INTERACT` intent, target/action selection belongs to a dedicated controller using the same offers; it does not require rewriting reach or highlight truth.

This avoids prematurely designing a radial menu or tap-target system merely to satisfy the Phase-1 highlight request.

---

## 10. Discovery / performance

System 29 must remain effectively constant-cost with world size.

Candidate approach:

1. compute the actor's tiny current reachable-cell set;
2. inspect WHAT OBJECT occupancy only in those cells;
3. deduplicate stable target IDs;
4. ask registered providers about those candidates;
5. apply System-23 visible-state filter for presentation;
6. emit a tiny highlight command list.

No full-world scan.

Typical `CONTACT_FORWARD` survivor footprint means only the actor's own cell(s) plus one forward fringe are inspected.

No Node per interactable object. One renderer owns all highlight drawing.

No `_process()` world query loop. Recompute on meaningful invalidation such as:

- controlled actor move/turn/placement change;
- current perception recompute affecting nearby cells;
- reachable target placement/removal;
- provider-specific availability revision;
- world reset;
- active controlled actor change later.

A cosmetic pulse may animate presentation delta only while highlights exist; it advances zero WHEN ticks.

---

## 11. Failure behavior

Fail closed / no highlight when:

- actor is missing/unplaced/not a supported living survivor;
- facing is invalid;
- target placement is missing/stale;
- target is not on the expected physical channel for the provider;
- provider is not ready;
- target no longer passes reach;
- System 23 says no target footprint cell is currently VISIBLE;
- an offer descriptor is malformed.

Diagnostics may be exposed in DEV/test mode, but ordinary play should not draw fake fallback interaction markers.

---

## 12. Public-contract impact

Expected additive contracts:

- `WorldInteractionReachQuery` or equivalently named neutral reach owner;
- `InteractionOffer`;
- `InteractionOfferProvider`;
- `InteractionAffordanceQuery`;
- `InteractionHighlightRenderer`.

Expected migration:

- System 24 replaces private `LootInteractionReach` usage with System 29's `CONTACT_FORWARD` contract.

No WHAT schema change and no save migration should be required because Candidate 001 System 29 owns no persistent gameplay state.

---

## 13. Protected neighbors

Implementation must preserve:

- System 24 deterministic loot/search timing/current-content behavior;
- System 12 transfer mutation and external-container carry policy;
- System 23 visibility/memory semantics;
- System 27 physical lighting truth;
- WHERE/WHAT footprint/facing semantics;
- WHEN zero-tick read/query behavior;
- current mobile player-shell input blocking/modal behavior;
- existing Prop renderer ownership.

---

## 14. Verification plan

Focused headless/query tests should prove:

- current System-24 reachable/unreachable fixtures are unchanged by the generalized reach owner;
- forward facing matters exactly as before;
- multi-cell target intersection works;
- no diagonal/behind reach is accidentally granted;
- only real provider offers produce highlights;
- an ordinary decorative nearby prop with no provider/action does not highlight;
- VISIBLE target can highlight;
- REMEMBERED target does not highlight;
- UNSEEN target does not highlight;
- partial multi-cell visibility does not reveal hidden cells;
- multiple offers deduplicate target highlight deterministically;
- queries and cosmetic pulse consume zero WHEN ticks;
- actor-local occupancy bounds are respected; no full-world entity scan;
- System 24 / System 23 / canonical player shell / startup regressions stay green.

Human/mobile acceptance:

- on iPhone/Safari it is immediately obvious which nearby searchable container is in current interaction reach;
- highlight is readable but does not drown out lighting/fog/weather;
- turning away removes a forward-only highlight exactly when the real search action becomes unreachable.

---

## 15. Deferred

System 29 Candidate 001 does **not** implement:

- universal Interact button;
- tap-to-select target;
- interaction radial/list menu;
- object action execution;
- reach skill modifiers;
- long tools/reach weapons;
- NPC interaction planning;
- powered appliance actions;
- crafting/workstation actions;
- vehicle interaction;
- loose-item pickup highlighting unless separately approved through the same provider model.

Those may consume the same contract later.

---

## 16. North-star fit

This keeps interaction readable in the small top-down world without turning the game into a glowing-object arcade layer. It exposes **real causal affordances** from the same physical state/actions that already govern looting, and establishes a cheap reusable interface for the increasingly interactive world planned through Beta.

---

## 17. Decisions proposed for approval

1. System 29 owns neutral world interaction reach + player-facing affordance composition, not action execution.
2. Candidate 001 preserves System 24's current actor-footprint + one-cell-forward `CONTACT_FORWARD` reach exactly.
3. System 24 migrates search/external-container reach to the shared contract with zero range rebalance.
4. Only real mechanic providers may publish offers; sprite/semantic appearance alone never creates a highlight.
5. Player highlights require current System-23 VISIBLE knowledge; REMEMBERED/UNSEEN cannot reveal current usability.
6. Candidate highlight is a restrained pixel outline/marker over visible target footprint, not physical light.
7. Discovery is actor-local and event-driven; no full-world scan or per-object Nodes.
8. Candidate 001 adds no universal Interact button or action execution controller yet.
