# Tick Survival Lab — Compatibility Context Pointer

Status: **legacy bootstrap pointer; not project working memory**

## Load order

1. README_SOPS.md — repository execution procedure;
2. AI_OPERATING_MODEL.md — reasoning/decision contract;
3. PROJECT_NORTH_STAR.md — game identity;
4. ARCHITECTURE.md — settled ownership/invariants;
5. ROADMAP.md — current rewrite order;
6. CURRENT.md — exact active state and NEXT.

Do not reconstruct current state from this file or old commits.

## Current pointer

CURRENT.md is canonical working memory.

As of 2026-09-27 the project direction deliberately changed from the experimental tick/WHERE/WHAT/WHEN execution model to a conventional turn-based survival game while preserving the existing procedural persistent world and gameplay content.

Slices 1-5 now establish the canonical simple turn spine for movement, combat, scavenging, inventory and survival: one player action, direct authoritative consequences, bounded sequential local infected actions, one ordinary survival-time advancement, immediate return of control, canonical Health/injury/corpse and condition/moodlet state, exact firearm state and exact loot/item/containment/equipment identity, with no TickKernel/WHEN/timed-transfer execution underneath the migrated routes.

The old execution architecture remains only as migration debt for bootstrap, durable-session compatibility and still-unmigrated gameplay routes. It is no longer protected project identity. The production MENU/save regression is repaired. The next rewrite slice reconnects contextual world/item interactions to the simple turn model.

The previous verbose contents remain available in Git history and must not be copied back into active context.
