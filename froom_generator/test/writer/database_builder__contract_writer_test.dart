import 'package:code_builder/code_builder.dart';
import 'package:froom_generator/writer/database_builder_contract_writer.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  useDartfmt();

  test('generate database builder contract', () async {
    const databaseName = 'FooBar';

    final actual = DatabaseBuilderContractWriter(databaseName).write();

    expect(actual, equalsDart(r'''
      abstract class $FooBarBuilderContract {
        /// Adds migrations to the builder.
        $FooBarBuilderContract addMigrations(List<Migration> migrations);
      
        /// Adds a database [Callback] to the builder.
        $FooBarBuilderContract addCallback(Callback callback);
      
        /// Recreates the database instead of crashing when there is no migration
        /// from its version to the current one, deleting all of its data.
        $FooBarBuilderContract fallbackToDestructiveMigration();
      
        /// Creates the database and initializes it.
        Future<FooBar> build();
      }      
    '''));
  });
}
