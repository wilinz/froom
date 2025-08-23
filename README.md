# Froom

English | [中文](README_zh.md)

**See the [project's website](https://wilinz.github.io/froom/) for the full documentation.**

Froom is a modern, lightweight SQLite abstraction for Flutter applications, inspired by the [Room persistence library](https://developer.android.com/topic/libraries/architecture/room) and developed as an evolution of the popular [Floor ORM](https://github.com/pinchbv/floor) library. Froom is built on top of **Floor 1.5.0**, which was discontinued and is no longer maintained, while Froom extends its capabilities to meet the needs of modern Flutter applications.

Froom provides automatic mapping between in-memory objects and database rows, while still offering full control of the database through SQL queries. To make the most of Froom's features, having a basic understanding of SQL and SQLite is necessary, but the library's API simplifies the process of interacting with databases.

- null-safe
- typesafe
- reactive
- lightweight
- SQL centric
- no hidden magic
- no hidden costs
- iOS, Android, Linux, macOS, Windows

⚠️ The library is open to contributions!
Refer to [GitHub Discussions](https://github.com/wilinz/froom/discussions) for questions, ideas, and discussions.

## Why Froom?

Froom is built as a **modern** and **feature-rich replacement** for the `floor` library, which itself was inspired by the Room persistence library used in Android development. While Floor served as a lightweight solution for SQLite in Flutter, Froom enhances and extends its capabilities to meet the needs of modern Flutter applications.

Froom is based on **Floor 1.5.0**, as Floor is no longer actively maintained. **Froom** aims to continue where Floor left off by providing better support for modern Flutter versions and adding new features such as automatic migrations, improved error handling, and more complex data type support.

- **Room**: The Android library that inspired Floor and Froom, provides a powerful SQLite abstraction with support for data persistence and querying.
- **Floor**: A Flutter-specific implementation of Room’s ideas, offering a simplified ORM solution for SQLite in Flutter. However, it has been discontinued and is no longer maintained.
- **Froom**: An evolution of Floor, Froom incorporates lessons learned from both Room and Floor, while adding new features such as automatic SQL migration, better error handling, and support for more complex data types.

> **Froom** was designed to provide everything that Floor could not, by addressing its limitations and offering better compatibility with newer versions of Flutter.

## Planned Features

The following features are planned for future releases of **Froom** to enhance its capabilities and address user feedback:

- **Automatic SQL Migration**: Plan to add automatic database migrations to handle schema changes smoothly.
- **Improved Error Handling**: Enhance error reporting and debugging capabilities, ensuring that developers get more actionable insights during development.

> These features are under **active planning** and will be added based on community contributions and ongoing development.


[![pub package](https://img.shields.io/pub/v/froom.svg)](https://pub.dartlang.org/packages/froom)
[![build status](https://github.com/wilinz/froom/workflows/CI/badge.svg)](https://github.com/wilinz/froom/actions)
[![codecov](https://codecov.io/gh/wilinz/froom/branch/develop/graph/badge.svg)](https://codecov.io/gh/wilinz/froom)

## Version Compatibility

Please choose the appropriate version based on your `source_gen` dependency:

| source_gen Version | Froom Version |
|--------------------|---------------|
| 3.x.x and above   | 3.x.x         |
| 2.x.x             | 2.0.4         |

## Migrating from Floor

If you're migrating from Floor to Froom, see our [Migration Guide](https://wilinz.github.io/froom/migration-from-floor) for detailed instructions and an automated migration script.

**⚠️ Important: Always backup your project before migration!**

## Getting Started

### 1. Setup Dependencies

Add the runtime dependency `froom` as well as the generator `froom_generator` to your `pubspec.yaml`.
The third dependency is `build_runner` which has to be included as a dev dependency just like the generator.

- `froom` holds all the code you are going to use in your application.
- `froom_generator` includes the code for generating the database classes.
- `build_runner` enables a concrete way of generating source code files.


```shell
dart pub add froom dev:froom_generator
```
or
```yaml
dependencies:
  flutter:
    sdk: flutter
  froom: ^x.x.x

dev_dependencies:
  froom_generator: ^x.x.x
  build_runner: ^x.x.x
```

### 2. Create an Entity

It will represent a database table as well as the scaffold of your business object.
`@entity` marks the class as a persistent class.
It's required to add a primary key to your table.
You can do so by adding the `@primaryKey` annotation to an `int` property.
There is no restriction on where you put the file containing the entity.

```dart
// entity/person.dart

import 'package:froom/froom.dart';

@entity
class Person {
  @primaryKey
  final int id;

  final String name;

  Person(this.id, this.name);
}
```

### 3. Create a DAO (Data Access Object)

This component is responsible for managing access to the underlying SQLite database.
The abstract class contains the method signatures for querying the database which have to return a `Future` or `Stream`.

- You can define queries by adding the `@Query` annotation to a method.
  The SQL statement has to get added in parenthesis.
  The method must return a `Future` or `Stream` of the `Entity` you're querying for.
- `@insert` marks a method as an insertion method.

```dart
// dao/person_dao.dart

import 'package:froom/froom.dart';

@dao
abstract class PersonDao {
  @Query('SELECT * FROM Person')
  Future<List<Person>> findAllPeople();

  @Query('SELECT name FROM Person')
  Stream<List<String>> findAllPeopleName();

  @Query('SELECT * FROM Person WHERE id = :id')
  Stream<Person?> findPersonById(int id);

  @insert
  Future<void> insertPerson(Person person);
}
```

### 4. Create the Database

It has to be an abstract class which extends `FroomDatabase`.
Furthermore, it's required to add `@Database()` to the signature of the class.
Make sure to add the created entity to the `entities` attribute of the `@Database` annotation.
In order to make the generated code work, it's required to also add the listed imports.

Make sure to add `part 'database.g.dart';` beneath the imports of this file.
It's important to note that 'database' has to get exchanged with the filename of the database definition.
In this case, the file is named `database.dart`.

```dart
// database.dart

// required package imports
import 'dart:async';
import 'package:froom/froom.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'dao/person_dao.dart';
import 'entity/person.dart';

part 'database.g.dart'; // the generated code will be there

@Database(version: 1, entities: [Person])
abstract class AppDatabase extends FroomDatabase {
  PersonDao get personDao;
}
```

### 5. Run the Code Generator

Run the generator with `flutter packages pub run build_runner build`.
To automatically run it, whenever a file changes, use `flutter packages pub run build_runner watch`.

### 6. Use the Generated Code

For obtaining an instance of the database, use the generated `$FroomAppDatabase` class, which allows access to a database builder.
The name is being composed by `$Froom` and the database class name.
The string passed to `databaseBuilder()` will be the database file name.
For initializing the database, call `build()` and make sure to `await` the result.

In order to retrieve the `PersonDao` instance, invoking the `persoDao` getter on the database instance is enough.
Its functions can be used as shown in the following snippet.

```dart
final database = await $FroomAppDatabase.databaseBuilder('app_database.db').build();

final personDao = database.personDao;
final person = Person(1, 'Frank');

await personDao.insertPerson(person);
final result = await personDao.findPersonById(1);
```

For further examples take a look at the [example](https://github.com/wilinz/froom/tree/develop/example) and [test](https://github.com/wilinz/froom/tree/develop/froom/test/integration) directories.

## Naming
The library's name derives from the following.
*Froom* as the *bottom layer* of a [Room](https://developer.android.com/topic/libraries/architecture/room) which points to the analogy of the database layer being the bottom and foundation layer of most applications.
Where *fl* also gives a pointer that the library is used in the Flutter context.

## Bugs, Ideas, and Feedback
For bugs please use [GitHub Issues](https://github.com/wilinz/froom/issues).
For questions, ideas, and discussions use [GitHub Discussions](https://github.com/wilinz/froom/discussions).

## License
    Copyright 2023 The Froom Project Authors
    
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
    http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
