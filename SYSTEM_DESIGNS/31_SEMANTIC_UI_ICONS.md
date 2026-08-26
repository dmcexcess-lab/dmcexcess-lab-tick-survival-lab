# Tick Survival Lab — System 31 Semantic UI Icons

Status: **IMPLEMENTED + CI VERIFIED — Candidate 001; Roadmap Phase 1C complete**

Roadmap role: **Phase 1C — Semantic inventory/menu icons**.

Core rule:

> **UI icons visualize existing semantic truth. They never define item identity, utility, freshness, or action legality.**

---

## 1. Goal

Make the phone-first inventory/scavenging shell faster to read without turning pictures into gameplay authority or hiding useful text.

Candidate 001 adds a small low-resolution semantic icon vocabulary for:

- the core `STATS`, `INVENTORY`, and `MENU` shell controls;
- occupied hand/loadout entries;
- carried inventory entries;
- scavenged-container contents;
- the player's `YOUR PACK` rows inside the scavenging panel.

Icons supplement labels. They do not replace labels.

The result should feel like the same low-resolution Ultima-style game rather than a modern high-resolution icon pack pasted over it.

---

## 2. Current implementation truth recovered before design

Current `main` before this draft:

`8abdce79133003a776fdc3de33f7b395654a215f`

Relevant current presentation facts:

- canonical viewport is `640x844`;
- `CanonicalPlayerShell` currently creates text-only `STATS`, `INVENTORY`, and `MENU` header buttons;
- its Inventory modal renders hands and carried items as text rows;
- `LootContainerPanel` renders container contents and `YOUR PACK` as text rows plus existing `TAKE` / `STORE` buttons;
- `ActorInventoryInspectorQuery` already exposes stable `item_id`, real `semantic_type`, weight truth, nested containment and optional System-30 freshness enrichment;
- `LootContainerInspectionQuery` already exposes real `semantic_type`, label, utility class, family, tags, weight and optional freshness enrichment;
- `LootItemCatalog` Candidate 001 / catalog version 2 currently defines **71** deterministic loot semantic types: 51 usable items and 20 junk items;
- System 10 already contains a small same-owner recovered held-item atlas for several silhouettes such as knife, hammer, crowbar and flashlight, but that atlas is world/held-item presentation, not a general UI contract.

Therefore 1C does not need new gameplay data. The semantic keys needed for icon lookup already exist in the current read-only presentation results.

---

## 3. Ownership

System 31 owns only presentation concerns:

- one dedicated low-resolution UI icon atlas;
- deterministic semantic-to-glyph mapping;
- cached atlas-region texture lookup;
- explicit shell-control icon keys;
- an honest unknown/unmapped diagnostic glyph;
- icon placement inside existing player-facing UI surfaces;
- CI coverage proving all currently supported loot semantics have intentional icon mappings.

System 31 does **not** own:

- WHAT item identity;
- System 11 containment;
- System 12 TAKE / STORE / equip / transfer legality or timing;
- System 13D weight;
- System 24 loot existence, utility class, family, tags or labels;
- System 30 freshness state or freshness labels;
- held-item world rendering;
- world prop art;
- any crafting/use capability;
- button/action legality;
- inventory quantity/stack semantics;
- persistent state or save data.

No mechanic reads an icon to learn what an item is.

---

## 4. Why this is a separate presentation system

Do not put UI icon identity into WHAT metadata or `LootItemCatalog` definitions merely because both are keyed by semantic type.

The same physical item truth may later be shown in several visual languages:

- world loose-item art;
- held-item art;
- inventory UI icon;
- crafting-recipe icon;
- accessibility/list presentation.

Those presentations have independent reasons to change.

System 31 therefore owns the UI vocabulary as a peer presentation layer rather than making System 24 or WHAT depend on art.

The existing System-04 recovered art catalog is also not expanded into a giant all-purpose gameplay/UI registry. System 31 may reuse visual provenance where appropriate, but runtime UI lookup remains a focused UI contract.

---

## 5. Candidate 001 public contract

Proposed owner:

`SemanticUiIconCatalog`

It is a Node-free presentation catalog constructed once and shared by UI consumers.

Candidate public surface:

