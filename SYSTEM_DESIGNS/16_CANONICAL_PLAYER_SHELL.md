# 16 Canonical Player Shell / Inspectors / Stance Integration

Status: **APPROVED — implementation authorized by the user on 2026-08-16**

Approval basis: after reviewing the detailed System 16 draft, the user explicitly instructed **“16 approved for code.”**

## 1. Goal

Complete the first useful player-facing shell around the live canonical demo by exposing already-implemented canonical mechanics/state through phone/Safari-first controls and read-only inspection screens.

Player-visible v1:

- Crouch/Stand using the real System 03 timed stance action;
- `STATS` modal showing only real actor state;
- `INVENTORY` modal showing only real 09/11/13D/13E possession facts;
- `MENU` using WHEN hard application pause;
- Resume/Close restoring the exact prior hard-pause state;
- Web/native Leave Game behavior;
- no duplicate legacy help/tick text underneath the System 15 HUD.

System 16 is integration/presentation. It creates no new survival-mechanic truth.

## 2. Why this is one bounded integration slice

The owning simulation systems already exist and are independently tested: System 03 stance/capability, 09 Hands, 11 Containment, 13A Health, 13B Needs, 13C Skills, 13D item weight, 13E Carry, 13F Moodlets, and WHEN hard pause.

System 16 only composes their public contracts. Its read/query/UI owners remain focused so Stats, Inventory, Menu, and device input can evolve independently.

If a requested screen later requires a new mechanic or stable simulation-contract rewrite, that change must receive its own design rather than being hidden inside this shell.

## 3. Non-goals

System 16 does **not** add:

- pickup/drop/equip/move/use controls or new transfer rules;
- demo items, starter gear, or item spawning;
- loose-item rendering or held-item composition changes;
- capacity/bulk/stack/quantity/durability rules;
- new Health/Needs/Skills progression;
- traits, stress, temperature, infection, or other nonexistent stats;
- door interaction;
- perception/LOS;
- camera/zoom;
- save/load;
- browser visibility/focus lifecycle pause automation;
- generation.

Empty inventory, level-0 skills, no injuries, and other current defaults are valid real state and must be displayed honestly.

## 4. Existing canonical systems reused unchanged

### 03 Actor Locomotion

System 03 remains the owner of standing/crouched state and `ActorStanceActionService`.

- voluntary crouch/stand base cost remains 4 ticks before existing capability modifiers;
- crouched walking remains 1.4x the ordinary step duration (14 ticks against the current 10-tick demo terrain);
- stance mutates only at the existing timed commit.

### 09 Hands + 11 Inventory / Containment

Remain the physical hand/direct-containment truth. System 16 only reads them.

### 12 Item Transfer

Remains the owner of timed pickup/drop/equip/container transitions. System 16 does not bypass it.

### 13 Actor Status

Health, Needs, Skills, Item Physical Properties, Carry and Moodlets remain peer canonical domains. System 16 composes reads only.

### WHEN

`TickKernel.set_hard_paused()` / `is_hard_paused()` remain the pause truth used by the shell.

## 5. Owners

### `game/scripts/ui/ActorStatsInspectorQuery.gd`

Read-only detailed actor-status composer over:

- `ActorStatusSummaryQuery`;
- `ActorHealthState` injury reads;
- `ActorSkillState`;
- `ActorLocomotionState`.

It returns status, stance, injuries and dynamic skill entries. It owns no persistent state and performs no mutations.

### `game/scripts/ui/ActorInventoryInspectorQuery.gd`

Read-only inventory/loadout query over:

- WHAT item identity;
- 09 Hands;
- 11 Containment;
- 13D `ItemWeightQuery`;
- 13E `ActorCarryQuery`.

It preserves stable physical item IDs, reports hand slots, recursively reports actor-root/nested containment, exposes known weight where classified and explicit unknown weight otherwise, and reports the real carry result.

### `game/scripts/ui/CanonicalPlayerShell.gd`

CanvasLayer owner for:

- `STATS`, `INVENTORY`, `MENU` buttons;
- full-screen blocking modal overlay;
- Stats/Inventory/Menu presentation;
- hard-pause acquisition/restoration;
- Resume/Close;
- Leave Game presentation behavior.

It does not mutate actor/world/inventory/stat truth.

### Existing input/control owners

`PlayerActionIntent.gd` gains one semantic `STANCE_TOGGLE` intent.

`KeyboardInputAdapter.gd` may map C to that semantic intent and exposes an enable gate for modal blocking.

`DemoMovementControls.gd` may expose one Crouch/Stand touch button and an enable gate. It observes canonical locomotion state only to choose presentation text.

### Existing `DemoPlayerActionController.gd`

