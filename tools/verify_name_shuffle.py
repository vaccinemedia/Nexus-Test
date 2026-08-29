#!/usr/bin/env python3
"""Verify shuffle_subject_names by simulating the Z80 routine bit-for-bit.

Mirrors rng_tick (question.asm) and shuffle_subject_names (subjects.asm) so we
can prove the 32-entry order is always a permutation, that the 25 names a
playthrough consumes are therefore distinct, and that no name is grossly
over- or under-represented across seeds.
"""

COUNT = 32
LEVELS = 25
NAME_LEN = 12

NAMES = [
    "KIRA VOSS", "LEON WRAY", "YUKI TANAKA", "COLE MERCER",
    "REINA PARK", "DANA KENT", "ALEX DREEN", "NASH OTERI",
    "JUDE SEVRIN", "MIRA TYRELL", "ANJA HOLT", "SEV OKONKWO",
    "IRIS CHANDA", "MARCO REYES", "TESS LUND", "OMAR BEQUET",
    "LENA STROUD", "KAI SOLBERG", "NOOR HASSEL", "VIC ANSELM",
    "ESME KOVAL", "BRAM DELACY", "SUNI RAVAL", "HALE MORROW",
    "PIA LINDROS", "GIL ASTRAND", "ZOE HARKER", "IVO SALAZAR",
    "RUTH VANCE", "EDEN MARSH", "TOMA VESELY", "ADA CRANMER",
]


class Rng:
    """rng_tick: xorshift-ish 16-bit LCG hybrid, returns the low byte."""

    def __init__(self, seed):
        self.seed = seed & 0xFFFF

    def tick(self):
        hl = self.seed
        b = ((hl >> 8) ^ (hl & 0xFF)) & 0xFF
        hl = (hl * 8) & 0xFFFF          # three add hl,hl
        hl = (hl & 0xFF00) | (((hl & 0xFF) ^ b) & 0xFF)
        hl = (hl + 0x1597) & 0xFFFF
        self.seed = hl
        return hl & 0xFF


def shuffle(seed):
    """Fisher-Yates with the index reduced modulo i+1.

    Modulo, not re-rolling: the RNG has cycles that never land in range for
    small i, which would hang the Z80. See tools/check_rng_cycles.py.
    """
    rng = Rng(seed)
    order = list(range(COUNT))
    for i in range(COUNT - 1, 0, -1):
        j = rng.tick() % (i + 1)
        order[i], order[j] = order[j], order[i]
    return order


def main():
    # Name records must fit the fixed 12-byte slot (11 chars + terminator).
    assert len(NAMES) == COUNT, f"expected {COUNT} names, got {len(NAMES)}"
    too_long = [n for n in NAMES if len(n) + 1 > NAME_LEN]
    assert not too_long, f"names exceed {NAME_LEN - 1} chars: {too_long}"

    dupes = {n for n in NAMES if NAMES.count(n) > 1}
    assert not dupes, f"duplicate names in pool: {dupes}"

    # Exhaustively check every possible RNG seed.
    counts = [0] * COUNT
    first_slot_counts = [0] * COUNT
    for seed in range(0x10000):
        order = shuffle(seed)
        assert sorted(order) == list(range(COUNT)), \
            f"seed {seed:04X} produced a non-permutation: {order}"
        drawn = order[:LEVELS]
        assert len(set(drawn)) == LEVELS, \
            f"seed {seed:04X} repeats a name in 25 levels: {drawn}"
        for i in drawn:
            counts[i] += 1
        first_slot_counts[order[0]] += 1

    total = 0x10000
    print(f"Seeds checked: {total} (all 16-bit values)")
    print(f"Every order is a permutation of 0..{COUNT - 1}: OK")
    print(f"All {LEVELS} names drawn per playthrough are distinct: OK")

    # Each name should appear in the 25 drawn slots ~25/32 = 78.1% of the time.
    expected = total * LEVELS / COUNT
    worst = min(counts), max(counts)
    print(f"\nAppearance rate per name (ideal {LEVELS / COUNT:.1%}):")
    for i, n in enumerate(NAMES):
        print(f"  {n:<12} {counts[i] / total:6.2%}")
    spread = (worst[1] - worst[0]) / expected
    print(f"\nSpread between least and most common: {spread:.2%} of expected")
    assert spread < 0.05, "name selection is badly skewed"

    # Sanity check the level-1 name isn't stuck on a few values.
    zeros = [NAMES[i] for i, c in enumerate(first_slot_counts) if c == 0]
    print(f"Names that can open a game: {COUNT - len(zeros)} of {COUNT}")
    assert not zeros, f"these names can never appear at level 1: {zeros}"

    print("\nAll checks passed.")


if __name__ == "__main__":
    main()
