import 'package:code_builder/code_builder.dart';
import 'package:froom_generator/writer/database_builder_writer.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  useDartfmt();

  test('generate database builder', () async {
    const databaseName = 'FooBar';

    final actual = DatabaseBuilderWriter(databaseName).write();

    expect(actual, equalsDart(r'''
      class _$FooBarBuilder implements $FooBarBuilderContract {
        _$FooBarBuilder(this.name);
      
        final String? name;
      
        final List<Migration> _migrations = [];

        Callback? _callback;

        bool _fallbackToDestructiveMigration = false;

        sqflite.DatabaseFactory? _databaseFactory;
      
        @override
        $FooBarBuilderContract addMigrations(List<Migration> migrations) {
          _migrations.addAll(migrations);
          return this;
        }

        @override
        $FooBarBuilderContract addCallback(Callback callback) {
          _callback = callback;
          return this;
        }

        @override
        $FooBarBuilderContract fallbackToDestructiveMigration() {
          _fallbackToDestructiveMigration = true;
          return this;
        }

        @override
        $FooBarBuilderContract databaseFactory(
            sqflite.DatabaseFactory databaseFactory) {
          _databaseFactory = databaseFactory;
          return this;
        }

        @override
        Future<FooBar> build() async {
          final databaseFactory = _databaseFactory ?? sqfliteDatabaseFactory;
          final path = name != null
            ? await databaseFactory.getDatabasePath(name!)
            : ':memory:'; 
          final database = _$FooBar();
          database.database = await database.open(
            databaseFactory,
            path,
            _migrations,
            _callback,
            _fallbackToDestructiveMigration,
          );
          return database;
        }
      }      
    '''));
  });
}
