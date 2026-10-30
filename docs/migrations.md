# Migrations

Whenever you are doing changes to your entities, you're required to also migrate the old data.

First, update your entity.
Next, Increase the database version.
Define a `Migration` which specifies a `startVersion`, an `endVersion` and a function that executes SQL to migrate the data.
At last, use `addMigrations()` on the obtained database builder to add migrations.
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
