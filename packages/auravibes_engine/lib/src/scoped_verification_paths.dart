import 'package:auravibes_engine/src/scoped_verification.dart';
import 'package:auravibes_engine/src/scoped_verification_check.dart';
import 'package:auravibes_engine/src/scoped_verification_json.dart';

/// A host-selected edit report. It carries no execution authority.
final class ScopedEditReport {
  new({required this.workspaceRoot, required List<String> paths})
    : paths = normalizeScopedVerificationPaths(paths) {
    final _ = verificationString(workspaceRoot);
  }

  final String workspaceRoot;
  final List<String> paths;
}

/// A configured check paired with only its matching reported relative paths.
final class ScopedVerificationSelection {
  new({required this.check, required List<String> paths})
    : paths = normalizeScopedVerificationPaths(paths);

  final ScopedVerificationCheck check;
  final List<String> paths;

  Map<String, Object?> toJson() => {'check': check.toJson(), 'paths': paths};
}

/// Parses only an SDK structured-content value, never a tool's model text.
ScopedEditReport? parseScopedEditReport(Object? structuredContent) {
  if (structuredContent is! Map<String, Object?> ||
      !structuredContent.containsKey('auravibesChangedPaths')) {
    return null;
  }
  final report = verificationObject(
    structuredContent['auravibesChangedPaths'],
    const {'version', 'workspaceRoot', 'paths'},
  );
  if (report['version'] is! int || report['version'] != 1) {
    throw const FormatException('Unsupported edit report version.');
  }
  final paths = verificationStrings(
    report['paths'],
    maxEntries: ScopedVerificationLimits.maxPaths,
    maxBytes: ScopedVerificationLimits.maxPathBytes,
  );

  return ScopedEditReport(
    workspaceRoot: verificationString(report['workspaceRoot']),
    paths: paths,
  );
}

/// Validates the entire report before returning any normalized paths.
///
/// Remote filesystem and symlink containment remain the bound runner's duty.
List<String> normalizeScopedVerificationPaths(List<String> rawPaths) {
  if (rawPaths.length > ScopedVerificationLimits.maxPaths) {
    throw const FormatException('Too many reported paths.');
  }
  final normalized = <String>{};
  for (final path in rawPaths) {
    final _ = verificationString(path, maxBytes: ScopedVerificationLimits.maxPathBytes);
    if (path.startsWith('/') || path.contains(r'\') ||
        RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(path)) {
      throw const FormatException('Reported paths must be workspace-relative.');
    }
    final segments = path.split('/');
    if (segments.any((part) => part == '..' || part.startsWith('-'))) {
      throw const FormatException('Reported path escapes its scope.');
    }
    final parts = segments.where((part) => part.isNotEmpty && part != '.').toList();
    if (parts.isEmpty) {
      throw const FormatException('Reported path names the workspace root.');
    }
    normalized.add(parts.join('/'));
  }

  return List.unmodifiable(normalized);
}

List<ScopedVerificationSelection> selectScopedVerificationChecks(
  ScopedVerificationSettings settings,
  ScopedEditReport report,
) {
  if (!settings.enabled) return const [];
  if (report.workspaceRoot != settings.workspaceRoot) {
    throw const FormatException('Edit report root does not match configuration.');
  }
  final selections = <ScopedVerificationSelection>[];
  for (final check in settings.checks) {
    final paths = report.paths.where(
      (path) => check.pathSuffixes.isEmpty || check.pathSuffixes.any(path.endsWith),
    ).toList();
    if (paths.isNotEmpty) {
      selections.add(ScopedVerificationSelection(check: check, paths: paths));
    }
  }

  return List.unmodifiable(selections);
}
