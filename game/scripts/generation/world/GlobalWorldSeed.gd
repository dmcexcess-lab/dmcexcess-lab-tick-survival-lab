extends RefCounted
class_name GlobalWorldSeed

## Stable named sub-seeds for System 00D. Global planning must not depend on
## call-order consumption from one shared RNG.

const HASH_MASK: int = 0x7fffffff

static func derive(base_seed: int, domain: String) -> int:
    var value: int = base_seed & HASH_MASK
    for index in range(domain.length()):
        value = int((value * 1103515245 + domain.unicode_at(index) + 12345) & HASH_MASK)
    return value

static func choose_index(base_seed: int, domain: String, count: int) -> int:
    if count <= 0:
        return -1
    return derive(base_seed, domain) % count

static func choose_inclusive(base_seed: int, domain: String, minimum: int, maximum: int) -> int:
    if maximum < minimum:
        return minimum
    var span: int = maximum - minimum + 1
    return minimum + choose_index(base_seed, domain, span)

## Mixed-coordinate deterministic sampling for coarse global geography. Both
## coordinates participate in one hash so elevation fields do not inherit the
## directional correlation problem previously found in local environmental noise.
static func hash_2d(base_seed: int, x: int, y: int, salt: int = 0) -> int:
    var x_bits: int = x & HASH_MASK
    var y_bits: int = y & HASH_MASK
    var value: int = (base_seed & HASH_MASK) ^ (salt & HASH_MASK)
    value = (value ^ ((x_bits * 374761393) & HASH_MASK)) & HASH_MASK
    value = (value ^ ((y_bits * 668265263) & HASH_MASK)) & HASH_MASK
    value = (value ^ (value >> 13)) & HASH_MASK
    value = (value * 1274126177) & HASH_MASK
    value = (value ^ (value >> 16)) & HASH_MASK
    return value

static func unit_2d(base_seed: int, x: int, y: int, salt: int = 0) -> float:
    return float(hash_2d(base_seed, x, y, salt)) / float(HASH_MASK)
