import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml_edit/yaml_edit.dart';

class PublishKit {
  static const List<String> publishOrder = [
    'froom_annotation',
    'froom_generator',
    'froom_common',
    'froom',
  ];

  final String rootPath;
  final bool dryRun;

  PublishKit(this.rootPath, {this.dryRun = false});

  Future<String> readVersionFile() async {
    final versionFile = File(path.join(rootPath, 'version.txt'));
    if (!await versionFile.exists()) {
      throw Exception('version.txt not found');
    }
    return (await versionFile.readAsString()).trim();
  }

  Future<void> updatePackageVersions(String version) async {
    print('Updating package versions to $version...');

    // First, check and sync CHANGELOG.md
    await _syncChangelog(version);

    for (final packageName in publishOrder) {
      final pubspecPath = path.join(rootPath, packageName, 'pubspec.yaml');
      final pubspecFile = File(pubspecPath);

      if (!await pubspecFile.exists()) {
        throw Exception('pubspec.yaml not found for $packageName');
      }

      final content = await pubspecFile.readAsString();

      // Update version
      final newContent = content.replaceFirst(
        RegExp(r'^version: .*$', multiLine: true),
        'version: $version',
      );

      if (!dryRun) {
        await pubspecFile.writeAsString(newContent);
      }
      print(
        '${dryRun ? "[DRY RUN] " : ""}Updated $packageName version to $version',
      );
    }
  }

  Future<void> _syncChangelog(String version) async {
    print('Checking and syncing CHANGELOG.md...');

    final rootChangelogPath = path.join(rootPath, 'CHANGELOG.md');
    final rootChangelogFile = File(rootChangelogPath);

    if (!await rootChangelogFile.exists()) {
      print('Warning: Root CHANGELOG.md not found, skipping sync');
      return;
    }

    final rootContent = await rootChangelogFile.readAsString();

    // Check if the version exists in root CHANGELOG
    if (!rootContent.contains('## $version')) {
      throw Exception(
        'Version $version not found in root CHANGELOG.md. Please add changelog entry for version $version first.',
      );
    }

    print('✓ Found version $version in root CHANGELOG.md');

    // Extract the changelog entry for this version
    final versionEntry = _extractVersionEntry(rootContent, version);

    // Sync to each package
    for (final packageName in publishOrder) {
      final packageChangelogPath = path.join(
        rootPath,
        packageName,
        'CHANGELOG.md',
      );
      final packageChangelogFile = File(packageChangelogPath);

      if (!await packageChangelogFile.exists()) {
        print('Warning: $packageName/CHANGELOG.md not found, skipping');
        continue;
      }

      String packageContent = await packageChangelogFile.readAsString();

      // Check if version already exists in package changelog
      if (packageContent.contains('## $version')) {
        print('Version $version already exists in $packageName/CHANGELOG.md');
        continue;
      }

      // Insert the new version entry at the top (after # Changelog)
      final lines = packageContent.split('\n');
      final insertIndex = lines.indexWhere((line) => line.startsWith('## '));

      if (insertIndex == -1) {
        // No existing version entries, add after "# Changelog"
        final headerIndex = lines.indexWhere(
          (line) => line.trim() == '# Changelog',
        );
        if (headerIndex != -1) {
          lines.insertAll(headerIndex + 1, ['', versionEntry, '']);
        }
      } else {
        // Insert before first existing version
        lines.insertAll(insertIndex, [versionEntry, '']);
      }

      final newPackageContent = lines.join('\n');

      if (!dryRun) {
        await packageChangelogFile.writeAsString(newPackageContent);
      }

      print(
        '${dryRun ? "[DRY RUN] " : ""}Synced CHANGELOG.md for $packageName',
      );
    }
  }

  String _extractVersionEntry(String content, String version) {
    final lines = content.split('\n');
    final startIndex = lines.indexWhere((line) => line.trim() == '## $version');

    if (startIndex == -1) {
      throw Exception('Version $version not found in CHANGELOG.md');
    }

    // Find the end of this version entry (next ## or end of file)
    int endIndex = lines.length;
    for (int i = startIndex + 1; i < lines.length; i++) {
      if (lines[i].startsWith('## ')) {
        endIndex = i;
        break;
      }
    }

    // Extract the version entry (without trailing empty lines)
    final entry = lines.sublist(startIndex, endIndex);
    while (entry.isNotEmpty && entry.last.trim().isEmpty) {
      entry.removeLast();
    }

    return entry.join('\n');
  }

