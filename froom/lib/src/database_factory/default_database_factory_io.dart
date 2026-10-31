import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The database factory of databases which aren't opened by another factory
/// of their builder.
///
/// On Android and iOS, it's the factory of the sqflite plugin, which registers
/// itself as the global `databaseFactory` of sqflite when the app depends on
/// `sqflite`. On the other platforms, it's the FFI one.
DatabaseFactory get sqfliteDatabaseFactory {
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      return databaseFactory;
    } on StateError {
      // an FFI fallback would store databases in the working directory, and
      // could differ from the plugin used by other isolates
      throw StateError(
        'The sqflite plugin is not registered, which is the default database '
        'factory on Android and iOS. Add the sqflite package to the '
        'dependencies of the app, call DartPluginRegistrant.ensureInitialized() '
        'in background isolates, or pass a database factory to the builder, '
        'e.g. databaseFactory(databaseFactoryFfi) with an absolute path.',
      );
    }
  }
  return _databaseFactoryFfi;
}

final _databaseFactoryFfi = () {
  sqfliteFfiInit();
  return databaseFactoryFfi;
}();
