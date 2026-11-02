#!/usr/bin/env python3
"""Read-only checks for repository guidance; no model calls or network access.

Melos command checks cover the root AGENTS.md, its linked scope AGENTS.md files,
docs/agents/**/*.md, and .agents/**/*.md. YAML code examples are treated as
configuration examples rather than commands from this workspace.
"""

import json
from html.parser import HTMLParser
from pathlib import Path
import re
import string
import sys
from urllib.parse import unquote, urlsplit

HTML_TAG_START = re.compile(
    r"</?[A-Za-z][A-Za-z0-9:-]*(?:[ \t\r\n]|/?>|$)"
)
ACTION_USES = re.compile(r"^\s*(?:-\s*)?uses:\s*(\S+)")
FULL_COMMIT_SHA = re.compile(r"[0-9a-fA-F]{40}")
MELOS_RUN = re.compile(r"\bmelos\s+run\s+([A-Za-z0-9][A-Za-z0-9:_-]*)\b")
MELOS_SCRIPT_DECLARATION = re.compile(
    r"^ {4}([A-Za-z0-9][A-Za-z0-9:_-]*):(?:[ \t]*(?:#.*)?)?$"
)
SKILL_NAME = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*")
SKILL_NAME_MIN_LENGTH = 1
SKILL_NAME_MAX_LENGTH = 64
SKILL_DESCRIPTION_MAX_LENGTH = 1024


def _skill_frontmatter_value(frontmatter, key):
    """Read a simple YAML frontmatter scalar, including literal/folded blocks."""
    lines = frontmatter.splitlines()
    for index, line in enumerate(lines):
        match = re.match(rf"^(?P<indent> *){re.escape(key)}:[ \t]*(?P<value>.*)$", line)
        if not match:
            continue

        raw_value = match.group("value").strip()
        block = re.fullmatch(r"([>|])([+-]?[1-9]?|[1-9][+-]?)(?:[ \t]+#.*)?", raw_value)
        if not block:
            return raw_value.strip("\"'")

        style, indicators = block.groups()
        parent_indent = len(match.group("indent"))
        explicit_indent_match = re.search(r"[1-9]", indicators)
        content_indent = (
            parent_indent + int(explicit_indent_match.group())
            if explicit_indent_match
            else None
        )
        leading_blanks = 0
        content = []
        for candidate in lines[index + 1 :]:
            if not candidate.strip():
                if content_indent is None:
                    leading_blanks += 1
                else:
                    content.append(("", False))
                continue

            indent = len(candidate) - len(candidate.lstrip(" "))
            if indent <= parent_indent:
                break
            if content_indent is None:
                content_indent = indent
                content.extend(("", False) for _ in range(leading_blanks))
            if indent < content_indent:
                break
            content.append((candidate[content_indent:], indent > content_indent))

        if not content:
            return ""

        trailing_blanks = 0
        while content and not content[-1][0]:
            content.pop()
            trailing_blanks += 1
        if not content:
            return ""

        value_parts = [content[0][0]]
        for previous, current in zip(content, content[1:]):
            previous_text, previous_indented = previous
            current_text, current_indented = current
            if style == "|" or previous_indented or current_indented:
                separator = "\n"
            elif previous_text and current_text:
                separator = " "
            elif previous_text:
                separator = ""
            else:
                separator = "\n"
            value_parts.extend((separator, current_text))

        value = "".join(value_parts)
        chomp = "+" if "+" in indicators else "-" if "-" in indicators else "clip"
        value = value.rstrip("\n")
        if chomp == "+":
            value += "\n" * (trailing_blanks + 1)
        elif chomp == "clip":
            value += "\n"
        return value

    return ""


def _without_yaml_code_blocks(text):
    """Preserve line numbers while omitting fenced YAML configuration examples."""
    lines = []
    yaml_fence = None
    for line in text.splitlines():
        if yaml_fence:
            closing = re.match(
                rf"^[ \t]*{re.escape(yaml_fence[0])}{{{yaml_fence[1]},}}[ \t]*$",
                line,
            )
            lines.append("")
            if closing:
                yaml_fence = None
            continue

        opening = re.match(r"^[ \t]*(`{3,}|~{3,})[ \t]*([A-Za-z0-9_-]*)", line)
        if opening and opening.group(2).lower() in {"yaml", "yml"}:
            yaml_fence = (opening.group(1)[0], len(opening.group(1)))
            lines.append("")
            continue

        lines.append(line)
    return "\n".join(lines)