- `has_icon(semantic_key: StringName) -> bool`
- `icon_key(semantic_key: StringName) -> StringName`
- `texture_for(semantic_key: StringName) -> Texture2D`
- `region_for(semantic_key: StringName) -> Rect2i`
- `known_semantics() -> Array[StringName]`
- `diagnostic_reason(semantic_key: StringName) -> String`

Semantic namespaces:

- item truth uses the existing exact `item.*` semantic type;
- shell controls use presentation-only keys such as `ui.shell.stats`, `ui.shell.inventory`, and `ui.shell.menu`.

The catalog may internally map many semantic keys to one shared glyph key.

Example:

- `item.food.canned_beans` -> `glyph.food.canned`
- `item.food.canned_soup` -> `glyph.food.canned`

That sharing is explicit and intentional. Runtime code does not guess an icon from string fragments.

---

## 6. No automatic family fallback

Candidate 001 deliberately does **not** say:

`if family == food, draw generic food`.

Every currently supported `LootItemCatalog.semantic_types()` entry receives an explicit mapping, even when several mappings intentionally point to the same glyph.

Reasons:

- adding a new item should not silently look supported merely because it happened to share a family;
- an explicit mapping makes visual sharing a deliberate design choice rather than accidental fallback;
- CI can prove current content coverage exactly;
- future Phase-1E content additions get an obvious icon-coverage obligation.

Unknown future item semantics return a visible `unknown_item` question-mark/package glyph plus a diagnostic result. Text remains present, so a missing icon never makes the item unusable or invisible.

Current canonical content must have zero unknown mappings after implementation.

---

## 7. Atlas geometry and pixel language

Candidate 001 uses one dedicated asset:

`game/assets/ui_icon_atlas.svg`

Logical icon cell:

- **16 x 16 pixels**.

Normal game draw size:

- **32 x 32 screen pixels** — exact 2x integer scale.

Candidate atlas grid:

- 16 columns;
- 8 rows;
- 128 available glyph cells;
- logical atlas size `256 x 128`.

Unused cells are simply reserved space; they do not create supported semantics.

Rendering rules:

- nearest-neighbor filtering;
- integer-positioned icon rectangles where practical;
- no smooth scaling between 16 and 32;
- no animation in Candidate 001;
- no gradients required for semantic readability;
- silhouette/shape must remain distinguishable without relying only on color;
- small internal detail is subordinate to recognizability at 32 x 32.

The atlas may be authored as SVG for repository maintainability, but the shapes themselves should obey a deliberately pixel-like 16x16 logical grid.

---

## 8. Candidate glyph vocabulary

The current 71 loot semantics do **not** require 71 unrelated drawings. Intentional sharing is part of the design.

### Food / drink

Separate readable glyphs for:

- water bottle;
- soda can;
- juice bottle;
- canned food — shared by canned beans / canned soup;
- crackers;
- cereal box;
- energy bar;
- apple;
- milk carton;
- raw meat package;
- berries;
- bread loaf;
- cheese block.

### Kitchen

- can opener;
- kitchen knife;
- frying pan;
- cooking pot;
- matches.

### Medical

- bandage/gauze — intentionally shared;
- disinfectant;
- medicine/pills — painkillers and antibiotics intentionally share the base pill-bottle glyph;
- first-aid kit.

### Tools

- hammer;
- screwdriver;
- adjustable wrench;
- crowbar;
- flashlight;
- lighter.

### Farming

- hand trowel;
- hand pruners;
- garden hoe;
- watering can;
- seed packet.

### Construction / material

- duct tape;
- fastener box — nails/screws intentionally shared;
- rag bundle;
- rope coil.

### Electrical / household / sanitation

- battery pack;
- trash-bag roll;
- soap bar;
- bleach/cleaner bottle.

### Other first-pass usable families

- notebook;
- permanent marker;
- work gloves;
- tarp;
- jumper cables;
- portable work light.

### Junk

Junk remains visually identifiable rather than collapsing to one garbage-can icon. Candidate shared junk silhouettes include:

- empty can;
- empty bottle — plastic/cleaner bottles may share;
- broken ceramic — mug/plant-pot variants may share;
- paper/package trash — wrapper/medical packaging/receipts/cardboard may share;
- empty medicine bottle;
- used mask;
- broken hand tool;
- rusted fasteners;
- empty seed packet;
- dead battery pack;
- broken pen;
- scrap wire;
- dirty rag;
- cracked charger;
- broken toy.

The exact atlas-cell indices are implementation detail after approval, but every current semantic must be represented by an explicit mapping table and covered by CI.

---

## 9. Reusing held-item silhouettes

Current System 10 contains recovered same-owner silhouettes that already read well at small scale.

Where they genuinely fit — currently especially:

- kitchen knife;
- hammer;
- crowbar;
- flashlight;

Candidate 001 may **visually reuse/repack** those exact silhouettes into the dedicated UI atlas with provenance documented.

Runtime System 31 should not reach through System 10's renderer or depend on hand-equipment state merely to draw an inventory icon.

This keeps one UI atlas hot and keeps held-item presentation independently replaceable.

No reuse is mandatory when the world-held silhouette looks poor as a square UI symbol.

---

## 10. Shell-control integration

`CanonicalPlayerShell` keeps the existing three real controls and callbacks:

- `STATS`;
- `INVENTORY`;
- `MENU`.

Candidate 001 adds dedicated 32x32 icons **beside the existing text**, not icon-only buttons.

Suggested visual concepts:

- Stats: survivor/bust/status silhouette;
- Inventory: backpack/pack;
- Menu: simple menu/pause-bars symbol.

Existing button action ownership and hard-pause behavior remain unchanged.

Text labels remain because:

- they remove ambiguity on first use;
- they improve accessibility;
- the current 640x844 layout has enough width;
- Phase 9 can later decide whether any control becomes icon-only after real usability testing.

Candidate 001 does not redesign the movement controls or Weather DEV controls.

---

## 11. Inventory-modal integration

The current System-16 Inventory surface stays read-only.

Occupied hand/loadout rows:

- 32x32 item icon;
- existing hand label;
- existing item label / identity text;
- existing weight/freshness text remains real query output.

Carried inventory rows:

- 32x32 semantic item icon at left;
- existing text to the right;
- nested containment indentation remains readable and still derives from System 11 traversal;
- icon presence does not flatten or invent stacks.

Empty hands / empty inventory remain honest empty states. No fake placeholder item is drawn.

The stable item ID currently present in System-16 text is not removed by this slice merely to make the UI prettier. Removing or hiding DEV-ish identity text is a separate UI-policy decision and can be revisited in Phase 9.

---

## 12. Scavenging-panel integration

`LootContainerPanel` uses the same shared System-31 catalog.

For both:

- `CONTENTS`;
- `YOUR PACK`;

each item row gains the same 32x32 semantic icon used by the Inventory modal.

Existing text remains:

- utility class;
- family;
- item label;
- freshness suffix when applicable;
- weight.

Existing `TAKE` / `STORE` buttons remain text buttons in Candidate 001 and retain exactly the current System-12 timing/legality path.

Why not iconize TAKE/STORE now:

- 1C's requested problem is semantic inventory/menu readability;
- action-symbol vocabulary is a separate usability concern;
- text TAKE/STORE is already unambiguous on phone;
- Phase 9 will eventually audit every player-facing control.

---

## 13. Freshness relationship

System 30 remains authoritative for freshness.

Candidate 001 does not create:

- green/fresh item variants;
- rotten-item replacement icons;
- animated spoilage overlays;
- icon-driven freshness rules.

The current coarse `FRESH / AGING / STALE / SPOILED` text remains beside the item.

A future tiny status badge/overlay may be added if phone playtesting shows it improves scanning, but that badge would still be derived from System-30 query truth and remain outside the base semantic icon identity.

This avoids multiplying atlas entries for every item x freshness state.

---

## 14. Presentation/query boundary

Do not add `icon_key` fields to WHAT, System 24 loot state, System 30 records, or the canonical item mechanic queries.

Existing presentation results already expose `semantic_type`.

Candidate integration pattern:

1. inventory/loot query returns real semantic/mechanic truth;
2. UI row reads `semantic_type`;
3. UI asks System 31 for an icon;
4. icon is drawn beside the unchanged textual truth.

