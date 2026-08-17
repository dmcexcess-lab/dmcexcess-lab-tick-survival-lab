# Tick Survival Lab — 09 Actor Hand Equipment State

Status: **DRAFT — prerequisite design for visible primary/right-hand and secondary/left-hand equipment; implementation requires explicit approval**

Discussion basis: after 08 Player / Living Actor Renderer was implemented, the user requested that the controlled survivor and survivor NPCs visibly carry the objects assigned to their primary/right and secondary/left hands. The user also requested that held objects turn with actor facing, use body occlusion for the far hand when facing east/west, and appear in the forthcoming Safari-first canonical demo alongside navigation buttons, the recovered `Looking at:` display, stats/inventory access, and a pause/menu path.

This document deliberately designs only the **authoritative two-hand equipment state prerequisite**. Held-item drawing is a separate presentation system, and the demo HUD/input/inspector remains downstream.

## 1. Goal

Own the durable answer to exactly two questions for an equipment-capable living actor:

- what stable physical item is currently in the actor's **primary / right hand**;
- what stable physical item is currently in the actor's **secondary / left hand**.

The state must be real persistent mechanic truth keyed by stable WHAT entity IDs so later rendering, inventory, combat, encumbrance, carried light, save/load and UI can all observe the same assignments without inventing parallel loadout dictionaries.

## 2. Slot vocabulary

Canonical v1 hand slots:

- `PRIMARY_RIGHT` — primary slot, anatomically the actor's right hand;
- `SECONDARY_LEFT` — secondary slot, anatomically the actor's left hand.

`primary` and `secondary` are hand roles, **not weapon/tool classes**. A flashlight, knife, firearm, carried object or future holdable item may occupy either hand if later item/equipment rules allow it.

UI may label them compactly as:

- `PRIMARY (R)`
- `SECONDARY (L)`

The slot-to-hand mapping is persistent and does not swap when the actor turns.

## 3. Canonical item identity prerequisite

Physical carried/equipped gear should be represented by stable WHAT entities rather than item-name strings copied into actor state.

Initial equipment-state validation therefore expects referenced items to:

- exist as stable WHAT entities;
- use the semantic family `item.*`;
- normally be tactically unplaced while held/equipped.

WHAT already supports persistent entities that are temporarily unplaced. This is the intended representation for an item carried in a hand or later contained by inventory.

09 does **not** define the full item taxonomy, stack rules, quantities, durability, ammunition, weight, container ownership or item statistics. Those belong to later item/inventory/equipment systems.

## 4. Intended owners

After approval:

- `game/scripts/simulation/actors/equipment/ActorHandSlot.gd`
- `game/scripts/simulation/actors/equipment/ActorHandEquipmentRecord.gd`
- `game/scripts/simulation/actors/equipment/ActorHandEquipmentState.gd`
- `game/scripts/simulation/actors/equipment/ActorHandEquipmentMutationService.gd`
- `game/scripts/ci/ActorHandEquipmentSmoke.gd`
- `.github/workflows/actor-hand-equipment.yml`

No renderer, UI, inventory or action controller belongs in these files.

## 5. Supported actors

V1 hand-equipment enrollment is for canonical living human survivors:

- `actor.survivor`

The controlled survivor is not a special semantic type; it uses the same hand-equipment state as NPC survivors.

`actor.infected` is not automatically equipment-capable in v1. If later design introduces infected/animals/other actors that can intentionally hold objects, that capability must be explicit rather than inferred from being on the ACTOR channel.

## 6. Explicit enrollment / no implicit empty loadout

An actor must be explicitly enrolled before hand state is authoritative.

Missing record means **UNCLASSIFIED / UNKNOWN**, not silently "both hands empty."

An enrolled record may explicitly contain:

- primary empty;
- secondary empty;
- either one occupied;
- both occupied.

This distinction matters to diagnostics, save/load and future content validation.

## 7. Record contract

`ActorHandEquipmentRecord` contains at least:

- `actor_id: String`
- `primary_item_id: String`
- `secondary_item_id: String`
- `version: int`

Empty item ID means that enrolled hand is explicitly empty.

Records are immutable-style/copy-safe to readers.

Each actor lifecycle receives monotonic versions so a future timed equip/swap action can capture an expected version and detect stale state before commit.

## 8. Read contract

`ActorHandEquipmentState` should expose narrow mutation-safe reads such as:

- `revision() -> int`
- `has_actor(actor_id) -> bool`
- `record(actor_id) -> ActorHandEquipmentRecord`
- `item_in_slot(actor_id, slot) -> String`
- `primary_item(actor_id) -> String`
- `secondary_item(actor_id) -> String`
- `actor_ids() -> Array[String]` sorted
- `assignment_for_item(item_id)` or equivalent read-only reverse lookup
- `snapshot() -> Dictionary`
- `load_snapshot(data) -> bool`

The exact UNKNOWN result type may be a typed decision/status object if implementation shows a plain missing-record distinction is insufficient. Do not encode UNKNOWN as an empty item ID.

