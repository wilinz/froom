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
        'Version $version not found in root CHANGELOG.md. Please add changelog entry for version $version first.'
      );
    }
    
    print('✓ Found version $version in root CHANGELOG.md');
    
    // Extract the changelog entry for this version
    final versionEntry = _extractVersionEntry(rootContent, version);
    
    // Sync to each package
    for (final packageName in publishOrder) {
      final packageChangelogPath = path.join(rootPath, packageName, 'CHANGELOG.md');
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
        final headerIndex = lines.indexWhere((line) => line.trim() == '# Changelog');
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
      
      print('${dryRun ? "[DRY RUN] " : ""}Synced CHANGELOG.md for $packageName');
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

    // Create and checkout release branch
    final result1 = await _runGitCommand(['checkout', '-b', branchName]);
    if (result1.exitCode != 0) {
      throw Exception('Failed to create release branch: ${result1.stderr}');
    }

    // Add all changes
    final result2 = await _runGitCommand(['add', '.']);
    if (result2.exitCode != 0) {
      throw Exception('Failed to add changes: ${result2.stderr}');
    }

    // Commit changes
    final result3 = await _runGitCommand(['commit', '-m', commitMessage]);
    if (result3.exitCode != 0) {
      throw Exception('Failed to commit changes: ${result3.stderr}');
    }

    print('Created release branch: $branchName');
  }

  Future<void> publishPackages() async {
    print('Publishing packages to pub.dev...');

    for (int i = 0; i < publishOrder.length; i++) {
      final packageName = publishOrder[i];
      final packagePath = path.join(rootPath, packageName);

      print('Publishing $packageName...');

      final result = await Process.run('dart', [
        'pub',
        'publish',
        dryRun ? '--dry-run' : '--force',
      ], workingDirectory: packagePath);

      if (result.exitCode != 0) {
        throw Exception('Failed to publish $packageName: ${result.stderr}');
      }

      print('${dryRun ? "[DRY RUN] " : ""}Successfully published $packageName');

      // Wait for dependencies to be available before publishing next package
      if (!dryRun && i < publishOrder.length - 1) {
        final nextPackage = publishOrder[i + 1];
        await _waitForDependencies(nextPackage);
      }
    }
  }
  
  Future<void> _waitForDependencies(String packageName) async {
    final dependencyMap = {
      'froom_generator': ['froom_annotation'],
      'froom_common': ['froom_annotation', 'froom_generator'], 
      'froom': ['froom_annotation', 'froom_common', 'froom_generator']
    };
    
    final deps = dependencyMap[packageName];
    if (deps == null || deps.isEmpty) return;
    
    print('Waiting for dependencies to be available for $packageName...');
    
    final packagePath = path.join(rootPath, packageName);
    int attempts = 0;
    const maxAttempts = 30; // Maximum 15 minutes (30 * 30 seconds)
    
    while (attempts < maxAttempts) {
      attempts++;
      print('Attempt $attempts/$maxAttempts: Running dart pub get for $packageName...');
      
      final result = await Process.run(
        'dart',
        ['pub', 'get'],
        workingDirectory: packagePath,
      );
      
      if (result.exitCode == 0) {
        print('✓ Dependencies resolved successfully for $packageName');
        return;
      }
      
      print('Dependencies not yet available. Waiting 30 seconds...');
      await Future.delayed(Duration(seconds: 30));
    }
    
    throw Exception(
      'Timeout waiting for dependencies to be available for $packageName after ${maxAttempts * 30} seconds'
    );
  }

  Future<ProcessResult> _runGitCommand(List<String> args) async {
    return await Process.run('git', args, workingDirectory: rootPath);
  }
}
