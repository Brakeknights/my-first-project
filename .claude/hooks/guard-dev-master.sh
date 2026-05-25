#!/usr/bin/env python3
"""
PreToolUse hook that blocks git commits / merges / pushes landing on
dev or master without explicit user approval. No bypass — Claude cannot
self-approve. Per CLAUDE.md: feature branch only, the user must say
"go dev" to grant one-shot approval for dev operations.

"go dev" approval (one-shot token) allows dev-targeted operations only.
Master is NEVER bypassable via token — always requires explicit user action.

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


def consume_dev_token():
    """Check for a one-shot 'go dev' approval token. Returns True and deletes
    the token if present; returns False if absent. Master is never covered."""
    session_id = os.environ.get("CLAUDE_SESSION_ID", "default")
    token_path = f"/tmp/claude-godev-{session_id}"
    try:
        with open(token_path) as f:
            content = f.read().strip()
        if content == "approved":
            os.remove(token_path)
            sys.stderr.write(
                "guard-dev-master.sh: 'go dev' token consumed — "
                "this dev operation is approved (one-shot).\n"
            )
            return True
    except FileNotFoundError:
        pass
    except Exception:
        pass
    return False


def block(reason):
    sys.stderr.write(
        f"BLOCKED by .claude/hooks/guard-dev-master.sh: {reason}\n\n"
        "Per CLAUDE.md, changes to dev or master require explicit user approval.\n"
        'Say "go dev" to grant one-shot approval for dev, or run the git\n'
        "command yourself. Master requires explicit user action — no bypass.\n\n"
        "Stage your changes on the feature branch only.\n"
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
DEV = r"(?<![\w\-/])dev(?![\w\-/])"
MASTER = r"(?<![\w\-/])master(?![\w\-/])"
DM = r"(?<![\w\-/])(?:dev|master)(?![\w\-/])"

# Match a git push command: optional pre-flags, then 'push', up to next shell separator
PUSH_PREFIX = r"(?:^|[\s&|;])git\s+(?:-\S+\s+)*push\b"


def targets_master_only(cmd):
    """True if the command references master but NOT dev."""
    return bool(re.search(MASTER, cmd)) and not bool(re.search(DEV, cmd))


def main():
    data = read_input()
    if data.get("tool_name") != "Bash":
        sys.exit(0)

    raw = data.get("tool_input", {}).get("command", "") or ""
    cmd = strip_quoted(raw)

    # 1. git push referencing dev or master
    if re.search(PUSH_PREFIX + r"[^|;&]*" + DM, cmd):
        if targets_master_only(cmd):
            block("git push referencing master (no token bypass for master)")
        if not consume_dev_token():
            block("git push referencing dev — no 'go dev' approval token found")

    # 2. git push --all or --mirror (would push every local branch) — never bypassable
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
        if b == "master":
            block("bare 'git push' while on master branch (no bypass for master)")
        if b == "dev":
            if not consume_dev_token():
                block("bare 'git push' while on dev — no 'go dev' approval token found")

    # 4. git merge while currently on dev or master
    if re.search(r"(?:^|[\s&|;])git\s+(?:-\S+\s+)*merge\b", cmd):
        b = current_branch()
        if b == "master":
            block("git merge while on master — would merge into protected branch")
        if b == "dev":
            if not consume_dev_token():
                block("git merge while on dev — no 'go dev' approval token found")

    # 5. git commit while currently on dev or master
    if re.search(r"(?:^|[\s&|;])git\s+(?:-\S+\s+)*commit\b", cmd):
        b = current_branch()
        if b == "master":
            block("git commit while on master — switch to feature branch first")
        if b == "dev":
            if not consume_dev_token():
                block("git commit while on dev — no 'go dev' approval token found")

    # 6. Compound: git checkout dev|master followed by commit|merge|push in same shell call
    if re.search(r"git\s+checkout\s+" + DM, cmd) and re.search(
        r"git\s+(?:commit|merge|push)\b", cmd
    ):
        if re.search(r"git\s+checkout\s+" + MASTER, cmd):
            block("compound command switches to master and then commits/merges/pushes")
        if not consume_dev_token():
            block(
                "compound command switches to dev and then commits/merges/pushes — "
                "no 'go dev' approval token found"
            )

    sys.exit(0)


if __name__ == "__main__":
    main()