  Future<void> updateDependencies(String version) async {
    print('Updating inter-package dependencies...');

    final dependencyMap = {
      'froom_generator': ['froom_annotation'],
      'froom_common': ['froom_annotation', 'froom_generator'],
      'froom': ['froom_annotation', 'froom_common', 'froom_generator'],
    };

    for (final packageName in publishOrder) {
      final deps = dependencyMap[packageName];
      if (deps == null) continue;

      final pubspecPath = path.join(rootPath, packageName, 'pubspec.yaml');
      final pubspecFile = File(pubspecPath);

      String content = await pubspecFile.readAsString();

      // Use yaml_edit to preserve formatting
      final yamlEditor = YamlEditor(content);
      yamlEditor.remove(['publish_to']);

      // Update dependencies
      for (final dep in deps) {
        final isDevDep = dep == 'froom_generator';
        final sectionKey = isDevDep ? 'dev_dependencies' : 'dependencies';

        // Update the dependency to version format
        yamlEditor.update([sectionKey, dep], '^$version');
      }

      content = yamlEditor.toString();

      if (!dryRun) {
        await pubspecFile.writeAsString(content);
      }
      print(
        '${dryRun ? "[DRY RUN] " : ""}Updated dependencies for $packageName',
      );
    }
  }

  Future<void> createReleaseCommit(String version) async {
    print('Creating release commit...');

    final branchName = 'release/$version';
    final commitMessage = 'chore: release version $version';

    if (dryRun) {
      print('[DRY RUN] Would create release branch: $branchName');
      print('[DRY RUN] Would add all changes');
      print('[DRY RUN] Would commit with message: $commitMessage');
      return;
    }

    // Check if release branch already exists
    final branchCheck = await _runGitCommand(['branch', '--list', branchName]);
    if (branchCheck.stdout.toString().trim().isNotEmpty) {
      print('Release branch $branchName already exists, switching to it...');
      final result = await _runGitCommand(['checkout', branchName]);
      if (result.exitCode != 0) {
        throw Exception(
          'Failed to checkout existing release branch: ${result.stderr}',
        );
      }
    } else {
      // Create and checkout release branch
      final result1 = await _runGitCommand(['checkout', '-b', branchName]);
      if (result1.exitCode != 0) {
        throw Exception('Failed to create release branch: ${result1.stderr}');
      }
    }

    // Check if there are any changes to commit
    final statusResult = await _runGitCommand(['status', '--porcelain']);
    if (statusResult.stdout.toString().trim().isEmpty) {
      print('No changes to commit');
      return;
    }

    // Add all changes
    final result2 = await _runGitCommand(['add', '.']);
    if (result2.exitCode != 0) {
      throw Exception('Failed to add changes: ${result2.stderr}');
    }

    // Commit changes
    final result3 = await _runGitCommand(['commit', '-m', commitMessage]);
    if (result3.exitCode != 0) {
      // Check if it's because there's nothing to commit
      final errorMsg = result3.stderr.toString();
      if (errorMsg.contains('nothing to commit')) {
        print('No changes to commit');
        return;
      }
      throw Exception('Failed to commit changes: $errorMsg');
    }

    print('Created release branch: $branchName');
  }

  Future<void> publishPackages() async {
    // Remember current branch to restore later
    final originalBranch = await _getCurrentBranch();

    try {
      print('Publishing packages to pub.dev...');
      final version = await readVersionFile();

      for (int i = 0; i < publishOrder.length; i++) {
        final packageName = publishOrder[i];
        final packagePath = path.join(rootPath, packageName);

        // Check if package is already published
        if (await _isPackageAlreadyPublished(packageName, version)) {
          print(
            '✓ $packageName version $version already published, skipping...',
          );
          continue;
        }

        print('Publishing $packageName...');

        final result = await Process.run('dart', [
          'pub',
          'publish',
          dryRun ? '--dry-run' : '--force',
        ], workingDirectory: packagePath);

        if (result.exitCode != 0) {
          final errorMsg = result.stderr.toString();

          // Check if it's already published error
          if (errorMsg.contains('already exists')) {
            print(
              '✓ $packageName version $version already published, skipping...',
            );
            continue;
          }

          throw Exception('Failed to publish $packageName: $errorMsg');
        }

        print(
          '${dryRun ? "[DRY RUN] " : ""}Successfully published $packageName',
        );

        // Wait for dependencies to be available before publishing next package
        if (!dryRun && i < publishOrder.length - 1) {
          final nextPackage = publishOrder[i + 1];
          final version = await readVersionFile();
          final targetBranch = 'release/$version';
          await _waitForDependencies(nextPackage, targetBranch);
        }
      }
    } finally {
      // Restore original branch if changed
      await _restoreBranch(originalBranch);
    }
  }

