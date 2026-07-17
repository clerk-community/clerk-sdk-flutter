import 'dart:io';

const _packages = ['clerk_auth', 'clerk_backend_api', 'clerk_flutter'];
const _packagePaths = {
  'clerk_auth': 'packages/clerk_auth',
  'clerk_backend_api': 'packages/clerk_backend_api',
  'clerk_flutter': 'packages/clerk_flutter',
};

Future<void> main(List<String> args) async {
  final root = Directory.current.path;

  // Guard: must be on main to avoid orphaned tags after a squash-merge.
  final branchResult = await Process.run(
    'git',
    ['branch', '--show-current'],
    workingDirectory: root,
  );
  final branch = (branchResult.stdout as String).trim();
  if (branch != 'main') {
    stderr.writeln(
      'ERROR: melos run tag must be run on main (currently on "$branch").\n'
      'Merge the release PR first:\n'
      '  git checkout main && git pull && melos run tag',
    );
    exit(1);
  }

  // Read current version from each pubspec.yaml and verify they all match.
  final versions = <String, String>{};
  for (final pkg in _packages) {
    final file = File('$root/${_packagePaths[pkg]!}/pubspec.yaml');
    final content = await file.readAsString();
    final m = RegExp(r'^version:\s*(.+)$', multiLine: true).firstMatch(content);
    versions[pkg] = m!.group(1)!.trim();
  }

  final unique = versions.values.toSet();
  if (unique.length != 1) {
    stderr.writeln('ERROR: packages have mismatched versions:');
    versions.forEach((k, v) => stderr.writeln('  $k: $v'));
    exit(1);
  }
  final version = unique.first;

  stdout.writeln('Tagging release v$version...');

  for (final pkg in _packages) {
    await _tag('$pkg-v$version', 'Release $pkg $version', root);
  }
  await _tag('v$version', 'Release v$version', root);

  // GitHub creates no push event when more than three tags arrive in a
  // single push, so pushing all four tags via `--tags` never triggers the
  // publish workflow. Push the package tags first, then the trigger tag on
  // its own — its push event starts the workflow with all tags in place.
  stdout.writeln('\nPushing tags...');
  final pushes = [
    ['push', 'origin', for (final pkg in _packages) '$pkg-v$version'],
    ['push', 'origin', 'v$version'],
  ];
  for (final args in pushes) {
    final pushResult = await Process.run(
      'git',
      args,
      workingDirectory: root,
    );
    if (pushResult.exitCode != 0) {
      stderr.writeln('git ${args.join(' ')} failed:\n${pushResult.stderr}');
      exit(1);
    }
  }

  stdout.writeln('\nDone! Tags pushed — pub.dev publish workflow will start shortly.');
  for (final pkg in _packages) {
    stdout.writeln('  $pkg-v$version');
  }
  stdout.writeln('  v$version  ← global trigger');
}

Future<void> _tag(String name, String message, String root) async {
  final result = await Process.run(
    'git',
    ['tag', '-a', name, '-m', message],
    workingDirectory: root,
  );
  if (result.exitCode != 0) {
    stderr.writeln('Failed to create tag $name:\n${result.stderr}');
    exit(1);
  }
  stdout.writeln('  $name');
}
