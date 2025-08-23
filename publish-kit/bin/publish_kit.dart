import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';
import 'package:publish_kit/publish_kit.dart';

void main(List<String> arguments) async {
  final parser =
      ArgParser()
        ..addOption(
          'command',
          abbr: 'c',
          help:
              'Command to run: update-version, copy-readme, tag, update-deps, commit-release, publish, or all',
        )
        ..addFlag(
          'dry-run',
          abbr: 'd',
          help: 'Perform a dry run without making changes',
        )
        ..addFlag('help', abbr: 'h', help: 'Show help');

  late ArgResults results;
  try {
    results = parser.parse(arguments);
  } catch (e) {
    print('Error parsing arguments: $e');
    print(parser.usage);
    exit(1);
  }

  if (results['help'] as bool) {
    print('Froom Package Publisher');
    print('Usage: dart bin/publish_kit.dart -c <command> [options]');
    print('');
    print('Commands:');
    print('  update-version - Update package versions from version.txt');
    print('  copy-readme    - Copy README.md from root to sub-projects');
    print(
      '  tag            - Commit changes, merge to main, and create version tag',
    );
    print(
      '  update-deps    - Update inter-package dependencies to version format',
    );
    print('  commit-release - Create release branch and commit changes');
    print('  publish        - Publish packages to pub.dev');
    print('  all            - Run all commands in sequence');
    print('');
    print('Options:');
    print(parser.usage);
    return;
  }

  final command = results['command'] as String?;
  final dryRun = results['dry-run'] as bool;

  if (command == null) {
    print('Error: Command is required. Use -h for help.');
    exit(1);
  }

  // Get the root directory (parent of publish-kit)
  final scriptPath = Platform.script.toFilePath();
  final publishKitDir = path.dirname(path.dirname(scriptPath));
  final rootPath = path.dirname(publishKitDir);

  final publishKit = PublishKit(rootPath, dryRun: dryRun);

  try {
    switch (command) {
      case 'update-version':
        await runUpdateVersion(publishKit);
        break;
      case 'copy-readme':
        await runCopyReadme(publishKit);
        break;
      case 'tag':
        await runTag(publishKit);
        break;
      case 'update-deps':
        await runUpdateDeps(publishKit);
        break;
      case 'commit-release':
        await runCommit(publishKit);
        break;
      case 'publish':
        await runPublish(publishKit);
        break;
      case 'all':
        await runAll(publishKit);
        break;
      default:
        print('Error: Unknown command "$command". Use -h for help.');
        exit(1);
    }

    print('Command completed successfully!');
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

Future<void> runUpdateVersion(PublishKit publishKit) async {
  final version = await publishKit.readVersionFile();
  print('Read version: $version');

  await publishKit.updatePackageVersions(version);
}

Future<void> runUpdateDeps(PublishKit publishKit) async {
  final version = await publishKit.readVersionFile();
  print('Read version: $version');

  await publishKit.updateDependencies(version);
}

Future<void> runCommit(PublishKit publishKit) async {
  final version = await publishKit.readVersionFile();
  await publishKit.createReleaseCommit(version);
}

Future<void> runPublish(PublishKit publishKit) async {
  await publishKit.publishPackages();
}

Future<void> runTag(PublishKit publishKit) async {
  final version = await publishKit.readVersionFile();
  await publishKit.createTagAndMergeToMain(version);
}

Future<void> runCopyReadme(PublishKit publishKit) async {
  await publishKit.copyReadme();
}

Future<void> runAll(PublishKit publishKit) async {
  await runUpdateVersion(publishKit);
  await runCopyReadme(publishKit);
  await runTag(publishKit);
  await runUpdateDeps(publishKit);
  await runCommit(publishKit);
  await runPublish(publishKit);
}
