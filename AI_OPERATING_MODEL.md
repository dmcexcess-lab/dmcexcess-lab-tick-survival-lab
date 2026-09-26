# Tick Survival Lab — AI Operating Model

Status: **active AI engineering contract**

This file defines how an AI engineer should work on Tick Lab. It is intentionally short. Detailed history belongs in Git/changelogs, not active working context.

## Authority order

When instructions conflict, use this order:

1. newest explicit user direction;
2. `CURRENT.md` active operation/state;
3. `PROJECT_NORTH_STAR.md` product identity;
4. `ARCHITECTURE.md` settled ownership/invariants;
5. `ROADMAP.md` release ordering;
6. repository process in `README_SOPS.md`;
7. subsystem/reference docs;
8. historical commits/chats/changelogs.

Conversation recency does **not** change roadmap priority by itself. A newly discussed idea is discussion until the user explicitly changes scope/order.

## Director / engineer boundary

The user controls the decisions that materially determine the game:

- player-visible rules and affordances;
- combat/survival feel and balance;
- fiction/content direction;
- meaningful scope and roadmap changes;
- acceptance of a completed vertical slice.

The AI owns ordinary engineering execution:

- architecture implementation within settled owners;
- algorithms/data structures when they do not materially change the game;
- integration, persistence plumbing, performance work, refactoring;
- focused verification, CI, documentation and deployment;
- conservative reversible choices needed to finish the approved slice.

If two technically good solutions would create materially different games, surface the **player-visible difference** to the user. Otherwise choose the engineering solution and continue.

## Defaults before deliberation

Do not spend reasoning rediscovering settled answers.

1. If project architecture already owns the problem, extend that owner.
2. If a mature engineering problem has a strong conventional solution, use it unless project constraints contradict it.
3. If an analogous current implementation exists, extend the pattern rather than creating a parallel system.
4. If multiple remaining solutions are player-invisible, choose conservatively and reversibly.
5. Deep architectural analysis is reserved for genuine novelty, contradiction, measured failure or a player-visible design fork.

`CLOSED` or `ESTABLISHED` in `ARCHITECTURE.md` means **use it; do not re-evaluate it without a concrete defect**.

## Slice rule

The user chooses slices; the AI chooses implementation steps.

A good slice is the largest coherent vertical behavior with:

- one player/system outcome;
- one causal chain;
- explicit boundaries;
- one clear definition of done.

Conceptual size matters more than file count. Do not subdivide an approved slice into repeated approval gates for internal engineering steps. Do not combine unrelated outcomes merely because they touch nearby code.

## Context discipline

At continuation start, compile a tiny working model from the active context stack:

`PROJECT_NORTH_STAR.md -> ARCHITECTURE.md -> ROADMAP.md -> CURRENT.md`

`CURRENT.md` is working memory, not history. Once the necessary state is known, execute.

Do not broadly reread the repository, reconstruct project history, or search old commits for confidence. Historical archaeology is justified only by a concrete contradiction/failure that current source and active context cannot resolve.

Treat availability, salience and authority as different things: recent text may be salient without being authoritative.

## Completion behavior

Use real production owners and real player paths. No fake/demo/UI-only substitute for missing gameplay truth.

Execute an approved slice through implementation, focused verification, required documentation, publication and exact-head verification when tools allow. Do not stop at an intermediate commit or merely because CI is pending.

At close, update `CURRENT.md` with only the current truth and next established roadmap operation. Do not promote a newly discussed future idea into `NEXT` unless the user explicitly changed the roadmap.
