// Generates a markdown PR comment summarising test results.
//
// Usage: dart .github/scripts/test_report_comment.dart <reports-dir> <output-file>
//
// Reads every *.json file in <reports-dir> (dart/flutter test
// `--file-reporter=json` output, one JSON event per line) and writes a
// markdown comment to <output-file>:
//
//   * a [!CAUTION] callout when at least one test failed, [!NOTE] otherwise
//   * a per-package summary table (test count and success rate)
//   * for packages with failures only: a collapsible per-file breakdown
//     listing each test in files that contain at least one failing test

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln(
      'Usage: dart test_report_comment.dart <reports-dir> <output-file>',
    );
    exit(64);
  }

  final reportFiles = Directory(args.first)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final packages = [
    for (final file in reportFiles) _PackageReport.parse(file),
  ];

  File(args.last).writeAsStringSync(_render(packages));
}

class _TestResult {
  const _TestResult(this.name, this.result, this.skipped);

  final String name;
  final String result; // success | failure | error
  final bool skipped;

  bool get failed => result != 'success' && !skipped;
}

class _PackageReport {
  _PackageReport(this.name);

  /// Package name, derived from the report file name
  /// (e.g. `clerk_auth.json` -> `clerk_auth`).
  final String name;

  /// Test results keyed by display path of the test file.
  final byFile = <String, List<_TestResult>>{};

  int get total => byFile.values.fold(0, (sum, tests) => sum + tests.length);

  int get failed => byFile.values
      .fold(0, (sum, tests) => sum + tests.where((t) => t.failed).length);

  int get successRate => total == 0 ? 100 : ((total - failed) * 100) ~/ total;

  static _PackageReport parse(File file) {
    final fileName = file.uri.pathSegments.last;
    final report =
        _PackageReport(fileName.substring(0, fileName.length - '.json'.length));

    final suitePaths = <int, String>{};
    final groupNames = <int, String>{};
    final testsById = <int, Map<String, dynamic>>{};

    for (final line in file.readAsLinesSync()) {
      if (line.trim().isEmpty) continue;

      final Map<String, dynamic> event;
      try {
        event = json.decode(line) as Map<String, dynamic>;
      } on FormatException {
        continue; // tolerate non-JSON noise in the report file
      }

      switch (event['type']) {
        case 'suite':
          final suite = event['suite'] as Map<String, dynamic>;
          suitePaths[suite['id'] as int] =
              _displayPath(suite['path'] as String? ?? '');

        case 'group':
          final group = event['group'] as Map<String, dynamic>;
          groupNames[group['id'] as int] = group['name'] as String? ?? '';

        case 'testStart':
          final test = event['test'] as Map<String, dynamic>;
          testsById[test['id'] as int] = test;

        case 'testDone':
          // Hidden tests are bookkeeping entries (e.g. suite loading).
          if (event['hidden'] == true) continue;
          final test = testsById[event['testID']];
          if (test == null) continue;
          final path = suitePaths[test['suiteID']] ?? '(unknown file)';
          report.byFile.putIfAbsent(path, () => []).add(
                _TestResult(
                  _displayName(test, groupNames),
                  event['result'] as String? ?? 'error',
                  event['skipped'] == true,
                ),
              );
      }
    }

    return report;
  }

  /// Path of a test file relative to its package root.
  static String _displayPath(String path) {
    for (final marker in ['integration_test/', 'test/']) {
      if (path.startsWith(marker)) return path;
      final index = path.indexOf('/$marker');
      if (index >= 0) return path.substring(index + 1);
    }
    return path.split('/').last;
  }

  /// Test name with its group prefix separated by ` · `.
  ///
  /// Group names and test names are cumulative in the JSON reporter output
  /// (each includes its ancestors' names), so successive prefixes are
  /// stripped to recover the bare name of each level.
  static String _displayName(
    Map<String, dynamic> test,
    Map<int, String> groupNames,
  ) {
    final segments = <String>[];
    var cumulative = '';

    for (final id in (test['groupIDs'] as List?)?.cast<int>() ?? const []) {
      final fullName = groupNames[id] ?? '';
      if (fullName.isEmpty) continue;
      var segment = fullName;
      if (cumulative.isNotEmpty && fullName.startsWith(cumulative)) {
        segment = fullName.substring(cumulative.length).trim();
      }
      if (segment.isNotEmpty) segments.add(segment);
      cumulative = fullName;
    }

    var bareName = test['name'] as String? ?? '';
    if (cumulative.isNotEmpty && bareName.startsWith(cumulative)) {
      bareName = bareName.substring(cumulative.length).trim();
    }

    return [...segments, if (bareName.isNotEmpty) bareName].join(' · ');
  }
}

String _render(List<_PackageReport> packages) {
  final anyFailures = packages.any((p) => p.failed > 0);
  final lines = <String>[
    if (anyFailures) ...[
      '[!CAUTION]',
      'At least one test failed. Please review the test results below.',
    ] else ...[
      '[!NOTE]',
      'All tests passed.',
    ],
    '',
    '<details>',
    '<summary><b>View Test Results</b></summary>',
    '',
    '| Package | Number of Tests | Success Rate |',
    '| :--- | :--- | :--- |',
    for (final package in packages)
      '| ${_cell(package.name)} | ${package.total} | ${package.successRate}% |',
    for (final package in packages.where((p) => p.failed > 0))
      ..._renderPackageBreakdown(package),
    '',
    '</details>',
  ];

  return lines.map((line) => line.isEmpty ? '>' : '> $line').join('\n');
}

Iterable<String> _renderPackageBreakdown(_PackageReport package) sync* {
  yield '';
  yield '<details>';
  yield '<summary>📂 <b>${_cell(package.name)}</b></summary>';

  // Only files containing at least one failing test are listed, so the
  // breakdown stays skimmable.
  final failingFiles = package.byFile.entries
      .where((entry) => entry.value.any((test) => test.failed))
      .toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  for (final entry in failingFiles) {
    yield '';
    yield '### ${entry.key}';
    yield '';
    yield '| Test | Result |';
    yield '| :--- | :--- |';
    for (final test in entry.value) {
      final name = test.failed ? _redText(test.name) : _cell(test.name);
      final icon = test.failed ? '❌' : (test.skipped ? '⏭️' : '✅');
      yield '| $name | $icon |';
    }
  }

  yield '';
  yield '</details>';
}

/// Escapes a value for use inside a markdown table cell.
String _cell(String value) => value.replaceAll('|', r'\|');

/// Renders a failing test name in red via GitHub's LaTeX support.
String _redText(String value) {
  final escaped = value
      .replaceAll(RegExp(r'[\\~^|]'), ' ')
      .replaceAllMapped(RegExp(r'[#$%&_{}]'), (m) => '\\${m[0]}');
  return '\$\\color{red}{\\text{$escaped}}\$';
}