`ActorInventoryInspectorQuery` and `LootContainerInspectionQuery` therefore require no semantic contract change merely to support icons.

If implementation discovers a small read-only presentation convenience is genuinely needed, it must remain additive and must not make simulation owners depend on System 31.

---

## 15. Texture/cache behavior

One `SemanticUiIconCatalog` instance is shared by the live composition.

Candidate implementation may:

- load the atlas texture once;
- cache one `AtlasTexture`/region texture per glyph key on first use;
- reuse those cached textures across all visible rows/buttons.

It should not:

- reload the SVG for every row;
- allocate a new texture every render refresh when an identical glyph is already cached;
- create one persistent icon object per physical world item;
- scan all items in the world to prepare an icon cache.

Only currently displayed UI rows request textures.

---

## 16. Performance contract

### While inventory/scavenging UI is closed

**Zero recurring System-31 work.**

### Per render frame

No System-31 `_process` / polling / animation loop.

### Per simulation tick

Zero work. Icons do not care that WHEN advanced.

### Per persistent item

Zero persistent Node/timer/icon state.

### On UI open/refresh

O(number of rows actually displayed), using O(1) semantic lookup and cached atlas-region textures.

There is no world scan and no catalog-wide redraw merely because one item's freshness changed.

### Streaming

Zero work unless streamed truth becomes an item row that the user actually opens/inspects.

This preserves the project's deliberate low-resolution/turn-based performance advantage.

---

## 17. Failure behavior

The game must remain usable if icon presentation fails.

Unknown semantic mapping:

- show the explicit unknown glyph;
- keep the real text label/semantic data;
- expose a diagnostic reason;
- CI must fail if the unknown semantic is part of current `LootItemCatalog` canonical content.

Atlas load/region failure:

- text still renders;
- buttons/actions still work;
- no gameplay mutation is blocked merely because art is unavailable.

A missing icon is a presentation defect, not missing item truth.

---

## 18. Accessibility/readability requirements

Candidate 001 should be usable on the current 640x844 phone-oriented viewport.

Rules:

- icon shape is the primary identifier; color is supplemental;
- item text remains visible;
- core shell controls remain icon + text;
- 32x32 icon draw size should not require precision tapping because icons themselves are not separate click targets;
- icons inherit the parent row/button interaction area rather than creating tiny independent controls;
- nearest-neighbor output must remain crisp on Safari/WebGL compatibility rendering;
- unknown/failure states remain readable as text even if texture import behaves unexpectedly.

---

## 19. Phase-1E and later content seam

When Phase 1E adds a new canonical loot semantic, the content change must also choose an intentional System-31 mapping.

It may:

- reuse an existing glyph intentionally;
- add a new glyph to a reserved atlas cell.

It must not rely on accidental family fallback.

Later consumers can reuse the same catalog:

- Phase 2 crafting recipe lists;
- Phase 4 food/medical action menus;
- Phase 6 broader item interactions;
- Phase 7 vehicle inventory/cargo;
- Phase 9 final inventory/UI overhaul.

Those consumers still read their own mechanic truth. System 31 supplies only the base semantic icon.

Phase 9 may replace/redraw the entire atlas without migrating any save or simulation state.

---

## 20. Implemented modules

Candidate 001 implementation set:

- `game/assets/ui_icon_atlas.svg`;
- `game/scripts/ui/icons/SemanticUiIconCatalog.gd`;
- focused integration in `game/scripts/ui/CanonicalPlayerShell.gd`;
- focused integration in `game/scripts/ui/LootContainerPanel.gd`;
- live composition injection of one shared icon catalog;
- `game/scripts/ci/SemanticUiIconsSmoke.gd`;
- `.github/workflows/semantic-ui-icons.yml`.

Do not create one script per icon, one resource per item, or a persistent icon Node per world entity.

If implementation can keep the atlas-region caching/private helper logic inside `SemanticUiIconCatalog.gd`, do so rather than fragmenting the module.

---

## 21. Verification plan

A dedicated System-31 smoke/contract should prove at minimum:

