import 'package:froom_generator/value_object/index.dart';
import 'package:test/test.dart';

void main() {
  test('create index', () {
    const name = 'foo';
    const tableName = 'bar';
    const unique = false;
    const columnNames = ['baz', 'off'];

    final actual = Index(name, tableName, unique, columnNames).createQuery();

    final expected =
        'CREATE INDEX IF NOT EXISTS `$name` ON `$tableName` (${columnNames.map((name) => '`$name`').join(', ')})';
    expect(actual, equals(expected));
  });

  test('create unique index', () {
    const name = 'foo';
    const tableName = 'bar';
    const unique = true;
    const columnNames = ['baz', 'off'];

    final actual = Index(name, tableName, unique, columnNames).createQuery();

    final expected =
        'CREATE UNIQUE INDEX IF NOT EXISTS `$name` ON `$tableName` (${columnNames.map((name) => '`$name`').join(', ')})';
    expect(actual, equals(expected));
  });

  test('create partial index', () {
    final actual = Index('foo', 'bar', true, ['email'],
            where: 'email IS NOT NULL')
        .createQuery();

    expect(
      actual,
      equals(
          'CREATE UNIQUE INDEX IF NOT EXISTS `foo` ON `bar` (`email`) WHERE email IS NOT NULL'),
    );
  });

  test('create index on expressions', () {
    final actual = Index('foo', 'bar', false, ['y + z', 'lower(name)', 'id'],
        expressions: {'y + z', 'lower(name)'}).createQuery();

    expect(
      actual,
      equals(
          'CREATE INDEX IF NOT EXISTS `foo` ON `bar` (y + z, lower(name), `id`)'),
    );
  });

  test('equal indices have equal hash codes', () {
    final index = Index('foo', 'bar', false, ['lower(name)'],
        expressions: {'lower(name)'});
    final other = Index('foo', 'bar', false, ['lower(name)'],
        expressions: <String>{'lower(name)'});

    expect(index, equals(other));
    expect(index.hashCode, equals(other.hashCode));
  });
}
