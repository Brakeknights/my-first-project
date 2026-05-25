#!/usr/bin/env python3
"""
PreToolUse hook that blocks git commits / merges / pushes landing on
dev or master without explicit user approval. No bypass — Claude cannot
self-approve. Per CLAUDE.md: feature branch only, the user must say
"push to dev" themselves.

Quoted strings and heredocs are stripped before matching so that
commit message bodies (which may legitimately mention 'git push' or
'dev/master') do not false-positive.
"""

import json
import os
import re
import subprocess
import sys


def read_input():
    try:
        return json.load(sys.stdin)
    except Exception:
        return {}


def current_branch():
    try:
        out = subprocess.check_output(
            ["git", "branch", "--show-current"],
            cwd=os.environ.get("CLAUDE_PROJECT_DIR", "."),
            stderr=subprocess.DEVNULL,
            text=True,
        )
        return out.strip()
    except Exception:
        return ""


def block(reason):
    sys.stderr.write(
        f"BLOCKED by .claude/hooks/guard-dev-master.sh: {reason}\n\n"
        "Per CLAUDE.md, changes to dev or master require explicit user approval.\n"
        'The user must say "push to dev" / "merge to dev" / "approved for dev"\n'
        "(etc) before any commit, merge, or push touches those branches.\n\n"
        "Stage your changes on the feature branch only. If the user has already\n"
        "explicitly approved this push/merge in this turn, ask them to run the\n"
        "command themselves — Claude cannot bypass this guard.\n"
    )
    sys.exit(2)


def strip_quoted(s):
    """Remove heredocs and single/double-quoted strings so quoted text
    (e.g. commit message bodies) is not scanned by the pattern checks."""
    # Heredocs: <<TAG ... TAG  and  <<'TAG' ... TAG  and  <<-TAG ... TAG
    s = re.sub(
        r"<<-?\s*['\"]?(\w+)['\"]?.*?^\s*\1\s*$",
        " ",
        s,
        flags=re.DOTALL | re.MULTILINE,
    )
    # Single-quoted strings (no escapes inside single quotes in POSIX shell)
    s = re.sub(r"'[^']*'", " ", s)
    # Double-quoted strings (with backslash escapes)
    s = re.sub(r'"(?:[^"\\]|\\.)*"', " ", s)
    return s


# Whole-word match for dev / master (no surrounding word chars, dashes, or slashes)
DM = r"(?<![\w\-/])(?:dev|master)(?![\w\-/])"

# Match a git push command: optional pre-flags, then 'push', up to next shell separator
PUSH_PREFIX = r"(?:^|[\s&|;])git\s+(?:-\S+\s+)*push\b"


def main():
    data = read_input()
    if data.get("tool_name") != "Bash":
        sys.exit(0)

    raw = data.get("tool_input", {}).get("command", "") or ""
    cmd = strip_quoted(raw)

    # 1. git push referencing dev or master
    if re.search(PUSH_PREFIX + r"[^|;&]*" + DM, cmd):
        block("git push referencing dev/master")

    # 2. git push --all or --mirror (would push every local branch)
    if re.search(PUSH_PREFIX + r"[^|;&]*--(?:all|mirror)\b", cmd):
        block("git push --all/--mirror would include dev/master")

    # 3. bare 'git push' (no explicit refspec) while current branch is dev/master
    bare_push = re.search(
        r"(?:^|[\s&|;])git\s+(?:-\S+\s+)*push"
        r"(?:\s+(?:--?u(?:pstream)?|--force(?:-with-lease)?|-f))*"
        r"\s*(?:$|[|;&])",
        cmd,
    )
    if bare_push and not re.search(r"push[^|;&]*\borigin\b", cmd):
        b = current_branch()
        if b in ("dev", "master"):
            block(f"bare 'git push' while on {b} branch")

    # 4. git merge while currently on dev or master
    if re.search(r"(?:^|[\s&|;])git\s+(?:-\S+\s+)*merge\b", cmd):
        b = current_branch()
        if b in ("dev", "master"):
            block(f"git merge while on {b} — would merge into protected branch")

    # 5. git commit while currently on dev or master
    if re.search(r"(?:^|[\s&|;])git\s+(?:-\S+\s+)*commit\b", cmd):
        b = current_branch()
        if b in ("dev", "master"):
            block(f"git commit while on {b} — switch to feature branch first")

    # 6. Compound: git checkout dev|master followed by commit|merge|push in same shell call
    if re.search(r"git\s+checkout\s+" + DM, cmd) and re.search(
        r"git\s+(?:commit|merge|push)\b", cmd
    ):
        block("compound command switches to dev/master and then commits/merges/pushes")

    sys.exit(0)


if __name__ == "__main__":
    main()
