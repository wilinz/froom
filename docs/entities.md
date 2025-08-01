# Entities

An entity is a persistent class.
Froom automatically creates the mappings between the in-memory objects and database table rows.
It's possible to supply custom metadata to Froom by adding optional values to the `Entity` annotation.
It has the additional attribute of `tableName` which opens up the possibility to use a custom name for that specific entity instead of using the class name.
`foreignKeys` allows adding foreign keys to the entity.
More information on how to use these can be found in the [Foreign Keys](#foreign-keys) section.
Indices are supported as well.
They can be used by adding an `Index` to the `indices` value of the entity.
For further information of these, please refer to the [Indices](#indices) section.

`@PrimaryKey` marks property of a class as the primary key column.
This property has to be of type int.
The value can be automatically generated by SQLite when `autoGenerate` is enabled.
For more information about primary keys and especially compound primary keys, refer to the [Primary Keys](#primary-keys) section.

`@ColumnInfo` enables custom mapping of single table columns.
With the annotation it's possible to give columns a custom name.
If you want a table's column to be nullable, mark the entity's field as nullable.
More information can be found in the [Null Safety](null-safety.md) section.

!!! attention
    - Froom automatically uses the **first** constructor defined in the entity class for creating in-memory objects from database rows.
    - There needs to be a constructor.

```dart
@Entity(tableName: 'person')
class Person {
  @PrimaryKey(autoGenerate: true)
  final int id;

  @ColumnInfo(name: 'custom_name')
  final String name;

  Person(this.id, this.name);
}
```

### Supported Types
Froom entities can hold values of the following Dart types which map to their corresponding SQLite types and vice versa.

- `int` - INTEGER
- `double` - REAL
- `String` - TEXT
- `bool` - INTEGER (0 = false, 1 = true)
- `Uint8List` - BLOB
- `enum` - INTEGER (records by the index 0..n)

In case you want to store sophisticated Dart objects that can be represented by one of the above types, take a look at [Type Converters](type-converters.md).

### Primary Keys
Whenever a compound primary key is required (e.g. *n-m* relationships), the syntax for setting the keys differs from the previously mentioned way of setting primary keys.
Instead of annotating a field with `@PrimaryKey`, the `@Entity` annotation's `primaryKey` attribute is used.
It accepts a list of column names that make up the compound primary key.

```dart
@Entity(primaryKeys: ['id', 'name'])
class Person {
  final int id;

  final String name;

  Person(this.id, this.name);
}
```

### Foreign Keys
Add a list of `ForeignKey`s to the `Entity` annotation of the referencing entity.
`childColumns` define the columns of the current entity, whereas `parentColumns` define the columns of the parent entity.
Foreign key actions can get triggered after defining them for the `onUpdate` and `onDelete` properties.

```dart
@Entity(
  tableName: 'dog',
  foreignKeys: [
    ForeignKey(
      childColumns: ['owner_id'],
      parentColumns: ['id'],
      entity: Person,
    )
  ],
)
class Dog {
  @PrimaryKey()
  final int id;

  final String name;

  @ColumnInfo(name: 'owner_id')
  final int ownerId;

  Dog(this.id, this.name, this.ownerId);
}
```

### Indices
Indices help speeding up query, join and grouping operations.
For more information on SQLite indices please refer to the official [documentation](https://sqlite.org/lang_createindex.html).
To create an index with froom, add a list of indices to the `@Entity` annotation.
The example below shows how to create an index on the `custom_name` column of the entity.

The index, moreover, can be named by using its `name` attribute.
To set an index to be unique, use the `unique` attribute.
```dart
@Entity(tableName: 'person', indices: [Index(value: ['custom_name'])])
class Person {
  @primaryKey
  final int id;

  @ColumnInfo(name: 'custom_name')
  final String name;

  Person(this.id, this.name);
}
```

### Ignoring Fields
Getters, setters and all static fields of entities are ignored by default and thus excluded from the library's mapping.
In case further fields should be ignored, the `@ignore` annotation should be used and applied as shown in the following snippet.

```dart
class Person {
  @primaryKey
  final int id;

  final String name;

  @ignore
  String nickname;

  // ignored by default
  String get combinedName => "$name ($nickname)";

  Person(this.id, this.name);
}
```

### Inheritance

Just like Daos, entities (and database views) can inherit from a common base class and use their fields. The entity just has to `extend` the base class.
This construct will be treated as if all the fields in the base class are part of the entity, meaning the database table will
have all columns of the entity and the base class.

The base class does not have to have a separate annotation for the class. Its fields can be annotated just like normal entity columns.
Foreign keys and indices have to be declared in the entity and can't be defined in the base class.

```dart
class BaseObject {
  @PrimaryKey()
  final int id;

  @ColumnInfo(name: 'create_time')
  final String createTime;

  @ColumnInfo(name: 'update_time')
  final String updateTime;

  BaseObject(
    this.id,
    this.updateTime, {
    String createTime,
  }) : this.createTime = createTime ?? DateTime.now().toString();

  @override
  List<Object> get props => [];
}

@Entity(tableName: 'comments')
class Comment extends BaseObject {
  final String author;

  final String content;

  Comment(
    this.author, {
    int id,
    this.content = '', 
    String createTime,
    String updateTime,
  }) : super(id, updateTime, createTime: createTime);
}
```
