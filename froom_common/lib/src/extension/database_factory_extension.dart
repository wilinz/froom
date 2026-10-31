import 'package:path/path.dart';
import 'package:sqflite_common/sqlite_api.dart';

extension DatabaseFactoryExtension on DatabaseFactory {
  /// The path of the database named [name] in the databases directory of
  /// the factory.
  Future<String> getDatabasePath(final String name) async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, name);
  }
}
