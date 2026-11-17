#!/usr/bin/env python3
"""Surface the Hindsight memory context that the recall hook injected.

The `hindsight-memory` plugin's recall.py hook runs on every
UserPromptSubmit, recalls from the memory bank, injects a
<hindsight_memories> block into the prompt as additionalContext, and
persists that block to last_recall.json. That injected context is easy
to miss because it's fused silently into the prompt — this script reads
the persisted copy and presents it legibly, plus a staleness check.

Staleness is the useful signal: recall.py rewrites last_recall.json on
EVERY prompt, so a fresh file (saved seconds ago) means the hook is
live. An old saved_at means the hook didn't fire this turn — usually
because the Hindsight server is down or the plugin is disabled — which
is the reminder the user wants ("did I forget to start Hindsight?").

Usage:
    python3 hindsight_context.py [--stale-minutes N] [--full]

Exits 0 always (this is a reporting tool; never block the caller).
"""

import argparse
import datetime as dt
import glob
import json
import os
import sys


def find_recall_files():
    """All last_recall.json under ~/.claude/plugins/data/hindsight-memory*/state/."""
    base = os.path.expanduser("~/.claude/plugins/data")
    pattern = os.path.join(base, "hindsight-memory*", "state", "last_recall.json")
    return glob.glob(pattern)


def parse_saved_at(value):
    """Parse an ISO8601 timestamp (handles trailing Z) into aware UTC."""
    if not value:
        return None
    try:
        cleaned = value.replace("Z", "+00:00")
        parsed = dt.datetime.fromisoformat(cleaned)
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=dt.timezone.utc)
        return parsed.astimezone(dt.timezone.utc)
    except (ValueError, TypeError):
        return None


def load_newest():
    """Return (path, data) for the recall file with the newest saved_at."""
    candidates = []
    for path in find_recall_files():
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except (OSError, json.JSONDecodeError):
            continue
        candidates.append((parse_saved_at(data.get("saved_at")), path, data))
    if not candidates:
        return None, None
    # Sort by saved_at; unknown timestamps sort oldest.
    epoch = dt.datetime.min.replace(tzinfo=dt.timezone.utc)
    candidates.sort(key=lambda c: c[0] or epoch)
    _, path, data = candidates[-1]
    return path, data


def human_age(delta):
    secs = int(delta.total_seconds())
    if secs < 90:
        return f"{secs}s"
    mins = secs // 60
    if mins < 90:
        return f"{mins}m"
    hours = mins // 60
    if hours < 48:
        return f"{hours}h {mins % 60}m"
    return f"{hours // 24}d"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--stale-minutes", type=int, default=15,
                    help="Age beyond which the recall is considered stale.")
    ap.add_argument("--full", action="store_true",
                    help="Print the entire memories block (default truncates).")
    args = ap.parse_args()

    path, data = load_newest()
    if data is None:
        print("HINDSIGHT RECALL: no last_recall.json found.")
        print("  -> The hindsight-memory plugin has never injected context on this")
        print("     machine, or its data dir moved. If you expect memory recall,")
        print("     check that the plugin is enabled and Hindsight is running.")
        return

    now = dt.datetime.now(dt.timezone.utc)
    saved_at = parse_saved_at(data.get("saved_at"))
    bank = data.get("bank_id", "?")
    count = data.get("result_count", "?")
    context = data.get("context", "") or ""

    print(f"HINDSIGHT RECALL  (source: {path})")
    print(f"  bank: {bank}   memories: {count}   saved_at: {data.get('saved_at', '?')}")

    if saved_at is None:
        print("  freshness: UNKNOWN (could not parse saved_at)")
    else:
        age = now - saved_at
        stale = age > dt.timedelta(minutes=args.stale_minutes)
        label = "STALE" if stale else "fresh"
        print(f"  freshness: {label} (saved {human_age(age)} ago)")
        if stale:
            print(f"  -> No recall in the last {args.stale_minutes}m. The recall hook")
            print("     rewrites this file every prompt, so a stale file means it")
            print("     didn't fire — Hindsight is probably not running. Reminder:")
            print("     start the Hindsight daemon if you want memory context.")

    print()
    if not context.strip():
        print("  (recall returned no memory text)")
        return

    if args.full or len(context) <= 4000:
        print(context)
    else:
        print(context[:4000])
        print(f"\n  ...[truncated {len(context) - 4000} chars — rerun with --full for all]")


if __name__ == "__main__":
    try:
        main()
    finally:
        sys.exit(0)