May widen from Movement-only coordination to navigation + existing stance-action coordination. It selects the existing Movement or Stance service, runs WHEN to the next stop, and reports the outcome. It owns no destination, collision, stance mutation, or timing rule.

### `CanonicalDemoMain.gd`

Composition only: construct/inject the new read/query owners, enroll Skills for the demo survivor, construct the existing stance service, and wire shell blocking to input enable gates.

## 6. Stance input contract

Semantic intent:

`STANCE_TOGGLE = player.stance_toggle`

Controller translation from canonical locomotion state:

- standing -> `request_crouch(actor_id)`;
- crouched -> `request_stand(actor_id)`.

Desktop:

- `C` emits exactly one stance-toggle intent.

Touch:

- one native Godot button below Turn Left;
- text is `CROUCH` while canonical stance is standing;
- text is `STAND` while canonical stance is crouched;
- one press emits exactly one stance-toggle intent.

Button text is presentation only and must follow `ActorLocomotionState`; it is never trusted as stance truth.

System 15 receives the resolved stance action and refreshes like other player actions.

## 7. Stats modal contract

Stats is read-only.

### Condition

- stance;
- HP current/max;
- fatigue;
- hunger;
- thirst;
- sleep pressure;
- carry current/capacity;
- derived moodlets.

### Injuries

Each real 13A injury shows:

- injury type;
- body region;
- Minor/Serious/Critical severity;
- stabilized state;
- treated state.

If none exist, display `None`.

### Skills

Enumerate the 13C catalog dynamically rather than hardcoding actor fields:

- Combat;
- Scavenging;
- Survival;
- Medical;
- Technical;
- Social;
- level;
- current XP / next threshold below max level;
- MAX at level 10.

The demo survivor is explicitly enrolled in 13C. Current level-0/XP-0 values are real canonical defaults.

Do not show traits, stress, temperature, infection or other domains until their owners exist.

## 8. Inventory modal contract

Inventory is read-only in System 16.

### Hands / Loadout

- Right Hand = primary/anatomical right;
- Left Hand = secondary/anatomical left.

### Carried Inventory

- actor-root direct contents;
- nested item-container contents recursively;
- deterministic stable-ID order from 11;
- stable item ID and semantic/readable identity remain visible in query truth.

No visual grouping may invent stacks or erase physical identity.

### Weight / Carry

- known 13D item weight is displayed;
- an unclassified profile displays `Weight: Unknown`, never zero;
- Carry uses the real 13E result.

Current itemless demo must show Empty hands/root inventory and real `0.0 / 18.0 kg` carry rather than starter gear.

No Move/Drop/Equip/Use actions are exposed in this slice.

## 9. Menu and hard-pause contract

Opening Stats, Inventory, or Menu acquires hard application pause.

On first transition from no modal to any modal:

1. capture whether WHEN was already hard paused;
2. call `set_hard_paused(true)`;
3. show the requested modal;
4. emit interaction blocking.

Switching directly among Stats/Inventory/Menu retains that same pause lifetime and does not recapture prior state.

On final Close/Resume:

- hide the modal;
- restore exactly the hard-pause state captured before the shell opened;
- unblock gameplay input exactly once.

This prevents the shell from accidentally unpausing a pause acquired by another owner.

### Input blocking

The modal overlay consumes pointer input, and keyboard/touch gameplay adapters are explicitly disabled while a modal is active. Main only wires the shell’s `interaction_blocked_changed` signal to those enable gates.

### Menu contents

- `RESUME`;
- `LEAVE GAME`.

### Leave Game

Web:

1. attempt browser history/back when a prior history entry exists;
2. otherwise navigate to Google as the approved safe fallback.

The implementation does not claim a web page can invoke Safari’s configured home page.

Native fallback may quit through normal Godot application behavior.

## 10. Layout / mobile requirements

- retain the existing 13x13 world view;
- System 15 exclusively owns the 568..632 HUD band;
- retain Forward/Back/Turn buttons;
- Crouch/Stand sits below Turn Left;
- Stats/Inventory/Menu use touch-sized native Buttons in the top/header area;
- the old decorative title may be removed to make room;
- modal uses a full-screen pointer-blocking overlay and scrollable content;
- no hover-only interactions;
- input is one physical press -> one semantic intent.

## 11. Public contracts

### Stats query

`query(actor_id: String) -> Dictionary`

Includes `ok/reason`, status summary, stance, injury entries and skill entries.

### Inventory query

`query(actor_id: String) -> Dictionary`

Includes `ok/reason`, primary/right hand, secondary/left hand, recursive actor-root inventory and carry result.

### Player shell