1. core shell keys `ui.shell.stats`, `ui.shell.inventory`, `ui.shell.menu` resolve to valid atlas regions;
2. every current `LootItemCatalog.semantic_types()` entry resolves intentionally;
3. current coverage count equals the full catalog count — currently 71 semantics;
4. shared-glyph mappings are deterministic and explicit;
5. an unknown future `item.*` semantic returns the unknown glyph plus diagnostic rather than silently pretending to be covered;
6. all mapped atlas indices/regions are inside the declared atlas grid;
7. repeated requests for the same glyph reuse cached texture data rather than recreating it unnecessarily;
8. inventory-query semantic/weight/freshness output is unchanged by icon lookup;
9. loot-container semantic/utility/family/weight/freshness output is unchanged;
10. opening/rendering iconized inventory advances zero WHEN ticks beyond existing modal behavior;
11. scavenging TAKE/STORE still follow the existing System-12 action path and timings;
12. icon presentation never mutates WHAT, containment, loot or freshness state;
13. canonical startup imports the atlas/catalog successfully;
14. phone-sized header/item rows fit the 640x844 fixture without removing text labels;
15. unknown/missing art degrades to text rather than blocking interaction.

Protected regression targets during implementation:

- System 16 player shell;
- System 24 loot/scavenging;
- System 30 freshness readout;
- canonical startup;
- Pages deployment.

Permanent exact-head context:

`verify/system31-semantic-ui-icons`

The required context count is 17.

---

## 22. Protected neighboring modules during implementation

Implementation must not rewrite:

- WHERE / WHAT / WHEN;
- System 11 containment;
- System 12 transfer semantics/timing;
- System 13D weight;
- System 24 loot tables/probabilities/search semantics;
- System 30 freshness math/state;
- System 04 world-art ownership;
- System 10 hand-equipment state/presentation behavior;
- System 29 reach/highlight truth;
- world generation/streaming;
- Weather/Lighting/Perception.

Narrow composition injection and focused UI-row changes are allowed by this design after approval.

---

## 23. Candidate 001 approval decisions

The following are the implemented Candidate 001 contract:

1. Phase 1C is System 31, a **presentation-only semantic UI icon system**.
2. Core rule: **UI icons visualize existing semantic truth; they never define it.**
3. Candidate 001 uses one dedicated `ui_icon_atlas.svg` with 16x16 logical icon cells normally displayed at exact 2x / 32x32.
4. `SemanticUiIconCatalog` is Node-free, shared, O(1)-lookup and caches atlas-region textures.
5. Every current `LootItemCatalog` semantic receives an explicit mapping; there is no automatic family fallback.
6. Multiple semantics may intentionally share one glyph.
7. Unknown future semantics use an explicit unknown glyph + diagnostic while text remains usable.
8. Header `STATS` / `INVENTORY` / `MENU` become **icon + text**, not icon-only.
9. Inventory hands/carried rows and scavenging `CONTENTS` / `YOUR PACK` rows receive the same 32x32 item icons.
10. `TAKE` / `STORE`, movement controls and DEV controls stay text-only in Candidate 001.
11. Existing item labels, stable IDs, weight, utility/family and System-30 freshness text remain real data beside the icon.
12. Freshness does not multiply base icon variants; any future freshness badge remains derived presentation.
13. Existing mechanic queries remain semantic/mechanic owners and do not store icon identity.
14. Candidate 001 adds no persistent state, save schema, simulation tick work, per-item Node/timer/process or world scan.
15. Selected System-10 silhouettes may be visually repacked into the UI atlas with provenance, but System 31 has no runtime dependency on hand-equipment presentation.
16. Implementation receives its own `verify/system31-semantic-ui-icons` context and proves complete current catalog coverage.

---

## 24. Lifecycle

Current lifecycle state:

**DESCRIBE — COMPLETE -> APPROVE — COMPLETE -> IMPLEMENT — COMPLETE -> VERIFY — COMPLETE**

Current verified executable:

`dc83ad10b7469a629fb2ac5d86c77d386b69434d`

All 17 required exact-head contexts are green, including `verify/system31-semantic-ui-icons` and `verify/pages-deploy`.

No separate human visual-acceptance claim is recorded for the post-width-fix appearance.