def _melos_script_names(pubspec):
    """Read declared Melos script names without requiring a YAML dependency."""
    if not pubspec.is_file():
        return set()

    names = set()
    in_melos = False
    in_scripts = False
    for line in pubspec.read_text().splitlines():
        if re.match(r"^melos:[ \t]*(?:#.*)?$", line):
            in_melos = True
            in_scripts = False
            continue
        if in_melos and re.match(r"^  scripts:[ \t]*(?:#.*)?$", line):
            in_scripts = True
            continue
        if in_scripts:
            if line.strip() and not line.startswith("    "):
                break
            match = MELOS_SCRIPT_DECLARATION.match(line)
            if match:
                names.add(match.group(1))
        elif in_melos and line and not line.startswith(" "):
            break
    return names


def _verify_melos_commands(root, guidance_files, fail):
    """Check documented Melos invocations against the root workspace scripts."""
    scripts = _melos_script_names(root / "pubspec.yaml")
    for path in sorted(guidance_files):
        guidance = _without_yaml_code_blocks(path.read_text())
        for line_number, line in enumerate(guidance.splitlines(), start=1):
            for match in MELOS_RUN.finditer(line):
                script = match.group(1)
                if script not in scripts:
                    fail(
                        path,
                        f"line {line_number}: Unknown Melos script '{script}'. "
                        "Add it to root pubspec.yaml under melos.scripts or "
                        "correct the command.",
                    )


