# Continuation Execution Guardrail

This file is an explicit hard guardrail for future coding sessions on Tick Lab.

## Do not re-investigate established state

When a coding prompt is a continuation of work already established in the current chat/context/handoff, treat that established state as authoritative.

Do **not** re-read broad repo documentation, rediscover architecture, repeat searches, retrace already-confirmed seams, or reconstruct already-known history just to regain confidence.

Only perform a targeted read when one of these is true:
- a specific compiler/import error names the file or symbol;
- a specific failing test names the implicated behavior;
- the remote head has changed unexpectedly;
- the established context is internally contradictory in a way that blocks the edit.

Otherwise: continue directly from the known checkpoint.

## Do not close before the requested coding prompt is complete

For an active code-change prompt, progress updates are not completion.

Do not end the response merely because several minutes or several tool calls have elapsed. Continue through the requested implementation, focused validation, push, exact-head verification, CI/Pages verification when applicable, and requested links/reporting.

If a true hard tool/session limit prevents completion, preserve the exact checkpoint and state only the concrete unfinished operations. Never voluntarily stop early after a few minutes while executable work remains.

## Avoid duplicate reads in one coherent prompt

For one coherent coding prompt:
- perform the required SOP/context refresh once at most;
- inspect each relevant source/test once at most before editing;
- after editing, read again only when a failure specifically requires it;
- do not search for information already present in the current conversation handoff/context.

## Tick Lab continuation rule

Current user expectation: execution time should be spent implementing and verifying, not repeatedly rediscovering already-settled architecture. When in doubt between re-checking an established fact and advancing the patch, advance the patch unless concrete evidence requires re-checking.
