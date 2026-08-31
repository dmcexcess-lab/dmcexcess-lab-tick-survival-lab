extends SceneTree

const FixtureClass = preload("res://scripts/demo/GeneratedIslandCritiqueFixture.gd")
const PowerTopologyPlannerClass = preload("res://scripts/simulation/utilities/UtilityLocalPowerTopologyPlanner.gd")

const SEEDS: Array[int] = [
    1,
    7,
    29,
    101,
    997,
    20001,
    28028,
    104729,
    524287,
    999983,
    123456789,
    2147483629,
]

var _failures: Array[String] = []

func _initialize() -> void:
    var seeds: Array[int] = SEEDS
    var requested_seed: String = OS.get_environment("TICK_LAB_PROCEDURAL_SEED")
    if not requested_seed.is_empty():
        seeds = [int(requested_seed)]

    for seed: int in seeds:
        _check_playable_seed(seed)

    if _failures.is_empty():
        print("PROCEDURAL_ISLAND_SEED_MATRIX_SMOKE_OK")
        quit(0)
        return
    for failure: String in _failures:
        push_error("PROCEDURAL_ISLAND_SEED_MATRIX_SMOKE_FAIL: %s" % failure)
    quit(1)

func _check_playable_seed(requested_seed: int) -> void:
    # Exercise the exact bounded resolver used by new-game boot. A merely valid
    # global plan is not enough: the candidate must survive central-area generation,
    # player-start selection, and initial streaming/materialization preflight.
    var resolved: Dictionary = FixtureClass._resolve_playable_boot(requested_seed)
    if not bool(resolved.get("ok", false)):
        _failures.append(
            "requested_seed=%d reason=%s"
            % [requested_seed, String(resolved.get("failure_reason", "playable_resolution_failed"))]
        )
        return

    var effective_seed: int = int(resolved.get("seed", -1))
    var global_plan: GeneratedGlobalWorldPlan = resolved.get("global_plan") as GeneratedGlobalWorldPlan
    var central_plan: GeneratedAreaPlan = resolved.get("central_plan") as GeneratedAreaPlan
    var player_start: Vector2i = resolved.get("player_start", Vector2i(-1, -1))

    if effective_seed <= 0:
        _failures.append("requested_seed=%d reason=invalid_effective_seed" % requested_seed)
        return
    if global_plan == null or not global_plan.is_generated():
        _failures.append("requested_seed=%d effective_seed=%d reason=invalid_global_plan" % [requested_seed, effective_seed])
        return
    if global_plan.seed != effective_seed:
        _failures.append(
            "requested_seed=%d effective_seed=%d plan_seed=%d reason=effective_seed_mismatch"
            % [requested_seed, effective_seed, global_plan.seed]
        )
        return
    if central_plan == null or not central_plan.is_generated():
        _failures.append("requested_seed=%d effective_seed=%d reason=invalid_central_area" % [requested_seed, effective_seed])
        return
    if player_start.x < 0 or not global_plan.bounds.has_point(player_start):
        _failures.append("requested_seed=%d effective_seed=%d reason=invalid_player_start" % [requested_seed, effective_seed])
        return

    # New-game readiness includes the full deterministic building manifest used
    # by streaming and physical utilities, not only the spawn neighborhood. This
    # catches remote local-area failures before they become a black first frame
    # in UtilityGameMain or a streaming failure later in play.
    var topology: Dictionary = PowerTopologyPlannerClass.new().plan(global_plan)
    if not bool(topology.get("ok", false)):
        _failures.append(
            "requested_seed=%d effective_seed=%d reason=utility_topology_failed:%s"
            % [requested_seed, effective_seed, String(topology.get("failure_reason", "unknown"))]
        )
        return
    if int(topology.get("building_count", 0)) <= 0 or (topology.get("substations", []) as Array).is_empty():
        _failures.append("requested_seed=%d effective_seed=%d reason=utility_topology_empty" % [requested_seed, effective_seed])
        return

    if effective_seed != requested_seed:
        print("PROCEDURAL_ISLAND_SEED_REROLLED requested=%d effective=%d" % [requested_seed, effective_seed])
    print(
        "PROCEDURAL_ISLAND_SEED_OK requested=%d effective=%d player_start=%s signature=%s"
        % [requested_seed, effective_seed, player_start, global_plan.signature()]
    )
