import 'package:code_builder/code_builder.dart';
import 'package:froom_generator/writer/code_writer.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  useDartfmt();

  test('generate froom database builder access class', () async {
    const databaseName = 'FooBar';

    final actual = CodeWriter(databaseName).write();

    expect(actual, equalsDart(r'''
      // ignore: avoid_classes_with_only_static_members
      class $FroomFooBar {
        /// Creates a database builder for a persistent database.
        /// Once a database is built, you should keep a reference to it and re-use it.
        static $FooBarBuilderContract databaseBuilder(String name) =>
            _$FooBarBuilder(name);
      
        /// Creates a database builder for an in memory database.
        /// Information stored in an in memory database disappears when the process is killed.
        /// Once a database is built, you should keep a reference to it and re-use it.
        static $FooBarBuilderContract inMemoryDatabaseBuilder() =>
            _$FooBarBuilder(null);
      }   
    '''));
  });
}
