extends RefCounted
class_name AreaSeed

## Stable named sub-seeds keep unrelated System 20 stages isolated.

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

## Independent coordinate hashing for spatial noise. Unlike deriving separate
## string-domain X/Y values, both coordinates participate in one mixed value so
## the result has no preferred diagonal or axis.
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