## 9. Mutation contract

Normal low-level writes go through `ActorHandEquipmentMutationService`.

Expected operations:

- `enroll_actor(actor_id)`
- `remove_actor(actor_id)`
- `set_item(actor_id, slot, item_id)`
- `clear_slot(actor_id, slot)`
- optional atomic `swap_hands(actor_id)` if implementation can keep it narrow and deterministic

These are **state mutation primitives**, not player actions. They consume no ticks and do not implement pickup/equip animations, inventory transfers or combat.

Future gameplay equip/unequip/swap actions will coordinate Inventory/Containment + 09 + WHEN at commit.

## 10. Validation rules

Enrollment:

- actor ID must be valid/stable;
- WHAT entity must exist;
- semantic type must be `actor.survivor`;
- duplicate enrollment rejected.

Assigning an item:

- actor must be enrolled;
- slot must be valid;
- item ID must be valid/stable;
- WHAT item entity must exist;
- semantic type must begin `item.` and contain a non-empty item kind;
- item must not currently have a tactical WHAT placement;
- the same stable item ID cannot occupy both hands;
- the same stable item ID cannot be assigned to two actors simultaneously;
- assigning the exact already-current item to the exact same slot is a successful no-op with no revision/version/signal.

09 deliberately does **not** claim the actor actually possesses the item in a backpack/container because Inventory/Containment does not exist yet. A later equip coordinator will enforce containment/ownership before calling this low-level state service.

## 11. Reverse assignment / uniqueness

The store should maintain or deterministically derive a reverse item assignment so one physical item cannot be simultaneously equipped in multiple places.

Conceptually:

`item_id -> (actor_id, hand_slot)`

This reverse index is derived/cacheable state; snapshot truth remains the actor hand records unless implementation proves another normalized shape is safer.

## 12. Lifecycle boundaries

Hand state may persist while the actor is tactically unplaced.

Removing/unplacing a WHAT actor does not silently erase hand state. Actor lifecycle cleanup is explicit.

Deleting an item or actor from WHAT does not trigger hidden cross-domain mutation inside WHAT. Higher-level lifecycle/save orchestration is responsible for coordinated cleanup.

Snapshot restore may validate its own schema atomically without requiring WHAT to be restored in the same method; cross-domain restore order remains a save-orchestration concern.

## 13. Signals / revision

Expected typed notifications:

- actor enrolled;
- actor removed;
- hand assignment changed;
- state reset after successful snapshot restore.

Real mutations increment store revision and per-actor version. No-op assignment does not.

Presentation and UI may observe these signals later; 09 itself does not redraw anything.

## 14. Snapshot / determinism

Snapshot requirements:

- schema versioned;
- actor records serialized in stable actor-ID order;
- explicit primary/secondary stable item IDs;
- deterministic output;
- full payload validated before replacing live state;
- malformed/duplicate actor IDs rejected atomically;
- duplicate physical item assignment rejected atomically;
- invalid slot/state rejected;
- successful restore emits one reset notification.

## 15. Forbidden ownership

09 must not own/import:

- Art Catalog or texture/atlas information;
- actor drawing or body occlusion;
- Inventory/Containment storage;
- item definitions/stats beyond validating the minimal `item.*` identity family;
- combat/attacks/ammo/damage;
- health/injury;
- encumbrance/fatigue;
- lighting/perception or flashlight effects;
- Collision/Movement rules;
- WHEN/action durations;
- AI;
- camera/input/UI;
- generation;
- frozen reboot runtime.

## 16. Recovery source and what is intentionally rejected

Same-owner First Fire `FFTacticalVisuals.gd` already established the useful player-facing concept of a `Weapon` plus a `Secondary` object and drew them next to survivors. `FFData.gd` also classified First Fire gear into `Weapon`, `Secondary`, `Tool`, `Clothing`, and `Pack` slots.

09 recovers only the coherent two-hand concept.

It intentionally rejects First Fire's runtime architecture of storing item names directly in survivor dictionaries. Canonical Tick equipment references persistent stable item entities instead.

## 17. Downstream 10 — held-item presentation direction already requested

The next bounded system after 09 should be **Actor Hand Equipment Presentation**.

It will read:

- visible living ACTOR truth from WHAT/08-compatible geometry;
- 09 primary/right + secondary/left item IDs;
- semantic item types through WHAT;
- recovered held-item art through an additive Art Catalog contract.

Requested presentation behavior to preserve in that later design:

1. Both hand items float immediately beside the actor rather than replacing the actor sprite.
2. Primary is always the actor's anatomical right hand; secondary is always anatomical left.
3. Held-object art rotates in 90-degree increments with actor facing; renderer-specific rotation never changes physics or item identity.
4. North/south facings show both hand objects clearly beside the body.
5. East/west facings use real body occlusion with a back-hand pass and front-hand pass rather than simply drawing both objects over the actor.
6. With screen Y increasing downward, the intended anatomical side vector is the same proven First Fire relation: `right = (-facing.y, facing.x)`, `left = -right`.
7. For EAST, the right/primary hand is the south/near hand and the left/secondary hand is the north/far hand; secondary therefore draws behind the body.
8. For WEST, the left/secondary hand is the south/near hand and the right/primary hand is the north/far hand; primary therefore draws behind the body.
9. Occluded items are hidden by normal draw ordering/body coverage, not deleted from state.
10. Recovered First Fire weapon silhouettes and secondary utility icons should be mined before any new art is invented.

