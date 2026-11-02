"""Shared configuration and helpers for experiment 2 (checkpoint mode).

Every trial starts from the same reference commit for both arms, so the only difference
between arms is the CLAUDE.md file. Reference commits are the passing step commits of the
`baseline` branch from experiment 1, tagged ref/00 ... ref/08.
"""
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = Path(subprocess.check_output(["git", "rev-parse", "--show-toplevel"], cwd=HERE, text=True).strip())
WT_DIR = Path(os.environ.get("WT_DIR", str(ROOT.parent / f"{ROOT.name}-wt")))
OUT = ROOT / "results" / "exp2"
ARMS = ["baseline", "caveman"]
CAVEMAN_MD = ROOT / "bench" / "arms" / "caveman" / "CLAUDE.md"
ACC_DIR = HERE / "acceptance"
TASK_DIR = HERE / "tasks"
TEST_DEST = Path("Tests/TMDBAppTests")

# kind: code = build a feature, fix = find and fix a seeded bug, explain = read-only answer
TASKS = {
    "01-models":      {"kind": "code", "start": "ref/00", "acceptance": "Acceptance01"},
    "02-networking":  {"kind": "code", "start": "ref/01", "acceptance": "Acceptance02"},
    "03-service":     {"kind": "code", "start": "ref/02", "acceptance": "Acceptance03"},
    "04-movie-list":  {"kind": "code", "start": "ref/03", "acceptance": "Acceptance04"},
    "05-search":      {"kind": "code", "start": "ref/04", "acceptance": "Acceptance05"},
    "06-detail":      {"kind": "code", "start": "ref/05", "acceptance": "Acceptance06"},
    "07-favorites":   {"kind": "code", "start": "ref/06", "acceptance": "Acceptance07"},
    "08-app-shell":   {"kind": "code", "start": "ref/07", "acceptance": "Acceptance08"},
    "d1-pagination-bug": {
        "kind": "fix", "start": "ref/08", "acceptance": "Acceptance04",
        "bug": ("Sources/TMDBApp/ViewModels/MovieListViewModel.swift",
                "index >= movies.count - 3", "index >= movies.count + 3"),
    },
    "d2-runtime-bug": {
        "kind": "fix", "start": "ref/08", "acceptance": "Acceptance06",
        "bug": ("Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift",
                "m = minutes % 60", "m = minutes % 6"),
    },
    "d3-favorites-bug": {
        "kind": "fix", "start": "ref/08", "acceptance": "Acceptance07",
        "bug": ("Sources/TMDBApp/Services/FavoritesStore.swift",
                "movies.filter { seen.insert($0.id).inserted }",
                "movies.filter { !seen.insert($0.id).inserted }"),
    },
    "x1-explain-pagination": {
        "kind": "explain", "start": "ref/08",
        # Rough completeness check: each group is one fact; any listed word counts as a hit.
        "rubric": [["generation", "stale", "superseded", "outdated"],
                   ["totalPages", "total pages", "last page"],
                   ["isFetching", "in flight", "in-flight", "already loading", "already fetching"],
                   ["paginationError", "pagination error"],
                   ["duplicate", "dedup", "already in the list", "known ids"]],
    },
    "x2-review-search": {"kind": "explain", "start": "ref/08"},
    "x3-plan-genre-filter": {"kind": "explain", "start": "ref/08"},
}

PERM_FLAGS = [
    "--permission-mode", "acceptEdits",
    "--allowedTools", "Read", "Edit", "Write", "Glob", "Grep", "MultiEdit", "TodoWrite",
    "Bash(swift build:*)", "Bash(swift test:*)", "Bash(swift package:*)",
    "Bash(mkdir:*)", "Bash(ls:*)", "Bash(cat:*)", "Bash(find:*)", "Bash(mv:*)", "Bash(rm:*)",
    "Bash(cd:*)", "Bash(echo:*)", "Bash(head:*)", "Bash(tail:*)", "Bash(grep:*)", "Bash(wc:*)",
    "--disallowedTools", "Bash(git commit:*)", "Bash(git push:*)", "Bash(git checkout:*)",
    "Bash(git reset:*)", "WebFetch", "WebSearch",
]


