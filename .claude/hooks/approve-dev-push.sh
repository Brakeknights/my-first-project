#!/usr/bin/env python3
"""
UserPromptSubmit hook: scans the user's message for the literal phrase
"go dev" (case-insensitive, whole-word). If present, writes a one-shot
approval token that the dev/master guard will consume on the next
dev-targeting git operation.

Only the user's typed messages flow through UserPromptSubmit, so the
keyword can only be triggered by the user actually typing it.
"""

import json
import os
import re
import sys


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    prompt = data.get("prompt", "") or ""
    session_id = data.get("session_id", "default")

    if re.search(r"\bgo dev\b", prompt, re.IGNORECASE):
        token_path = f"/tmp/claude-godev-{session_id}"
        try:
            with open(token_path, "w") as f:
                f.write("approved\n")
            print(
                json.dumps(
                    {
                        "systemMessage": "'go dev' detected — next push/merge/commit targeting dev is approved (one-shot)."
                    }
                )
            )
        except Exception:
            pass

    sys.exit(0)


if __name__ == "__main__":
    main()