  Future<String> _getCurrentBranch() async {
    final result = await Process.run('git', [
      'branch',
      '--show-current',
    ], workingDirectory: rootPath);
    if (result.exitCode == 0) {
      return result.stdout.toString().trim();
    }
    return 'main'; // fallback
  }

  Future<void> _restoreBranch(String originalBranch) async {
    if (dryRun) return;

    final currentBranch = await _getCurrentBranch();
    if (currentBranch != originalBranch) {
      print('Restoring to original branch: $originalBranch');
      final result = await Process.run('git', [
        'checkout',
        originalBranch,
      ], workingDirectory: rootPath);
      if (result.exitCode != 0) {
        print('Warning: Failed to restore original branch: ${result.stderr}');
      }
    }
  }

  Future<bool> _isPackageAlreadyPublished(
    String packageName,
    String version,
  ) async {
    if (dryRun) return false;

    try {
      // Try to publish with --dry-run to check if version already exists
      final result = await Process.run('dart', [
        'pub',
        'publish',
        '--dry-run',
      ], workingDirectory: path.join(rootPath, packageName));

      // If dry-run fails with "already exists" message, the package is published
      if (result.exitCode != 0) {
        final errorMsg = result.stderr.toString();
        if (errorMsg.contains('already exists') ||
            errorMsg.contains(
              'Version $version of package $packageName already exists',
            )) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _waitForDependencies(
    String packageName,
    String targetBranch,
  ) async {
    final dependencyMap = {
      'froom_generator': ['froom_annotation'],
      'froom_common': ['froom_annotation', 'froom_generator'],
      'froom': ['froom_annotation', 'froom_common', 'froom_generator'],
    };

    final deps = dependencyMap[packageName];
    if (deps == null || deps.isEmpty) return;

    print('Waiting for dependencies to be available for $packageName...');

    final packagePath = path.join(rootPath, packageName);
    int attempts = 0;
    const maxAttempts = 30; // Maximum 15 minutes (30 * 30 seconds)

    while (attempts < maxAttempts) {
      attempts++;

      // Check and ensure we're on the correct branch before each attempt
      await _ensureCorrectBranch(targetBranch);

      print(
        'Attempt $attempts/$maxAttempts: Running dart pub get for $packageName...',
      );

      final result = await Process.run('dart', [
        'pub',
        'get',
      ], workingDirectory: packagePath);

      if (result.exitCode == 0) {
        print('✓ Dependencies resolved successfully for $packageName');
        return;
      }

      print('Dependencies not yet available. Waiting 30 seconds...');
      await Future.delayed(Duration(seconds: 30));
    }

    throw Exception(
      'Timeout waiting for dependencies to be available for $packageName after ${maxAttempts * 30} seconds',
    );
  }

  Future<void> _ensureCorrectBranch(String targetBranch) async {
    final currentBranch = await _getCurrentBranch();

    if (currentBranch != targetBranch) {
      print(
        '⚠️ Branch changed to $currentBranch, switching back to $targetBranch...',
      );

      final result = await _runGitCommand(['checkout', targetBranch]);
      if (result.exitCode != 0) {
        print(
          'Warning: Failed to switch back to $targetBranch: ${result.stderr}',
        );
        print('Please manually switch to the correct branch if needed.');
      } else {
        print('✓ Switched back to $targetBranch');
      }
    }
  }

  Future<void> createTagAndMergeToMain(String version) async {
    print('Creating tag and merging to main...');

    if (dryRun) {
      print('[DRY RUN] Would commit current changes');
      print('[DRY RUN] Would merge to main branch');
      print('[DRY RUN] Would switch to main branch');
      print('[DRY RUN] Would create tag: v$version');
      return;
    }

    // Get current branch
    final currentBranch = await _getCurrentBranch();

    // Check if there are any changes to commit
    final statusResult = await _runGitCommand(['status', '--porcelain']);
    if (statusResult.stdout.toString().trim().isNotEmpty) {
      // Add and commit current changes
      print('Committing current changes...');
      final addResult = await _runGitCommand(['add', '.']);
      if (addResult.exitCode != 0) {
        throw Exception('Failed to add changes: ${addResult.stderr}');
      }

      final commitResult = await _runGitCommand([
        'commit',
        '-m',
        'chore: update versions and dependencies for v$version',
      ]);
      if (commitResult.exitCode != 0) {
        final errorMsg = commitResult.stderr.toString();
        if (!errorMsg.contains('nothing to commit')) {
          throw Exception('Failed to commit changes: $errorMsg');
        }
      }
      print('✓ Changes committed');
    }

    // Switch to main branch
    print('Switching to main branch...');
    final checkoutMainResult = await _runGitCommand(['checkout', 'main']);
    if (checkoutMainResult.exitCode != 0) {
      throw Exception(
        'Failed to checkout main branch: ${checkoutMainResult.stderr}',
      );
    }
    print('✓ Switched to main branch');

    // Merge current branch to main (if not already on main)
    if (currentBranch != 'main') {
      print('Merging $currentBranch to main...');
      final mergeResult = await _runGitCommand(['merge', currentBranch]);
      if (mergeResult.exitCode != 0) {
        throw Exception(
          'Failed to merge $currentBranch to main: ${mergeResult.stderr}',
        );
      }
      print('✓ Merged $currentBranch to main');
    }

    // Create and push tag
    final tagName = 'v$version';
    print('Creating tag $tagName...');

    // Check if tag already exists
    final tagCheckResult = await _runGitCommand(['tag', '-l', tagName]);
    if (tagCheckResult.stdout.toString().trim().isNotEmpty) {
      print('Tag $tagName already exists, deleting and recreating...');
      await _runGitCommand(['tag', '-d', tagName]);
    }

    final tagResult = await _runGitCommand([
      'tag',
      '-a',
      tagName,
      '-m',
      'Release version $version',
    ]);
    if (tagResult.exitCode != 0) {
      throw Exception('Failed to create tag: ${tagResult.stderr}');
    }
    print('✓ Created tag $tagName');

    // Push main branch and tag
    print('Pushing main branch and tag...');
    final pushResult = await _runGitCommand(['push', 'origin', 'main']);
    if (pushResult.exitCode != 0) {
      print('Warning: Failed to push main branch: ${pushResult.stderr}');
    }

    final pushTagResult = await _runGitCommand(['push', 'origin', tagName]);
    if (pushTagResult.exitCode != 0) {
      print('Warning: Failed to push tag: ${pushTagResult.stderr}');
    } else {
      print('✓ Pushed main branch and tag');
    }
  }

  Future<void> copyReadme() async {
    print('Copying README.md to sub-projects...');

    final rootReadmePath = path.join(rootPath, 'README.md');
    final rootReadmeFile = File(rootReadmePath);

    if (!await rootReadmeFile.exists()) {
      throw Exception('Root README.md not found');
    }

    final rootContent = await rootReadmeFile.readAsString();

    for (final packageName in publishOrder) {
      final packageReadmePath = path.join(rootPath, packageName, 'README.md');
      final packageReadmeFile = File(packageReadmePath);

      // Update language links to point to root directory
      String modifiedContent = _updateLanguageLinks(rootContent);

      if (!dryRun) {
        await packageReadmeFile.writeAsString(modifiedContent);
      }

      print(
        '${dryRun ? "[DRY RUN] " : ""}Copied README.md to $packageName (with updated language links)',
      );
    }

    print('${dryRun ? "[DRY RUN] " : ""}README.md copying completed');
  }

  String _updateLanguageLinks(String content) {
    // Pattern to match language links like [中文](README_zh.md), [Español](README_es.md), etc.
    // This regex captures:
    // - Text in square brackets (language name)
    // - Parentheses with README_xx.md pattern (where xx is language code)
    final languageLinkPattern = RegExp(
      r'\[([^\]]+)\]\((README_[a-z]{2}(?:_[A-Z]{2})?\.md)\)',
    );

    return content.replaceAllMapped(languageLinkPattern, (match) {
      final languageName = match.group(1)!; // e.g., "中文", "Español"
      final filename = match.group(2)!; // e.g., "README_zh.md", "README_es.md"

      // Update the path to point to root directory
      return '[$languageName](../$filename)';
    });
  }

  Future<ProcessResult> _runGitCommand(List<String> args) async {
    return await Process.run('git', args, workingDirectory: rootPath);
  }
}
