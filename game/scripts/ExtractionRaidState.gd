extends RefCounted
class_name ExtractionRaidState

const MODE_BASE := "base"
const MODE_RAID := "raid"
const NO_REGION := Vector2i(-1, -1)

var mode: String = MODE_BASE
var raid_serial: int = 0
var active_region: Vector2i = NO_REGION
var active_raid_seed: int = 0
var last_raid_seed: int = 0
var deployments_by_region: Dictionary = {}
var extracts_completed: int = 0

func reset() -> void:
    mode = MODE_BASE
    raid_serial = 0
    active_region = NO_REGION
    active_raid_seed = 0
    last_raid_seed = 0
    deployments_by_region.clear()
    extracts_completed = 0

func at_base() -> bool:
    return mode == MODE_BASE

func raid_active() -> bool:
    return mode == MODE_RAID

func deployment_count(region: Vector2i) -> int:
    return int(deployments_by_region.get(region, 0))

func begin_raid(world_seed: int, region: Vector2i, site_seed: int) -> int:
    if raid_active():
        return 0
    raid_serial += 1
    var visit: int = deployment_count(region) + 1
    deployments_by_region[region] = visit
    active_region = region
    active_raid_seed = derive_raid_seed(world_seed, site_seed, region, visit)
    last_raid_seed = active_raid_seed
    mode = MODE_RAID
    return active_raid_seed

func extract_to_base() -> bool:
    if not raid_active():
        return false
    extracts_completed += 1
    active_region = NO_REGION
    active_raid_seed = 0
    mode = MODE_BASE
    return true

static func derive_raid_seed(world_seed: int, site_seed: int, region: Vector2i, visit: int) -> int:
    var mixed: int = world_seed * 1103515245
    mixed += site_seed * 69069
    mixed += (region.x + 17) * 374761393
    mixed += (region.y + 31) * 668265263
    mixed += maxi(1, visit) * 1274126177
    mixed = mixed ^ (mixed >> 13)
    mixed = mixed ^ (mixed << 7)
    return 1 + posmod(mixed, 2147483000)
