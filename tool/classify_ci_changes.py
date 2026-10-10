#!/usr/bin/env python3
"""Classify changed paths for lightweight CI routing.

This module only decides whether application checks are needed and whether the
Renovate config validator should run. It never launches dependency updates.
"""

import json
import sys


_DOCUMENTATION_FILES = (
    "readme",
    "changelog",
    "license",
)


def _requires_code_checks(path):
    normalized = path.replace("\\", "/")
    filename = normalized.rsplit("/", 1)[-1].lower()

    if _is_skill_metadata(normalized):
        return False
    if normalized == "renovate.json":
        return False
    if (
        normalized.startswith(".github/")
        or normalized.startswith(".fvm/")
        or normalized in (".fvmrc", ".vscode/settings.json")
        or normalized.startswith("assets/")
        or "/assets/" in normalized
    ):
        return True
    if (
        filename.endswith((".md", ".mdx"))
        or filename in _DOCUMENTATION_FILES
        or normalized.startswith(".pi/")
        or normalized == "sonar-project.properties"
    ):
        return False

    return True


def _is_skill_metadata(path):
    if not path.startswith(".agents/skills/"):
        return False
    filename = path.rsplit("/", 1)[-1].lower()

    return filename.endswith((".md", ".mdx")) or path.endswith("/evals/evals.json")


def classify_paths(paths):
    """Return whether paths need app checks and Renovate config validation."""
    normalized_paths = [
        path.replace("\\", "/") for path in paths if isinstance(path, str) and path
    ]
    return {
        "run_code_checks": any(_requires_code_checks(path) for path in normalized_paths),
        "renovate_config_changes": "renovate.json" in normalized_paths,
    }


def main():
    paths = [line.rstrip("\n") for line in sys.stdin if line.rstrip("\n")]
    print(json.dumps(classify_paths(paths), sort_keys=True))


if __name__ == "__main__":
    main()
