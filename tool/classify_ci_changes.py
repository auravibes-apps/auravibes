#!/usr/bin/env python3
"""Classify changed paths for lightweight CI routing.

This module routes code, platform, golden, generated-artifact, Serverpod
integration, and Renovate checks. It never launches dependency updates.
"""

import argparse
import json
import re
import subprocess
import sys


_DOCUMENTATION_FILES = (
    "readme",
    "changelog",
    "license",
)

_CI_ROUTING_PATHS = {
    ".github/workflows/ci.yml",
    "tool/classify_ci_changes.py",
    "tool/classify_ci_changes_test.py",
    "tool/ci_summary.py",
    "tool/ci_summary_test.py",
    "tool/sonar_workflow_test.py",
}

_STATIC_ASSET_SUFFIXES = (
    ".aac",
    ".avif",
    ".bmp",
    ".gif",
    ".ico",
    ".jpeg",
    ".jpg",
    ".mp3",
    ".mp4",
    ".ogg",
    ".otf",
    ".png",
    ".svg",
    ".ttf",
    ".wav",
    ".webm",
    ".webp",
    ".woff",
    ".woff2",
)

_APP_NATIVE_PLATFORMS = {
    "android",
    "ios",
    "linux",
    "macos",
    "web",
    "windows",
}

_SERVER_INTEGRATION_SHARED_PATHS = {
    ".fvmrc",
    ".vscode/settings.json",
    "melos.yaml",
    "pubspec.yaml",
    "pubspec.lock",
    "pubspec_overrides.yaml",
}

_BUILD_RUNNER_PART = re.compile(
    r"^\s*part\s+['\"][^'\"]+\.(?:g|freezed|mocks)\.dart['\"]",
    re.MULTILINE,
)
_GENERATED_ARTIFACT_SUFFIXES = (".g.dart", ".freezed.dart", ".mocks.dart")
_GENERATED_CONFIG_FILES = {
    "build.yaml",
    ".fvmrc",
    "pubspec.yaml",
    "pubspec.lock",
    "pubspec_overrides.yaml",
}
_GENERATED_SOURCE_FILES = {
    "tool/run_quiet.dart",
    "apps/auravibes_server/test/integration/test_tools/serverpod_test_tools.dart",
}
_UI_GOLDEN_SEGMENTS = {
    "components",
    "dialogs",
    "pages",
    "presentation",
    "providers",
    "router",
    "screens",
    "shell",
    "styles",
    "theme",
    "themes",
    "views",
    "widgets",
}
_UI_GOLDEN_TESTS = {
    "apps/auravibes_app/test/features/markdown/screens/markdown_editor_screen_test.dart",
    "apps/auravibes_app/test/features/service_connections/screens/service_connection_edit_screen_test.dart",
    "apps/auravibes_app/test/features/service_connections/screens/service_connections_screen_test.dart",
    "apps/auravibes_app/test/features/tools/widgets/tools_workspace_list_test.dart",
    "apps/auravibes_app/test/features/workspaces/screens/workspace_management_screen_test.dart",
    "apps/auravibes_app/test/widgets/responsive_shell_layout_test.dart",
    "apps/auravibes_app/test/widgets/responsive_shell_test.dart",
    "packages/auravibes_ui/test/src/organisms/auravibes_input_test.dart",
}


def _requires_code_checks(path):
    normalized = path.replace("\\", "/")
    filename = normalized.rsplit("/", 1)[-1].lower()

    if _is_ci_routing_path(normalized):
        return False
    if _is_object_gateway_path(normalized):
        return False
    if _is_skill_metadata(normalized):
        return False
    if normalized == "renovate.json":
        return False
    if (
        _is_docs_media(normalized)
        or _is_routed_non_dart_input(normalized)
        or _is_docker_validation_path(normalized)
    ):
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


def _requires_server_integration(path):
    normalized = path.replace("\\", "/")
    filename = normalized.rsplit("/", 1)[-1].lower()

    if _is_ci_routing_path(normalized):
        return False
    if _is_object_gateway_path(normalized):
        return False
    if (
        filename.endswith((".md", ".mdx"))
        or filename in _DOCUMENTATION_FILES
        or _is_skill_metadata(normalized)
        or _is_docs_media(normalized)
    ):
        return False
    if _is_docker_validation_path(normalized):
        return True
    if normalized.startswith(
        (
            "apps/auravibes_server/",
            "packages/auravibes_engine/",
            ".github/",
            ".fvm/",
        )
    ):
        return True

    return normalized in _SERVER_INTEGRATION_SHARED_PATHS


def _is_object_gateway_path(path):
    return path == ".github/workflows/object-gateway.yml" or path.startswith(
        "services/object_gateway/"
    )


def _is_static_asset(path):
    return path.lower().endswith(_STATIC_ASSET_SUFFIXES)


def _is_docs_media(path):
    return _is_static_asset(path) and path.startswith(("doc/", "docs/"))


def _is_ui_asset_directory(path):
    return path.startswith(
        (
            "apps/auravibes_app/assets/",
            "packages/auravibes_ui/assets/",
        )
    )


def _is_ui_golden_media(path):
    if not _is_static_asset(path):
        return False
    parts = path.split("/")
    return (
        path.startswith(("apps/auravibes_app/test/", "packages/auravibes_ui/test/"))
        and ("goldens" in parts or "golden" in parts[-1].lower())
    )


