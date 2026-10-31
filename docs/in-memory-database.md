# In Memory Database

To instantiate an in-memory database, use the static `inMemoryDatabaseBuilder()` method of the generated `$FroomAppDatabase` class instead of `databaseBuilder()`.

```dart
final database = await $FroomAppDatabase.inMemoryDatabaseBuilder().build();
```

In-memory databases are not stored, so they aren't encrypted with a [password](platform-support.md#encryption) of their builder.
