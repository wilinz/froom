# Migrations

Whenever you are doing changes to your entities, you're required to also migrate the old data.

First, update your entity.
Next, Increase the database version.
Define a `Migration` which specifies a `startVersion`, an `endVersion` and a function that executes SQL to migrate the data.
At last, use `addMigrations()` on the obtained database builder to add migrations.
The migrations have to lead from the version of the database to the current one without gaps, e.g. `1 → 2` and `2 → 3`.
Like in Room, of several migrations starting at the same version, the one reaching the highest version is used, e.g. a `1 → 3` migration instead of `1 → 2` and `2 → 3`.
Don't forget to trigger the code generator again, to create the code for handling the new entity.

```dart
// update entity with new 'nickname' field
@Entity(tableName: 'person')
class Person {
  @PrimaryKey(autoGenerate: true)
  final int id;

  @ColumnInfo(name: 'custom_name')
  final String name;

  final String nickname;

  Person(this.id, this.name, this.nickname);
}

// bump up database version
@Database(version: 2)
abstract class AppDatabase extends FroomDatabase {
  PersonDao get personDao;
}

// create migration
final migration1to2 = Migration(1, 2, (database) async {
  await database.execute('ALTER TABLE person ADD COLUMN nickname TEXT');
});

final database = await $FroomAppDatabase
    .databaseBuilder('app_database.db')
    .addMigrations([migration1to2])
    .build();
```

Migrations run with foreign keys disabled, as they can't be disabled within the transaction of the migrations, which e.g. [recreating a table](https://www.sqlite.org/lang_altertable.html#otheralter) requires.
Therefore, foreign key actions like `ON DELETE CASCADE` don't run during migrations, so delete dependent rows explicitly.
After the migrations, Froom checks that they didn't add foreign key violations with `PRAGMA foreign_key_check`, otherwise rolls them back together with the database version and fails opening the database, and enables foreign keys again.
Violations which existed before the migrations are ignored.

## Automatic Migrations

Like Room's `@AutoMigration`, Froom can generate migrations by comparing the schemas of two versions of the database.
When generating the code of a database with automatic migrations or `exportSchema: true`, Froom exports the schema of the current version to `froom_schemas/<path of the library>/<database class>/<version>.json`.
**Commit these files**, as the automatic migrations of later versions are generated from them.
Enable `exportSchema: true` before increasing the version for the first automatic migration, so that the schema of the version to migrate from is exported.
Otherwise, generate the code of the previous version with `exportSchema: true` once, or migrate from it with a manual `Migration`.
The schemas are exported to another directory when configuring it in the `build.yaml` of your project:

```yaml
targets:
  $default:
    builders:
      froom_generator:
        options:
          schema_location: database_schemas
```

After increasing the version, declare an `AutoMigration` from the previous version to the new one.
Its migration is added to the database builder automatically, unless a migration of the same versions is added with `addMigrations()`.

```dart
@Database(
  version: 2,
  entities: [Person, Song],
  autoMigrations: [AutoMigration(from: 1, to: 2)],
)
abstract class AppDatabase extends FroomDatabase {}
```

Froom adds new tables and columns, renames tables, and recreates tables with other changes, e.g. to their columns, primary key, foreign keys or indices, copying their data like [SQLite recommends](https://www.sqlite.org/lang_altertable.html#otheralter).
New `NOT NULL` columns require a default value, see `@ColumnInfo(defaultValue: ...)`.
Views are recreated with their new queries.

Deleted and renamed tables and columns can't be distinguished, so the code generation fails until they are declared on a spec class extending `AutoMigrationSpec`.
Its `onPostMigrate` method runs within the transaction of the migration afterwards, e.g. for migrating data.

```dart
import 'package:froom/sqflite.dart' as sqflite;

@Database(
  version: 3,
  entities: [Person, Artist, Song],
  autoMigrations: [
    AutoMigration(from: 1, to: 2),
    AutoMigration(from: 2, to: 3, spec: AppAutoMigrationSpec),
  ],
)
abstract class AppDatabase extends FroomDatabase {}

@RenameTable(fromTableName: 'Singer', toTableName: 'Artist')
@RenameColumn(tableName: 'Person', fromColumnName: 'name', toColumnName: 'fullName')
@DeleteTable(tableName: 'Album')
@DeleteColumn(tableName: 'Person', columnName: 'nickname')
class AppAutoMigrationSpec extends AutoMigrationSpec {
  @override
  Future<void> onPostMigrate(sqflite.Database database) async {
    // e.g. migrate data
  }
}
```

Specs are created by their unnamed constructor.
To pass dependencies instead, annotate the spec with `@providedAutoMigrationSpec` and add an instance with `addAutoMigrationSpecs()` of the database builder.

## Destructive Migration

When it's fine to lose the data of the database, e.g. for a cache or during development, call `fallbackToDestructiveMigration()` on the database builder.
Like Room, Froom then recreates the database from scratch instead of failing when there is no migration from its version to the current one, or when the database version is higher than the current one (downgrade).
All tables and views get dropped, so all data is lost.
Migrations are still used whenever they cover the version change.

```dart
final database = await $FroomAppDatabase
    .databaseBuilder('app_database.db')
    .addMigrations([migration1to2])
    .addCallback(Callback(
      onDestructiveMigration: (database) {
        // e.g. re-download data
      },
    ))
    .fallbackToDestructiveMigration()
    .build();
```