- `configure(kernel, stats_query, inventory_query, actor_id) -> bool`
- `interaction_blocked_changed(blocked)` signal
- `open_stats()`
- `open_inventory()`
- `open_menu()`
- `close_modal()`
- `active_modal() -> StringName`
- `presentation_snapshot() -> Dictionary`

### Input owners

Retain `action_intent(intent)` and add `set_enabled(enabled)` where required.

## 12. Failure / edge cases

- Missing Health/Needs/Skills/Carry truth => Stats reports unavailable, no default fabrication.
- Missing hand/root-container enrollment => Inventory reports unavailable, not assumed empty.
- Missing WHAT item referenced by 09/11 => explicit invalid/stale inventory entry.
- Containment traversal is bounded and cycle/duplicate guarded even though 11 normally prevents cycles.
- Missing item weight => explicit unknown weight.
- Direct modal switching does not overwrite the one prior-pause capture.
- Final close restores prior pause exactly once.
- Gameplay input is blocked while a modal is open.
- Leave Game does not mutate simulation truth.

## 13. Forbidden dependencies

New inspector/query/UI owners must not:

- call World/Health/Needs/Skills/Hands/Inventory mutation services;
- call System 12 transfer actions;
- implement movement, collision or stance-duration rules;
- import renderer/art selection;
- import Reboot;
- invent perception knowledge;
- invent item/stat values;
- use SceneTree pause as a substitute for WHEN hard pause.

The only WHEN interactions owned here are player-action coordination through the existing controller and hard application pause in the shell.

## 14. Acceptance tests

Dedicated System 16 CI must prove:

1. Godot 4.7.1 parses the project;
2. System 14 and 15 regressions remain green;
3. legacy help text and duplicate controls tick label remain absent;
4. C key and touch stance button each emit one semantic stance-toggle request;
5. standing -> crouched spends existing 4 stance ticks and commits real 03 state;
6. stance button then presents `STAND` from real locomotion observation;
7. crouched forward movement uses the existing 14-tick result;
8. crouched -> standing spends existing 4 stance ticks;
9. Stats shows real condition, stance, carry, moodlets and all six Skill records;
10. Stats shows no fake traits/stress/etc.;
11. Inventory shows real empty hands/root and 0/18 kg in the itemless demo;
12. synthetic nested containment exposes stable IDs recursively and unknown weights explicitly;
13. Stats/Inventory/Menu acquire hard pause and restore prior pause correctly;
14. direct modal switching does not recapture/unpause;
15. gameplay keyboard/touch input is blocked while modal active;
16. Menu exposes Resume and Leave Game;
17. inspector/query owners have no mutation/transfer/render/Reboot dependency;
18. exact-final-SHA startup, Web export and Pages deployment succeed.

## 15. Recovery sources

UX evidence only:

- golden Tick `MapPreview.gd` blob `8ef5d900e5f56bb557bba496d10acc47438b38de`: Crouch button, Menu/Resume, exit behavior;
- same-owner First Fire `FFInspector.gd` blob `8eed5e9d6f768c0d23350e99c79ad0c0844b18ff`: full-screen scrolling inspector and previous-pause restoration pattern.

Do not restore either monolithic architecture or nonexistent gameplay state.

## 16. Future seams

After System 16:

- loose-item presentation can make Inventory visibly nonempty without changing inspector ownership;
- System 12 UI may add pickup/drop/equip actions without moving possession truth into UI;
- System 10 held-item layers can be composed when the demo has real equipped items;
- future stat domains can extend Stats explicitly;
- browser/app lifecycle can acquire WHEN hard pause through a separate lifecycle owner;
- save/load remains independent of modal state.

## 17. North-star fit

System 16 turns the walking/HUD demo into a usable survival-game shell without fake mechanics. It exposes real stance cost, real actor condition, real physical inventory truth and real-life-safe hard pause through replaceable owners, fitting **Ultima-style turn-based mini Zomboid** and the rule that mini means reduced complexity rather than reduced consequence.

## 18. Approved decisions

Approved by the user on 2026-08-16:

1. Crouch/Stand + Stats + Inventory + Menu are one bounded integration system because their simulation owners already exist.
2. One semantic `STANCE_TOGGLE` intent maps current canonical stance to the existing System 03 crouch/stand action.
3. Stats is read-only: stance, HP, needs, carry, moodlets, injuries and six Skills only.
4. Inventory is read-only: Hands + actor-root/nested Containment + Carry; no pickup/drop/equip/use yet.
5. Any modal acquires WHEN hard pause and final close restores exact prior hard-pause state.
6. Modal UI blocks gameplay keyboard/touch input.
7. Web Leave Game tries browser history first and falls back to Google; no Safari-homepage claim.
8. System 15 remains the sole tick/action HUD surface; legacy help/action overlays remain removed.
