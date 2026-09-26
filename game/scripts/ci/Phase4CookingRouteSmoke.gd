extends SceneTree

# Prompt-local Phase 4 verifier. Production assertions are filled in with the slice;
# this file exists before production edits per README_SOPS.md.
func _initialize() -> void:
    print("PHASE4_COOKING_ROUTE_VERIFIER_BOOTSTRAPPED")
    quit(0)