def sh(args, cwd=None, check=True, timeout=None, capture=True):
    r = subprocess.run(args, cwd=cwd, text=True, timeout=timeout,
                       stdout=subprocess.PIPE if capture else None,
                       stderr=subprocess.STDOUT if capture else None)
    if check and r.returncode != 0:
        raise RuntimeError(f"command failed ({r.returncode}): {' '.join(map(str, args))}\n{r.stdout or ''}")
    return r


def git(*args, cwd=ROOT, check=True):
    return sh(["git", *args], cwd=cwd, check=check)


def rev_exists(rev):
    return git("rev-parse", "--verify", "-q", rev, check=False).returncode == 0


def ensure_refs():
    """Tags ref/00 (skeleton) and ref/01..08 (baseline step commits from experiment 1)."""
    if not rev_exists("refs/tags/setup/baseline"):
        sys.exit("✗ tag setup/baseline missing: run ./bench/setup.sh and experiment 1 first.")
    if not rev_exists("refs/tags/ref/00"):
        git("tag", "ref/00", "setup/baseline")
    log = git("log", "--format=%H %s", "setup/baseline..baseline").stdout.splitlines()
    by_step = {}
    for line in log:
        sha, subject = line.split(" ", 1)
        m = re.match(r"(0\d)-", subject)
        if m and m.group(1) not in by_step:  # newest first: keep the latest commit per step
            by_step[m.group(1)] = sha
    for n in range(1, 9):
        tag = f"ref/{n:02d}"
        if rev_exists(f"refs/tags/{tag}"):
            continue
        sha = by_step.get(f"{n:02d}")
        if not sha:
            sys.exit(f"✗ no baseline commit for step {n:02d}; cannot create {tag}")
        git("tag", tag, sha)


def ensure_worktree(name):
    path = WT_DIR / name
    if not path.exists():
        WT_DIR.mkdir(parents=True, exist_ok=True)
        git("worktree", "add", "-q", "--detach", str(path), "ref/00")
    return path


def prepare(wt, start, arm=None, bug=None):
    """Checks out `start`, cleans, adds CLAUDE.md for caveman, injects the bug, and commits the
    result as the trial's starting point (detached HEAD), so the patch shows only agent edits."""
    git("checkout", "-q", "-f", "--detach", start, cwd=wt)
    git("clean", "-fdq", cwd=wt)  # keeps git-ignored .build for faster builds
    if arm == "caveman":
        shutil.copy(CAVEMAN_MD, wt / "CLAUDE.md")
    if bug:
        rel, old, new = bug
        f = wt / rel
        text = f.read_text()
        if text.count(old) != 1:
            raise RuntimeError(f"bug injection: {old!r} found {text.count(old)}x in {rel}")
        f.write_text(text.replace(old, new))
    git("add", "-A", cwd=wt)
    git("-c", "user.name=bench", "-c", "user.email=bench@localhost", "commit", "-q",
        "--allow-empty", "--no-verify", "-m", "trial start", cwd=wt)


def acceptance_total(name):
    return (ACC_DIR / f"{name}.swift").read_text().count("@Test")


def run_acceptance(wt, name, timeout=900):
    """Copies the hidden test file in, runs only it, removes it again. Returns a dict."""
    dest = wt / TEST_DEST / f"{name}.swift"
    shutil.copy(ACC_DIR / f"{name}.swift", dest)
    total = acceptance_total(name)
    try:
        r = sh(["swift", "test", "--filter", name], cwd=wt, check=False, timeout=timeout)
        out = r.stdout
        status = None
    except subprocess.TimeoutExpired as e:
        out = (e.stdout or "") if isinstance(e.stdout, str) else ""
        status = "timeout"
    finally:
        dest.unlink(missing_ok=True)
    passed = failed = 0
    for line in out.splitlines():
        s = line.strip()
        if "Test run with" in s:
            continue
        if s.startswith("✔ Test "):
            passed += 1
        elif s.startswith("✘ Test "):
            failed += 1
    if status is None:
        if "Test run with" not in out:
            status = "compile_error"
        else:
            status = "pass" if failed == 0 and passed >= total else "fail"
    return {"status": status, "passed": passed if status != "compile_error" else 0,
            "total": total, "log": out}


def write_json_line(path, rec):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "a") as f:
        f.write(json.dumps(rec) + "\n")


def read_json_lines(path):
    if not path.exists():
        return []
    return [json.loads(l) for l in path.read_text().splitlines() if l.strip()]
