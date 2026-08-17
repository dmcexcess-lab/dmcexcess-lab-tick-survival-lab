# Tick Survival Lab — 09 Actor Hand Equipment State

Status: **IMPLEMENTED — canonical two-hand equipment state and dedicated Godot CI contract present 2026-08-16**

Approval basis: after 08 Player / Living Actor Renderer was implemented, the user requested visible primary/right-hand and secondary/left-hand objects for the controlled survivor and survivor NPCs, then explicitly approved this detailed 09 prerequisite contract on 2026-08-16.

## 1. Goal

Own the durable mechanic truth for exactly two anatomical survivor hand slots:

- `PRIMARY_RIGHT` — primary role, actor's right hand;
- `SECONDARY_LEFT` — secondary role, actor's left hand.

Assignments reference stable physical WHAT `item.*` entity IDs. Primary/secondary are hand roles, not weapon/tool classes, and never swap meaning when the actor turns.

## 2. Owners

Production:

- `game/scripts/simulation/actors/equipment/ActorHandSlot.gd`
- `game/scripts/simulation/actors/equipment/ActorHandEquipmentRecord.gd`
- `game/scripts/simulation/actors/equipment/ActorHandEquipmentState.gd`
- `game/scripts/simulation/actors/equipment/ActorHandEquipmentMutationService.gd`

Testing:

- `game/scripts/ci/ActorHandEquipmentSmoke.gd`
- `.github/workflows/actor-hand-equipment.yml`

## 3. Supported actors

V1 enrollment is explicit and accepts only canonical `actor.survivor` WHAT entities. The controlled survivor is not a special entity type and uses the same state as NPC survivors.

`actor.infected`, animals, and other future actor families are not implicitly equipment-capable.

Missing record means **not enrolled / unknown**, not “both hands empty.” An enrolled record can explicitly have either or both hand item IDs empty.

## 4. Record contract

`ActorHandEquipmentRecord` contains:

- `actor_id: String`
- `primary_item_id: String`
- `secondary_item_id: String`
- `version: int`

Empty item ID means that enrolled hand is explicitly empty. Records are copy-safe to readers and reject invalid actor/item ID syntax, non-positive versions, and the same non-empty item ID in both hands.

Per-actor versions are monotonic across mutations. Removal + later re-enrollment receives a newer version so future timed equip/swap actions can detect stale state.

## 5. Read contract

`ActorHandEquipmentState` exposes:

- `revision() -> int`
- `has_actor(actor_id) -> bool`
- `actor_ids() -> Array[String]` sorted
- `record(actor_id) -> ActorHandEquipmentRecord` copy or null
- `version(actor_id) -> int`
- `item_in_slot(actor_id, slot) -> String`
- `primary_item(actor_id) -> String`
- `secondary_item(actor_id) -> String`
- `assignment_for_item(item_id) -> Dictionary`
- `snapshot() -> Dictionary`
- `load_snapshot(data) -> bool`

Callers distinguish unknown enrollment through `has_actor` / `record`; empty string is meaningful only inside an enrolled record as an explicitly empty hand.

## 6. Mutation contract

Normal low-level writes go through `ActorHandEquipmentMutationService`:

- `enroll_actor(actor_id)`
- `remove_actor(actor_id)`
- `set_item(actor_id, slot, item_id)`
- `clear_slot(actor_id, slot)`

These are mechanic-state primitives only. They consume zero ticks and do not perform inventory transfer, pickup/equip actions, animation, combat, lighting, UI, or rendering.

Enrollment validates a live WHAT `actor.survivor` entity. Assigning validates:

- enrolled survivor;
- valid hand slot;
- stable WHAT item entity exists;
- semantic type begins `item.` with a non-empty kind;
- item is tactically unplaced;
- item is not assigned to another hand/actor.

Assigning the exact already-current item to the exact same slot is a successful no-op with no revision/version/signal. `clear_slot` supports explicit state cleanup without requiring a new item reference.

## 7. Physical-item uniqueness

The store maintains a derived reverse assignment index:

`item_id -> { actor_id, slot }`

One stable physical item cannot simultaneously occupy both hands or multiple actors. Snapshot truth remains the per-actor records; the reverse index is rebuilt/validated from them.

## 8. Lifecycle boundary

Hand state may persist while an actor is tactically unplaced.

Removing an actor or item from WHAT does not silently mutate this mechanic domain. Higher-level lifecycle/save orchestration must coordinate cleanup explicitly. `remove_actor` therefore remains available even after the WHAT actor was already removed.

Normal new item assignment still requires the actor to exist as a valid WHAT survivor.

## 9. Signals / revision

State emits:

- `actor_enrolled(actor_id, version)`
- `actor_removed(actor_id, primary_item_id, secondary_item_id, version)`
- `hand_assignment_changed(actor_id, slot, previous_item_id, new_item_id, version)`
- `hand_equipment_reset`

Real mutations increment global store revision. Hand assignment changes increment the actor version. No-op same assignment does neither.

## 10. Snapshot / determinism

Snapshot schema version is 1.

Requirements implemented:

- records serialized in stable actor-ID order;
- explicit primary/secondary stable item IDs;
- global revision retained;
- full candidate payload validated before live replacement;
- duplicate actor IDs rejected;
- duplicate physical item assignment rejected;
- malformed IDs/non-positive versions rejected;
- record version may not exceed restored revision;
- successful restore emits exactly one reset signal;
- reverse assignment index rebuilt from restored canonical records.

Snapshot restore intentionally does not require WHAT to be restored in the same method; cross-domain restore order belongs to future save orchestration.

## 11. Forbidden ownership

09 does not import or own:

- Art Catalog / textures / atlas indices;
- actor drawing, held-item rotation, or body occlusion;
- Inventory / Containment;
- item definitions/stats beyond minimal `item.*` identity validation;
- combat, ammo, damage;
- Health / injury / fatigue / encumbrance;
- carried-light behavior;
- Collision / Movement;
- WHEN / equip action durations;
- AI;
- camera / input / UI;
- generation;
- frozen reboot runtime.

## 12. Recovery source

Same-owner First Fire `FFTacticalVisuals.gd` established the useful concept of visible `Weapon` and `Secondary` carried objects. First Fire stored item-name strings inside survivor dictionaries; canonical Tick deliberately rejects that architecture and references persistent stable physical item entities instead.

## 13. Downstream held-item presentation contract

The next bounded system is **Actor Hand Equipment Presentation**. It will read WHAT living actor placement/facing plus 09 hand assignments and resolve item art without mutating hand state.

Locked requested presentation direction for that later design:

1. held objects float beside the actor;
2. primary remains anatomical right, secondary anatomical left;
3. held-object art rotates with N/E/S/W facing;
4. north/south show both hand objects clearly;
5. east/west use `back hand -> actor body -> front hand` draw ordering;
6. anatomical side vector uses `right = (-facing.y, facing.x)`, `left = -right`;
7. EAST: secondary/left is far/back, primary/right near/front;
8. WEST: primary/right is far/back, secondary/left near/front;
9. occlusion is presentation draw ordering only; item state is never deleted;
10. recover First Fire weapon silhouettes and secondary utility icons before inventing replacement art.

## 14. Downstream canonical demo/UI direction

The future canonical demo must remain Safari/iPhone first-class and eventually include:

- touch Forward, Back, Turn Left, Turn Right and implemented stance/navigation controls;
- desktop keyboard equivalents;
- recovered-style `Looking at: ...` HUD line;
- concise **real** actor stats only;
- `STATS`, `INVENTORY`, and `MENU` buttons;
- Stats/Inventory inspection that hard-pauses safely;
- menu with Resume and Leave Game;
- no fabricated HP/stamina/carry/inventory values before their owning systems exist.

Web Leave Game should prefer useful browser-history return and use a safe fallback such as Google; a web page cannot reliably open the user's configured browser homepage.

These behaviors are downstream and are not implemented by 09.

## 15. Verified acceptance

Initial full production head `c108083744f474c80b06f8dc02673b60f1dca7cd` passed dedicated **Actor Hand Equipment contract** run `31986162867` with no production repair required.

Verified there:

- source-boundary isolation;
- Godot 4.7.1 project parse/import;
- persistent WHAT regression;
- explicit survivor enrollment;
- missing-record distinction;
- explicit empty hands;
- stable `item.*` assignment;
- nonexistent/non-item/tactically placed item rejection;
- duplicate actor enrollment rejection;
- one physical item cannot occupy two hands or two actors;
- no-op assignment preserves revision/version and emits no signal;
- reverse assignment lookup;
- tactically unplaced actor retains hand state;
- explicit orphan cleanup;
- removal/re-enrollment stale-version protection;
- copy-safe reads;
- deterministic sorted snapshot;
- duplicate item/actor and malformed version snapshot rejection atomically;
- exactly one reset signal on successful restore.

## 16. Future seams

Known consumers/extensions:

- Actor Hand Equipment Presentation;
- Inventory/Containment and timed equip/unequip/swap coordination;
- combat attack selection;
- two-handed-item rules;
- weight/encumbrance providers;
- carried flashlight/light-source state;
- durability/ammunition;
- character creator/start loadout;
- save/load and distant actor simulation;
- detailed stats/inventory UI.

Two-handed gear is deliberately not implemented in v1. A later rule can reserve both anatomical slots without changing primary/right and secondary/left semantics.

## 17. North-star fit

Stable physical hand assignments make visible equipment meaningful survival truth rather than decoration. The system stays intentionally small while preserving consequence: one item cannot secretly exist in several hands, renderers do not become inventories, and later combat/lighting/UI can consume the same persistent state.

## 18. Approved decisions

Approved 2026-08-16:

- primary = anatomical right hand;
- secondary = anatomical left hand;
- stable WHAT `item.*` IDs are canonical equipment references;
- explicit survivor enrollment and explicit empty-hand state;
- one physical item may occupy only one hand assignment globally;
- held items are normally tactically unplaced;
- 09 is state only; presentation/inventory/action/UI remain separate owners;
- next system is held-item presentation with facing rotation and east/west body occlusion.
