#!/usr/bin/env python3
"""Read-only checks for repository guidance; no model calls or network access."""

import json
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit

SCOPES = (
    "apps/auravibes_app",
    "packages/auravibes_engine",
    "packages/auravibes_ui",
    "widgetbook",
)


def markdown_links(text):
    """Yield inline link targets outside fenced blocks and inline code."""
    fence = None
    for line in text.splitlines():
        marker = re.match(r"^\s*(`{3,}|~{3,})", line)
        if marker:
            token = marker.group(1)
            if fence is None:
                fence = token
            elif token[0] == fence[0] and len(token) >= len(fence):
                fence = None
            continue
        if fence:
            continue
        line = re.sub(r"`[^`]*`", "", line)
        for target in re.findall(r"\]\(([^)]+)\)", line):
            # Support plain destinations and angle-wrapped paths with spaces.
            if target.startswith("<"):
                target = target[1:].split(">", 1)[0]
            else:
                target = target.split()[0]
            yield target


def verify(root):
    root = root.resolve()
    errors = []

    def fail(path, message):
        errors.append(f"{path.relative_to(root)}: {message}")

    instructions = [root / "AGENTS.md"]
    instructions.extend(root / scope / "AGENTS.md" for scope in SCOPES)
    for path in instructions:
        if not path.is_file():
            fail(path, "Missing instructions. Restore this scope's AGENTS.md.")
        alias = path.with_name("CLAUDE.md")
        if not alias.is_symlink() or alias.readlink() != Path("AGENTS.md"):
            fail(alias, "Expected symlink to AGENTS.md. Restore the local alias.")
    main = root / "AGENTS.md"
    if main.is_file() and len(main.read_text().splitlines()) > 150:
        fail(main, "Over 150 lines. Move rare procedures to conditional references.")
    architecture = root / "docs/ARCHITECTURE.md"
    if not architecture.is_file():
        fail(architecture, "Missing architecture entrypoint. Restore its pointer.")

    skills = sorted((root / ".agents/skills").glob("*/SKILL.md"))
    markdown = set(path for path in instructions if path.is_file())
    for path in skills:
        text = path.read_text()
        frontmatter = re.match(r"\A---\n(.*?)\n---(?:\n|$)", text, re.S)
        if not frontmatter:
            fail(path, "Missing YAML frontmatter. Add name and description.")
        else:
            fields = {}
            for key in ("name", "description"):
                match = re.search(rf"^{key}:\s*(.+)$", frontmatter.group(1), re.M)
                fields[key] = match.group(1).strip().strip("\"'") if match else ""
                if not fields[key]:
                    fail(path, f"Missing {key}. Describe the skill's task trigger.")
            if fields["name"] and fields["name"] != path.parent.name:
                fail(path, "Skill name differs from directory. Align discovery metadata.")
        markdown.add(path)
        markdown.update((path.parent / "references").glob("*.md"))
        cases = path.parent / "evals/evals.json"
        if cases.exists():
            try:
                data = json.loads(cases.read_text())
                if data.get("skill_name") != path.parent.name:
                    raise ValueError("skill_name must match the owning skill")
                scenarios = data.get("evals")
                if not isinstance(scenarios, list) or not scenarios:
                    raise ValueError("evals must be a nonempty list")
                ids = set()
                for item in scenarios:
                    if not isinstance(item, dict):
                        raise ValueError("each scenario must be an object")
                    identifier = item.get("id")
                    if type(identifier) is not int or identifier in ids:
                        raise ValueError("scenario IDs must be unique integers")
                    ids.add(identifier)
                    for key in ("prompt", "expected_output"):
                        if not isinstance(item.get(key), str) or not item[key].strip():
                            raise ValueError(f"each scenario needs {key}")
                    files = item.get("files")
                    if not isinstance(files, list) or any(not isinstance(f, str) for f in files):
                        raise ValueError("files must be a list of path strings")
            except (ValueError, AttributeError) as error:
                fail(cases, f"Invalid evaluation cases: {error}. Repair scenario data.")

    # Follow local references so newly extracted runbooks are checked as well.
    visited = set()
    while markdown:
        path = markdown.pop()
        if path in visited:
            continue
        visited.add(path)
        for target in markdown_links(path.read_text()):
            url = urlsplit(target)
            if url.scheme or url.netloc or not url.path:
                continue
            referenced = (path.parent / unquote(url.path)).resolve()
            if not referenced.is_relative_to(root):
                fail(path, f"Reference escapes repository: {target}. Use a scoped path.")
            elif not referenced.exists():
                fail(path, f"Dead reference: {target}. Correct the relative path or restore its file.")
            elif referenced.is_file() and referenced.suffix == ".md":
                markdown.add(referenced)
    return errors


def main():
    errors = verify(Path(__file__).resolve().parent.parent)
    if errors:
        for message in errors:
            print(message, file=sys.stderr)
        print("Repair affected guidance, then rerun python3 tool/verify_agent_harness.py.", file=sys.stderr)
        return 1
    print("Harness verification passed (links, aliases, metadata, evaluation schema).")
    print("Behavioral model trials are separate; this check does not run them.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
