#!/usr/bin/env python3
"""Raw-model baseline: one API call, no tools, no agent loop. Establishes the
model's floor so harness value = (harnessed result) - (this).

Usage: run_baseline.py TASK_FILE OUT_DIR
Config via env:
  MODEL            default anthropic/claude-sonnet-4.6
  OPENROUTER_BASE  default https://openrouter.ai/api/v1
  OPENROUTER_API_KEY  taken from env, else parsed from ~/.hermes/.env

Writes OUT_DIR/response.md and OUT_DIR/usage.json. Extract the FILE: blocks
from response.md and run the produced tests yourself to score it.
"""
import os, json, time, sys
from pathlib import Path

MODEL = os.environ.get("MODEL", "anthropic/claude-sonnet-4.6")
BASE = os.environ.get("OPENROUTER_BASE", "https://openrouter.ai/api/v1")

key = os.environ.get("OPENROUTER_API_KEY")
if not key:
    envf = Path.home() / ".hermes" / ".env"
    if envf.exists():
        for line in envf.read_text().splitlines():
            if line.startswith("OPENROUTER_API_KEY="):
                key = line.split("=", 1)[1].strip()
assert key, "OPENROUTER_API_KEY not set (env or ~/.hermes/.env)"

from openai import OpenAI
client = OpenAI(base_url=BASE, api_key=key)

task = Path(sys.argv[1]).read_text()
sys_prompt = (
    "You are a coding assistant with NO tools and NO ability to run commands. "
    "Produce the COMPLETE solution in a single response. For EVERY file, output a fenced "
    "code block immediately preceded by a line of the exact form `FILE: <relative/path>` "
    "so files can be extracted programmatically. Include the pytest test file. "
    "Do not ask questions; make reasonable choices."
)

t0 = time.time()
resp = client.chat.completions.create(
    model=MODEL,
    messages=[{"role": "system", "content": sys_prompt}, {"role": "user", "content": task}],
    temperature=0,
)
t1 = time.time()

out = resp.choices[0].message.content or ""
u = resp.usage
pt, ct = u.prompt_tokens, u.completion_tokens
usage = {
    "duration_s": round(t1 - t0, 1),
    "api_calls": 1,
    "prompt_tokens": pt,
    "completion_tokens": ct,
    "total_tokens": u.total_tokens,
    "est_cost_usd": round(pt / 1e6 * 3 + ct / 1e6 * 15, 4),  # sonnet 4.6 $3/$15 per M; adjust per model
    "model": resp.model,
}
outdir = Path(sys.argv[2]); outdir.mkdir(parents=True, exist_ok=True)
(outdir / "response.md").write_text(out)
(outdir / "usage.json").write_text(json.dumps(usage, indent=2))
print(json.dumps(usage, indent=2))
print("response chars:", len(out))
