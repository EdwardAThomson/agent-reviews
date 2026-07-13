#!/usr/bin/env python3
"""Gate a SWE-bench evaluation report: hard-stop on silent-failure signatures.

The whole point is to NOT discover a broken run 20 (or 100) instances deep.
Run this on every harness's report before accepting the result.

Usage: gate.py REPORT.json [--max-empty-frac 0.5] [--max-error-frac 0.2]
Exit codes: 0 = pass, 3 = gate tripped, 2 = bad report file.
"""
import json, sys, argparse


def main():
    p = argparse.ArgumentParser()
    p.add_argument("report")
    p.add_argument("--max-empty-frac", type=float, default=0.5,
                   help="max fraction of empty patches before tripping (default 0.5)")
    p.add_argument("--max-error-frac", type=float, default=0.2,
                   help="max fraction of errored instances before tripping (default 0.2)")
    a = p.parse_args()

    try:
        d = json.load(open(a.report))
    except Exception as e:
        print(f"cannot read report {a.report}: {e}", file=sys.stderr)
        sys.exit(2)

    # NOTE: swebench's `submitted_instances` is the whole dataset size, not our
    # slice — use `total_instances` (the instances we actually asked for).
    tot = d.get("total_instances") or d.get("completed_instances") or 0
    comp = d.get("completed_instances", 0)
    res = d.get("resolved_instances", 0)
    empty = d.get("empty_patch_instances", 0)
    err = d.get("error_instances", 0)

    print(f"total={tot} completed={comp} resolved={res} empty={empty} error={err}")

    fails = []
    if tot == 0:
        fails.append("no instances in report")
    if comp < tot:
        fails.append(f"incomplete: {comp}/{tot} completed (a run died mid-way)")
    if tot and empty / tot > a.max_empty_frac:
        fails.append(f"empty-patch rate {empty}/{tot} > {a.max_empty_frac:.0%} "
                     f"(agent likely not editing code / misconfigured)")
    if tot and err / tot > a.max_error_frac:
        fails.append(f"error rate {err}/{tot} > {a.max_error_frac:.0%} "
                     f"(systematic API/auth/docker failure)")

    if fails:
        print("GATE TRIPPED — do not proceed:")
        for f in fails:
            print("  -", f)
        sys.exit(3)

    # resolved==0 is allowed (hard tasks) but worth surfacing.
    note = "" if res else "  (note: 0 resolved — fine if expected, suspicious if not)"
    print("GATE PASS ✓" + note)


if __name__ == "__main__":
    main()