def _is_app_native_path(path):
    parts = path.split("/")
    return (
        len(parts) > 2
        and parts[:2] == ["apps", "auravibes_app"]
        and parts[2] in _APP_NATIVE_PLATFORMS
    )


def _is_routed_non_dart_input(path):
    return (
        _is_app_native_path(path)
        or (_is_static_asset(path) and _is_ui_asset_directory(path))
        or _is_ui_golden_media(path)
    )


def _is_docker_validation_path(path):
    filename = path.rsplit("/", 1)[-1]
    return (
        filename == ".dockerignore"
        or filename.startswith("Dockerfile")
        or filename.endswith(".Dockerfile")
        or (
            filename.endswith((".yml", ".yaml"))
            and filename.startswith(("compose", "docker-compose"))
        )
        or path in {
            "scripts/start_server.sh",
            "scripts/stop_server.sh",
            "scripts/serverpod_worktree_env.sh",
        }
    )


def _requires_ui_goldens(path):
    normalized = path.replace("\\", "/")
    parts = normalized.split("/")

    if normalized.startswith(
        (
            "apps/auravibes_app/assets/",
            "packages/auravibes_ui/lib/",
            "packages/auravibes_ui/assets/",
        )
    ):
        return True
    if normalized in _UI_GOLDEN_TESTS:
        return True
    if _is_ui_golden_media(normalized):
        return True
    if normalized.startswith(("apps/auravibes_app/test/", "packages/auravibes_ui/test/")):
        filename = parts[-1].lower()
        return "golden" in filename or "goldens" in parts
    if not normalized.startswith("apps/auravibes_app/lib/"):
        return False
    if normalized in {
        "apps/auravibes_app/lib/main.dart",
        "apps/auravibes_app/lib/main_device_preview.dart",
    }:
        return True

    return bool(_UI_GOLDEN_SEGMENTS.intersection(parts[3:-1]))


def _requires_generated_checks(path):
    normalized = path.replace("\\", "/")
    filename = normalized.rsplit("/", 1)[-1].lower()

    return (
        normalized in _GENERATED_SOURCE_FILES
        or filename in _GENERATED_CONFIG_FILES
        or filename.endswith(_GENERATED_ARTIFACT_SUFFIXES)
        or normalized.endswith(".spy.yaml")
        or normalized == "melos.yaml"
        or normalized == "apps/auravibes_server/config/generator.yaml"
        or normalized.startswith("apps/auravibes_server/lib/")
        or normalized.startswith("packages/auravibes_server_client/lib/src/protocol/")
    )


def _requires_dependency_preflight(path):
    normalized = path.replace("\\", "/")
    filename = normalized.rsplit("/", 1)[-1].lower()

    return normalized in {
        ".fvmrc",
        ".github/actions/setup-workspace/action.yml",
        "melos.yaml",
    } or filename in {
        "pubspec.yaml",
        "pubspec.lock",
        "pubspec_overrides.yaml",
    }


def _is_ci_routing_path(path):
    return path.replace("\\", "/") in _CI_ROUTING_PATHS


def _has_build_runner_part(contents):
    return bool(_BUILD_RUNNER_PART.search(contents))


def _changed_generated_source_paths(paths, base, head):
    generated_paths = set()
    for path in paths:
        normalized = path.replace("\\", "/")
        if not normalized.endswith(".dart"):
            continue
        for revision in (base, head):
            result = subprocess.run(
                ["git", "show", f"{revision}:{normalized}"],
                capture_output=True,
                check=False,
                text=True,
            )
            if result.returncode == 0 and _has_build_runner_part(result.stdout):
                generated_paths.add(normalized)
                break
    return generated_paths


def classify_paths(paths, generated_source_paths=()):
    """Return which CI gates changed paths require."""
    normalized_paths = [
        path.replace("\\", "/") for path in paths if isinstance(path, str) and path
    ]
    generated_sources = {
        path.replace("\\", "/") for path in generated_source_paths
    }
    return {
        "run_code_checks": any(_requires_code_checks(path) for path in normalized_paths),
        "run_server_integration": any(
            _requires_server_integration(path) for path in normalized_paths
        ),
        "run_ci_tool_checks": any(
            _is_ci_routing_path(path) for path in normalized_paths
        ),
        "renovate_config_changes": "renovate.json" in normalized_paths,
        "run_ui_goldens": any(_requires_ui_goldens(path) for path in normalized_paths),
        "run_dependency_preflight": any(
            _requires_dependency_preflight(path) for path in normalized_paths
        ),
        "run_generated_checks": any(
            _requires_generated_checks(path) or path in generated_sources
            for path in normalized_paths
        ),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base")
    parser.add_argument("--head")
    args = parser.parse_args()
    if (args.base is None) != (args.head is None):
        parser.error("--base and --head must be provided together")

    paths = [line.rstrip("\n") for line in sys.stdin if line.rstrip("\n")]
    generated_sources = (
        _changed_generated_source_paths(paths, args.base, args.head)
        if args.base is not None
        else ()
    )
    print(
        json.dumps(
            classify_paths(paths, generated_sources),
            sort_keys=True,
        )
    )


if __name__ == "__main__":
    main()
