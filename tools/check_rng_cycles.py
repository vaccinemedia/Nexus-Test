#!/usr/bin/env python3
"""Show why shuffle_subject_names must not pick its index by re-rolling.

The tempting way to get a Fisher-Yates index in 0..i is to draw rng_tick,
mask to 0..31, and re-roll anything above i. This walks the RNG's entire
state graph to show that rng_tick contains closed cycles which never produce
a value <= 1, so that loop would hang the Spectrum at game start. Hence the
routine reduces modulo i+1 instead, which always terminates.

Exits 0 when the hazard is confirmed to exist (i.e. the modulo approach is
still required), and 1 if the RNG ever changes such that it is safe.
"""

MASK = 31


def tick(seed):
    hl = seed & 0xFFFF
    b = ((hl >> 8) ^ (hl & 0xFF)) & 0xFF
    hl = (hl * 8) & 0xFFFF
    hl = (hl & 0xFF00) | (((hl & 0xFF) ^ b) & 0xFF)
    hl = (hl + 0x1597) & 0xFFFF
    return hl


def main():
    nxt = [tick(s) for s in range(0x10000)]
    out = [nxt[s] & MASK for s in range(0x10000)]

    print("Simulating a re-roll loop at each Fisher-Yates threshold i.")
    print("(i = 1 is the tightest: only draws of 0 or 1 would be accepted)\n")

    worst_overall = 0
    hazard_found = False
    for i in (1, 2, 3, 7, 15, 31):
        # run[s] = draws needed, starting from state s, to hit a value <= i.
        # Solved by walking each chain with memoisation; a cycle with no
        # acceptable value would leave states unresolved.
        run = [None] * 0x10000
        for start in range(0x10000):
            if run[start] is not None:
                continue
            chain = []
            s = start
            while run[s] is None and s not in chain:
                chain.append(s)
                if out[s] <= i:
                    break
                s = nxt[s]

            if run[s] is not None:
                tail = run[s]
            elif out[s] <= i:
                run[s] = 1
                tail = 1
                if chain and chain[-1] == s:
                    chain.pop()
            else:
                # Closed cycle with no acceptable draw: the Z80 would hang.
                print(f"  i={i:<2} accepts {i + 1:>2}/32 of draws   "
                      f"HANGS: cycle from state {s:04X} never accepts")
                hazard_found = True
                break

            for s2 in reversed(chain):
                tail += 1
                run[s2] = tail
        else:
            mx = max(run)
            worst_overall = max(worst_overall, mx)
            print(f"  i={i:<2} accepts {i + 1:>2}/32 of draws   "
                  f"worst case {mx:>3} draws   (expected {32 / (i + 1):.1f})")

    if hazard_found:
        print("\nConfirmed: re-rolling can wedge forever on this RNG.")
        print("shuffle_subject_names must keep reducing modulo i+1.")
        return 0

    print("\nNo unescapable cycles at any threshold.")
    print(f"Worst single wait: {worst_overall} RNG calls.")
    print("The RNG has changed; re-rolling would now be safe.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
