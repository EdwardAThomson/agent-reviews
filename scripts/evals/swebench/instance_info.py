#!/usr/bin/env python3
"""Print an instance's repo, base_commit, then problem_statement (for the
generic adapter). Usage: instance_info.py <instance_id> <dataset> <split>"""
import sys
from datasets import load_dataset

iid, dataset, split = sys.argv[1], sys.argv[2], sys.argv[3]
ds = load_dataset(dataset, split=split)
row = next((r for r in ds if r["instance_id"] == iid), None)
if row is None:
    sys.exit(f"instance not found: {iid}")
print(row["repo"])
print(row["base_commit"])
print(row["problem_statement"])
