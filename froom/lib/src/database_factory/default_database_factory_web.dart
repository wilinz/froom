import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// The database factory of databases which aren't opened by another factory
/// of their builder, which is the FFI one of the web.
///
/// It requires the SQLite WebAssembly binary and worker set up by
/// `dart run sqflite_common_ffi_web:setup`.
final DatabaseFactory sqfliteDatabaseFactory = databaseFactoryFfiWeb;
