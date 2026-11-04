#!/usr/bin/env python3
"""Capture Flutter UX fixtures with verified, source-bound sidecars."""

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys

from validation_evidence import repository_context

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
CAPTURE_KINDS = ("base", "candidate", "mixed", "iteration")


def capture_provenance(root, base, kind, fixture_overlay):
    source = repository_context(root)
    result = subprocess.run(
        [
            "git", "-C", str(source["root"]), "rev-parse", "--verify",
            "--end-of-options", f"{base}^{{commit}}",
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode:
        raise ValueError("base revision does not resolve to a commit")
    base_revision = result.stdout.strip()
    overlay = fixture_overlay.strip()
    if not overlay:
        raise ValueError("describe the fixture overlay, or use 'none'")
    if kind == "mixed" and overlay.lower() == "none":
        raise ValueError("mixed captures require a fixture overlay description")
    if kind == "base" and overlay.lower() != "none":
        raise ValueError("base captures cannot include a fixture overlay; use mixed")
    if kind == "base" and (source["dirty"] or source["head"] != base_revision):
        raise ValueError("base captures require a clean checkout of the base revision")
    return {
        "baseRevision": base_revision,
        "headRevision": source["head"],
        "workingTreeFingerprint": source["fingerprint"],
        "dirty": source["dirty"],
        "fixtureOverlay": overlay,
        "kind": kind,
    }


def _run_flutter(command, cwd):
    return subprocess.run(command, cwd=cwd, check=False).returncode


def capture(root, test, name, output, base, kind, fixture_overlay):
    root = Path(root).resolve()
    app = root / "apps/auravibes_app"
    test_path = (app / test).resolve()
    if not test_path.is_relative_to(app / "test") or not test_path.is_file():
        raise ValueError(
            "test must be an existing file under apps/auravibes_app/test"
        )
    if not name.strip():
        raise ValueError("a test name is required")
    output = Path(output).resolve()
    if output.is_relative_to(root):
        raise ValueError("capture output must be outside the repository")
    if output.exists() and (not output.is_dir() or any(output.iterdir())):
        raise ValueError("capture output must be an empty directory")
    provenance = capture_provenance(root, base, kind, fixture_overlay)
    fixture_status = subprocess.run(
        [
            "git", "-C", str(root), "status", "--porcelain",
            "--untracked-files=all", "--", str(test_path.relative_to(root)),
            "apps/auravibes_app/test/helpers",
        ],
        capture_output=True,
        check=False,
    )
    if fixture_status.returncode:
        raise ValueError("could not inspect the fixture overlay")
    if fixture_status.stdout and provenance["fixtureOverlay"].lower() == "none":
        raise ValueError("describe the changed fixture overlay")
    output.mkdir(parents=True, exist_ok=True)
    encoded_provenance = json.dumps(provenance, separators=(",", ":"))
    command = [
        sys.executable,
        str(root / "tool/validation_lease.py"),
        "--label",
        "ux-capture",
        "--",
        "fvm",
        "flutter",
        "test",
        str(test_path.relative_to(app)),
        "--no-pub",
        "--concurrency=1",
        f"--plain-name={name}",
        f"--dart-define=UX_CAPTURE_DIR={output}",
        f"--dart-define=UX_SOURCE_FINGERPRINT={provenance['workingTreeFingerprint']}",
        f"--dart-define=UX_CAPTURE_PROVENANCE={encoded_provenance}",
    ]
    code = _run_flutter(command, app)
    if code:
        raise ValueError(f"Flutter capture failed with exit code {code}")
    after = repository_context(root)
    if (after["head"], after["fingerprint"]) != (
        provenance["headRevision"],
        provenance["workingTreeFingerprint"],
    ):
        raise ValueError("source changed during capture; discard the images")
    verify_capture(output, expected=provenance)
    return provenance


def verify_capture(output, expected=None):
    output = Path(output)
    if not output.is_dir():
        raise ValueError("capture directory does not exist")
    images = sorted(output.rglob("*.png"))
    if not images:
        raise ValueError("capture produced no PNG images")
    recorded = expected
    for image in images:
        if not image.read_bytes().startswith(PNG_SIGNATURE):
            raise ValueError(f"invalid PNG image: {image.name}")
        sidecar = image.with_suffix(".json")
        if not sidecar.is_file():
            raise ValueError(f"missing sidecar for {image.name}")
        try:
            metadata = json.loads(sidecar.read_text())
        except (OSError, ValueError) as error:
            raise ValueError(f"invalid sidecar for {image.name}") from error
        provenance = (
            metadata.get("sourceProvenance") if isinstance(metadata, dict) else None
        )
        if not _valid_provenance(provenance):
            raise ValueError(f"incorrect provenance in sidecar for {image.name}")
        if recorded is None:
            recorded = provenance
        if (
            provenance != recorded
            or metadata.get("sourceFingerprint")
            != provenance["workingTreeFingerprint"]
        ):
            raise ValueError(f"incorrect provenance in sidecar for {image.name}")
    return len(images), recorded


def _valid_provenance(value):
    if not isinstance(value, dict):
        return False
    sha = r"(?:[0-9a-f]{40}|[0-9a-f]{64})"
    for key in ("baseRevision", "headRevision"):
        if not isinstance(value.get(key), str) or not re.fullmatch(sha, value[key]):
            return False
    fingerprint = value.get("workingTreeFingerprint")
    if not isinstance(fingerprint, str) or not re.fullmatch(
        r"[0-9a-f]{64}", fingerprint
    ):
        return False
    if type(value.get("dirty")) is not bool or value.get("kind") not in CAPTURE_KINDS:
        return False
    overlay = value.get("fixtureOverlay")
    if not isinstance(overlay, str) or not overlay.strip():
        return False
    if value["kind"] == "mixed" and overlay.lower() == "none":
        return False
    return not (
        value["kind"] == "base"
        and (value["dirty"] or value["headRevision"] != value["baseRevision"]
             or overlay.lower() != "none")
    )


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--verify", help="check an existing capture directory before use"
    )
    parser.add_argument("--test", help="test path relative to the app")
    parser.add_argument("--name", help="plain Flutter test name")
    parser.add_argument(
        "--output", help="empty directory outside the repo"
    )
    parser.add_argument("--base", help="baseline commit or ref")
    parser.add_argument(
        "--kind", choices=CAPTURE_KINDS
    )
    parser.add_argument(
        "--fixture-overlay", help="describe the overlay, or use 'none'"
    )
    args = parser.parse_args(argv)
    capture_args = (
        args.test, args.name, args.output, args.base, args.kind, args.fixture_overlay
    )
    if args.verify and any(value is not None for value in capture_args):
        parser.error("--verify cannot be combined with capture options")
    if not args.verify and any(value is None for value in capture_args):
        parser.error(
            "capture requires --test, --name, --output, --base, --kind "
            "and --fixture-overlay"
        )
    try:
        if args.verify:
            count, provenance = verify_capture(args.verify)
        else:
            provenance = capture(
                Path(__file__).resolve().parent.parent,
                args.test,
                args.name,
                args.output,
                args.base,
                args.kind,
                args.fixture_overlay,
            )
            count = len(list(Path(args.output).rglob("*.png")))
    except (OSError, RuntimeError, ValueError) as error:
        print(f"ux-capture: {error}", file=sys.stderr)
        return 1
    print(
        f"Verified {count} {provenance['kind']} image(s): "
        f"base {provenance['baseRevision']}, head {provenance['headRevision']}, "
        f"dirty={provenance['dirty']}, fixture overlay: {provenance['fixtureOverlay']}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