class _HtmlImageSourceParser(HTMLParser):
    """Collect image sources from raw HTML embedded in Markdown."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.sources = []

    def handle_starttag(self, tag, attrs):
        if tag.lower() == "img":
            self.sources.extend(
                value for name, value in attrs if name.lower() == "src" and value
            )


class _HtmlContextParser(HTMLParser):
    """Track raw HTML blocks and tags that continue across Markdown lines."""

    _VOID_TAGS = {
        "area",
        "base",
        "br",
        "col",
        "embed",
        "hr",
        "img",
        "input",
        "link",
        "meta",
        "param",
        "source",
        "track",
        "wbr",
    }

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.open_tags = []

    @property
    def active(self):
        pending_tag = self.rawdata.lstrip().startswith("<") and ">" not in self.rawdata
        return bool(self.open_tags) or pending_tag

    def reset_block(self):
        self.reset()
        self.open_tags.clear()

    def handle_starttag(self, tag, attrs):
        if tag.lower() not in self._VOID_TAGS:
            self.open_tags.append(tag.lower())

    def handle_endtag(self, tag):
        tag = tag.lower()
        for index in range(len(self.open_tags) - 1, -1, -1):
            if self.open_tags[index] == tag:
                del self.open_tags[index:]
                break

    def handle_startendtag(self, tag, attrs):
        pass


def _without_code(text):
    """Remove fenced and inline code so examples are not treated as links."""
    lines = []
    fence = None
    list_content_indents = []
    html_context = _HtmlContextParser()
    for line in text.splitlines():
        indentation = re.match(r"^[ \t]*", line).group(0)
        indent = len(indentation.expandtabs(4))
        if fence:
            marker = re.match(r"^[ \t]*(`{3,}|~{3,})[ \t]*$", line)
            if (
                marker
                and indent >= fence[2]
                and indent - fence[2] <= 3
                and marker.group(1)[0] == fence[0]
                and len(marker.group(1)) >= fence[1]
            ):
                fence = None
            lines.append("")
            continue

        if not line.strip():
            lines.append("")
            if html_context.active:
                html_context.reset_block()
            continue

        while list_content_indents and indent < list_content_indents[-1]:
            list_content_indents.pop()
        content_indent = list_content_indents[-1] if list_content_indents else 0
        in_html_context = html_context.active

        if not in_html_context:
            marker = re.match(r"^([ \t]*)(`{3,}|~{3,})(.*)$", line)
            if (
                marker
                and indent >= content_indent
                and indent - content_indent <= 3
            ):
                token = marker.group(2)
                fence = (token[0], len(token), content_indent)
                lines.append("")
                continue

            if indent >= content_indent + 4:
                lines.append("")
                continue

        cleaned_line = re.sub(r"(`+).*?\1", "", line)
        lines.append(cleaned_line)
        if in_html_context or HTML_TAG_START.search(cleaned_line):
            html_context.feed(cleaned_line + "\n")
        if not in_html_context:
            list_item = re.match(r"^([ \t]*)(?:[-+*]|\d{1,9}[.)])([ \t]+)", line)
            if list_item:
                prefix, separator = list_item.groups()
                marker_end = list_item.end() - len(separator)
                list_content_indents.append(
                    len((line[:marker_end] + separator).expandtabs(4))
                )
    text = "\n".join(lines)
    return re.sub(r"<!--.*?(?:-->|$)", "", text, flags=re.DOTALL)


def _is_escaped(text, index):
    backslashes = 0
    index -= 1
    while index >= 0 and text[index] == "\\":
        backslashes += 1
        index -= 1
    return backslashes % 2 == 1


def _unescape_markdown(text):
    """Decode Markdown escapes for ASCII punctuation in a destination."""
    result = []
    index = 0
    while index < len(text):
        if (
            text[index] == "\\"
            and index + 1 < len(text)
            and text[index + 1] in string.punctuation
        ):
            result.append(text[index + 1])
            index += 2
        else:
            result.append(text[index])
            index += 1
    return "".join(result)


def _inline_link_targets(text):
    """Yield destinations from inline Markdown links and images."""
    brackets = []
    index = 0
    while index < len(text):
        char = text[index]
        if char == "[" and not _is_escaped(text, index):
            brackets.append(index)
            index += 1
            continue
        if char != "]" or _is_escaped(text, index) or not brackets:
            index += 1
            continue

        brackets.pop()
        opening = index + 1
        if opening >= len(text) or text[opening] != "(":
            index += 1
            continue

        index = opening + 1
        while index < len(text) and text[index].isspace():
            index += 1
        if index == len(text):
            continue

        if text[index] == "<":
            end = index + 1
            while end < len(text):
                if text[end] == ">" and not _is_escaped(text, end):
                    yield _unescape_markdown(text[index + 1 : end])
                    index = end + 1
                    break
                end += 1
            else:
                index = end
            continue

        target = []
        depth = 0
        while index < len(text):
            char = text[index]
            if char == "\\" and index + 1 < len(text):
                target.extend((char, text[index + 1]))
                index += 2
                continue
            if char == "(":
                depth += 1
            elif char == ")":
                if depth == 0:
                    break
                depth -= 1
            elif char.isspace() and depth == 0:
                break
            target.append(char)
            index += 1
        if target:
            yield _unescape_markdown("".join(target))
        if index < len(text) and text[index] == ")":
            index += 1


def markdown_links(text):
    """Yield inline, reference-definition, and HTML image destinations."""
    text = _without_code(text)
    yield from _inline_link_targets(text)

    # Keep escaped characters and ordinary label characters disjoint to avoid
    # exponential backtracking on long runs of backslashes.
    reference_definition = re.compile(
        r"^ {0,3}\[(?:\\.|[^\\\]])+\]:[ \t]*(?:\n[ \t]{0,3})?"
        r"(<[^>\n]*>|(?:\\.|[^ \t\n]+))",
        re.MULTILINE,
    )
    for match in reference_definition.finditer(text):
        target = match.group(1)
        if target.startswith("<"):
            target = target[1:-1]
        yield _unescape_markdown(target)

    images = _HtmlImageSourceParser()
    images.feed(text)
    images.close()
    yield from images.sources


def verify(root):
    root = root.resolve()
    errors = []

    def fail(path, message):
        errors.append(f"{path.relative_to(root)}: {message}")

    for directory in (root / ".github/workflows", root / ".github/actions"):
        if not directory.is_dir():
            continue
        for path in sorted(directory.rglob("*")):
            if not path.is_file() or path.suffix.lower() not in {".yml", ".yaml"}:
                continue
            for line_number, line in enumerate(path.read_text().splitlines(), start=1):
                match = ACTION_USES.match(line)
                if not match:
                    continue
                reference = match.group(1).strip("\"'")
                # GitHub resolves `$/` references to the workflow's running commit.
                if reference.startswith(("./", "$/")):
                    continue
                _, separator, revision = reference.rpartition("@")
                if not separator or not FULL_COMMIT_SHA.fullmatch(revision):
                    fail(
                        path,
                        f"Mutable or incomplete external action reference '{reference}' "
                        f"on line {line_number}. Pin it to a full 40-character commit SHA.",
                    )

    main = root / "AGENTS.md"
    instructions = [main]
    if main.is_file():
        for target in markdown_links(main.read_text()):
            url = urlsplit(target)
            destination = Path(unquote(url.path))
            if url.scheme or url.netloc or destination.name != "AGENTS.md":
                continue
            scoped = main.parent / destination
            if scoped.resolve().is_relative_to(root) and scoped not in instructions:
                instructions.append(scoped)
    for path in instructions:
        if not path.is_file():
            fail(path, "Missing instructions. Restore this scope's AGENTS.md.")
        alias = path.with_name("CLAUDE.md")
        if not alias.is_symlink() or alias.readlink() != Path("AGENTS.md"):
            fail(alias, "Expected symlink to AGENTS.md. Restore the local alias.")
    if main.is_file() and len(main.read_text().splitlines()) > 150:
        fail(main, "Over 150 lines. Move rare procedures to conditional references.")
    architecture = root / "docs/ARCHITECTURE.md"
    if not architecture.is_file():
        fail(architecture, "Missing architecture entrypoint. Restore its pointer.")

    skills = sorted((root / ".agents/skills").glob("*/SKILL.md"))
    markdown = set(path for path in instructions if path.is_file())
    markdown.update(
        path
        for path in (root / "README.md", root / "CONTRIBUTING.md")
        if path.is_file()
    )
    context_map = root / "CONTEXT-MAP.md"
    if not context_map.is_file():
        fail(context_map, "Missing context map. Restore CONTEXT-MAP.md.")
    else:
        markdown.add(context_map)
        contexts = set()
        for target in markdown_links(context_map.read_text()):
            url = urlsplit(target)
            if url.scheme or url.netloc or Path(unquote(url.path)).name != "CONTEXT.md":
                continue
            path = (context_map.parent / unquote(url.path)).resolve()
            if not path.is_relative_to(root):
                continue  # The shared link check reports paths outside the repository.
            contexts.add(path)
            if not path.is_file():
                fail(path, "Missing context document. Restore the mapped CONTEXT.md file.")
                continue
            text = _without_code(path.read_text())
            if re.search(r"\bplaceholder\b|No glossary or context-specific ADRs documented yet", text, re.I):
                fail(path, "Placeholder context document. Add verified terms, invariants, and relationships.")
            else:
                body = re.sub(r"(?m)^\s*#{1,6}\s+.*$", "", text)
                body = re.sub(r"(?im)^\s*[-*>\s]*(?:(?:TODO|TBD)\b[^\n]*|\.\.\.[.!\s]*)$", "", body)
                if not re.search(r"[A-Za-z0-9]", body):
                    fail(path, "Empty context document. Add verified terms, invariants, and relationships.")
        if not contexts:
            fail(context_map, "No local context documents. Link the workspace CONTEXT.md files.")
    for directory in (root / "docs/agents", root / ".agents"):
        if directory.is_dir():
            markdown.update(path for path in directory.rglob("*.md") if path.is_file())
    guidance_files = {path for path in instructions if path.is_file()}
    guidance_files.update(
        path
        for directory in (root / "docs/agents", root / ".agents")
        if directory.is_dir()
        for path in directory.rglob("*.md")
        if path.is_file()
    )
    _verify_melos_commands(root, guidance_files, fail)
    for path in skills:
        text = path.read_text()
        frontmatter = re.match(r"\A---\n(.*?)\n---(?:\n|$)", text, re.S)
        if not frontmatter:
            fail(path, "Missing YAML frontmatter. Add name and description.")
        else:
            fields = {}
            for key in ("name", "description"):
                fields[key] = _skill_frontmatter_value(frontmatter.group(1), key)
                if not fields[key]:
                    fail(path, f"Missing {key}. Describe the skill's task trigger.")
            name = fields["name"]
            if name:
                if not SKILL_NAME_MIN_LENGTH <= len(name) <= SKILL_NAME_MAX_LENGTH:
                    fail(
                        path,
                        "Skill name must contain 1 to 64 characters "
                        f"(got {len(name)}).",
                    )
                if not SKILL_NAME.fullmatch(name):
                    fail(
                        path,
                        "Skill name must use lowercase letters, numbers, and "
                        "single hyphens; it cannot start or end with a hyphen.",
                    )
            if fields["name"] and fields["name"] != path.parent.name:
                fail(path, "Skill name differs from directory. Align discovery metadata.")
            description = fields["description"]
            if len(description) > SKILL_DESCRIPTION_MAX_LENGTH:
                fail(
                    path,
                    "Skill description must be at most 1024 characters "
                    f"(got {len(description)}).",
                )
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
    print(
        "Harness verification passed (immutable GitHub action references, "
        "documentation links and image references, "
        "context documents, aliases, metadata, evaluation schema, "
        "and documented Melos scripts)."
    )
    print("Behavioral model trials are separate; this check does not run them.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