Those are presentation requirements only; they do not belong in 09 production code.

## 18. Downstream canonical demo/UI direction already requested

The authored canonical demo path should eventually include real Safari/mobile controls and inspection UI rather than being keyboard-only.

Requested UI target:

- visible touch buttons for Forward, Back, Turn Left, Turn Right and stance/navigation actions needed by the implemented systems;
- retain keyboard equivalents on desktop;
- concise top HUD with a recovered-style `Looking at: ...` display;
- concise real actor stats in the HUD;
- `STATS` button for a detailed actor inspector;
- `INVENTORY` button for real inventory/held-item inspection;
- `MENU` button that invokes hard application pause;
- menu includes Resume and Leave Game;
- detailed Stats and Inventory inspection also pause the simulation safely while open.

No fake HP, stamina, carry weight, names or inventory contents should be invented merely to fill the demo. The inspector must show only state owned by implemented canonical systems; Health/Needs/Inventory can expand it when those systems exist.

On Web/Safari, a website cannot reliably command the browser to open the user's configured homepage. The preferred future Leave Game behavior is therefore best-effort navigation back to the page that launched the game when browser history permits, with an explicit safe fallback such as Google when there is no useful prior page.

The `Looking at:` display should be recovered as a read-only facing inspection query over canonical WHAT rather than UI code reaching into renderer internals. Exact priority/label rules belong to the later HUD/inspection design.

## 19. Dependency order created by this request

The user's desired canonical demo now spans several real owners. Recommended order:

1. **09 Actor Hand Equipment State** — this DRAFT; real two-hand truth.
2. **Actor Hand Equipment Presentation** — recovered held-item art, rotation, hand offsets, body occlusion.
3. **Inventory / Containment** and any actor-stat domains required for real inspector data; do not fabricate them in UI.
4. **Authored Visual Test Area** — real canonical WHAT fixture containing structures/props/actors/items.
5. **Tactical renderer composition** — layer ordering including back-hand -> actor -> front-hand passes.
6. **Tactical camera + zoom** — supplies visible window/scale.
7. **Touch/keyboard/Safari input + Tactical Controls UI** — semantic action intents with real Button/Control nodes.
8. **HUD / Facing Inspection / Stats & Inventory Inspector / Pause Menu** — consumes real system state and hard-pause contract.

Some later slices may prove tightly coupled enough to combine after their contracts are designed, but they should not be hidden inside one demo-scene script.

## 20. Acceptance tests after approval

Dedicated Godot 4.7.1 CI should prove at minimum:

- source-boundary isolation;
- explicit survivor enrollment;
- missing record is not silently treated as enrolled empty hands;
- explicit empty primary/secondary state;
- stable WHAT `item.*` references accepted;
- nonexistent/non-item/placed item references rejected;
- duplicate actor enrollment rejected;
- same physical item cannot occupy two hands or two actors;
- same-state assignment is a no-op;
- real assignment increments actor version/store revision and emits typed change;
- actor may retain state while tactically unplaced;
- removal + re-enrollment cannot accidentally reuse a stale lifecycle version;
- copy-safe reads;
- deterministic sorted snapshot;
- atomic malformed snapshot rejection;
- duplicate item assignment in snapshot rejected;
- reset signal emitted once on successful restore;
- no Art/Render/Inventory/Combat/Health/WHEN/AI/Input/UI/Reboot imports.

## 21. Future seams

Known consumers/extensions:

- Actor Hand Equipment Presentation;
- Inventory/Containment and equip/unequip/swap actions;
- combat attack selection;
- two-handed-item rules;
- encumbrance/weight providers;
- carried flashlight/light-source state;
- item durability/ammunition;
- character creator/start loadout;
- save/load and distant actor simulation;
- detailed stats/inventory UI.

Two-handed gear is intentionally not implemented in v1. The slot vocabulary leaves room for a later rule that one item reserves both hands without changing the anatomical primary/secondary meaning.

## 22. North-star fit

Visible physical equipment is valuable because it makes the readable Ultima-style world communicate real survival state without opening menus, while stable item identity preserves mini-Zomboid consequence and persistence.

Separating hand assignment truth from held-item drawing and inventory mechanics keeps the system small without reducing consequence: one physical item cannot secretly exist in several hands, renderers do not become inventories, and later combat/lighting/UI can all consume the same real state.

## 23. Approval state

**DRAFT.**

The user has clearly requested the visible two-hand behavior and downstream Safari/demo UI direction. The detailed 09 state contract above still requires explicit approval before implementation under `DESIGN_WORKFLOW.md`.