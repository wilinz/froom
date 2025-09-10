# Froom

[English](README.md) | 中文

**请查看[项目网站](https://wilinz.github.io/froom/) 获取完整文档。**

Froom 是一个现代、轻量级的 Flutter 应用 SQLite 抽象库，灵感来源于 [Room 持久化库](https://developer.android.com/topic/libraries/architecture/room)，是流行的 [Floor ORM](https://github.com/pinchbv/floor) 库的演进版本。Froom 基于 **Floor 1.5.0** 构建，Floor 已停止开发且不再维护，而 Froom 扩展了其功能以满足现代 Flutter 应用的需求。

Froom 提供内存对象与数据库行之间的自动映射，同时仍然通过 SQL 查询提供对数据库的完全控制。要充分利用 Froom 的功能，需要对 SQL 和 SQLite 有基本了解，但该库的 API 简化了与数据库交互的过程。

- 空安全
- 类型安全
- 响应式
- 轻量级
- 以 SQL 为中心
- 无隐藏逻辑
- 无隐藏成本
- 支持 iOS、Android、Linux、macOS、Windows

⚠️ 该库欢迎贡献！
如有问题、想法和讨论，请参阅 [GitHub Discussions](https://github.com/wilinz/froom/discussions)。

## 为什么选择 Froom？

Froom 是作为 `floor` 库的**现代化**和**功能丰富的替代品**而构建的，floor 本身也是受到 Android 开发中使用的 Room 持久化库的启发。虽然 Floor 在 Flutter 中作为 SQLite 的轻量级解决方案发挥了作用，但不再维护，Froom 增强并扩展了其功能，以满足现代 Flutter 应用的需求。

Froom 基于 **Floor 1.5.0**，因为 Floor 不再积极维护。**Froom** 旨在从 Floor 停止的地方继续，通过为现代 Flutter 版本提供更好的支持，并添加诸如自动迁移、改进的错误处理和更复杂数据类型支持等新功能。

- **Room**：启发 Floor 和 Froom 的 Android 库，提供强大的 SQLite 抽象，支持数据持久化和查询。
- **Floor**：Room 思想在 Flutter 中的特定实现，为 Flutter 中的 SQLite 提供简化的 ORM 解决方案。但是，它已被停止开发且不再维护。
- **Froom**：Floor 的演进版，Froom 汲取了 Room 和 Floor 的经验教训，同时添加了诸如自动 SQL 迁移、更好的错误处理和对更复杂数据类型的支持等新功能。

> **Froom** 旨在提供 Floor 无法提供的一切，通过解决其局限性并提供与新版本 Flutter 更好的兼容性。

## 计划功能

以下功能计划在 **Froom** 的未来版本中推出，以增强其功能并回应用户反馈：

- **自动 SQL 迁移**：计划添加自动数据库迁移以平滑处理模式更改。
- **改进的错误处理**：增强错误报告和调试功能，确保开发者在开发过程中获得更多可操作的洞察。

> 这些功能正在**积极规划**中，将根据社区贡献和持续开发而添加。

[![pub package](https://img.shields.io/pub/v/froom.svg)](https://pub.dartlang.org/packages/froom)
[![build status](https://github.com/wilinz/froom/workflows/CI/badge.svg)](https://github.com/wilinz/froom/actions)
[![codecov](https://codecov.io/gh/wilinz/froom/branch/develop/graph/badge.svg)](https://codecov.io/gh/wilinz/froom)

## 版本兼容性

请根据您的 `source_gen` 依赖选择合适的版本：

| source_gen Version | Froom Version |
|--------------------|---------------|
| 4.x.x             | 4.x.x         |
| 3.x.x             | 3.x.x         |
| 2.x.x             | 2.0.4         |

## 从 Floor 迁移

如果您正在从 Floor 迁移到 Froom，请查看我们的[迁移指南](https://wilinz.github.io/froom/migration-from-floor)以获取详细说明和自动迁移脚本。

**⚠️ 重要提示：迁移前请务必备份您的项目！**

## 快速开始

### 1. 设置依赖

将运行时依赖 `froom` 以及生成器 `froom_generator` 添加到您的 `pubspec.yaml` 中。
第三个依赖是 `build_runner`，它必须作为开发依赖包含在内，就像生成器一样。

- `froom` 包含您将在应用程序中使用的所有代码。
- `froom_generator` 包含生成数据库类的代码。
- `build_runner` 提供生成源代码文件的具体方式。


```shell
dart pub add froom dev:froom_generator 
```
或者
```yaml
dependencies:
  flutter:
    sdk: flutter
  froom: ^x.x.x

dev_dependencies:
  froom_generator: ^x.x.x
  build_runner: ^x.x.x
```

### 2. 创建实体

它将表示数据库表以及业务对象的脚手架。
`@entity` 将类标记为持久化类。
需要为您的表添加主键。
您可以通过向 `int` 属性添加 `@primaryKey` 注解来实现。
对于包含实体的文件放置位置没有限制。

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

### 3. 创建 DAO（数据访问对象）

该组件负责管理对底层 SQLite 数据库的访问。
抽象类包含查询数据库的方法签名，这些方法必须返回 `Future` 或 `Stream`。

- 您可以通过向方法添加 `@Query` 注解来定义查询。
  SQL 语句必须添加在括号中。
  该方法必须返回您要查询的 `Entity` 的 `Future` 或 `Stream`。
- `@insert` 将方法标记为插入方法。

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

### 4. 创建数据库

它必须是一个扩展 `FroomDatabase` 的抽象类。
此外，需要在类的签名中添加 `@Database()`。
确保将创建的实体添加到 `@Database` 注解的 `entities` 属性中。
为了使生成的代码工作，还需要添加列出的导入。

确保在此文件的导入下方添加 `part 'database.g.dart';`。
重要的是要注意 'database' 必须与数据库定义的文件名交换。
在这种情况下，文件名为 `database.dart`。

```dart
// database.dart

// 必需的包导入
import 'dart:async';
import 'package:froom/froom.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'dao/person_dao.dart';
import 'entity/person.dart';

part 'database.g.dart'; // 生成的代码将在这里

@Database(version: 1, entities: [Person])
abstract class AppDatabase extends FroomDatabase {
  PersonDao get personDao;
}
```

### 5. 运行代码生成器

使用 `flutter packages pub run build_runner build` 运行生成器。
要在文件更改时自动运行它，请使用 `flutter packages pub run build_runner watch`。

### 6. 使用生成的代码

要获取数据库的实例，请使用生成的 `$FroomAppDatabase` 类，它允许访问数据库构建器。
名称由 `$Froom` 和数据库类名组成。
传递给 `databaseBuilder()` 的字符串将是数据库文件名。
要初始化数据库，请调用 `build()` 并确保 `await` 结果。

要检索 `PersonDao` 实例，在数据库实例上调用 `persoDao` getter 就足够了。
其功能可以如下面的代码片段所示使用。

```dart
final database = await $FroomAppDatabase.databaseBuilder('app_database.db').build();

final personDao = database.personDao;
final person = Person(1, 'Frank');

await personDao.insertPerson(person);
final result = await personDao.findPersonById(1);
```

更多示例请查看 [example](https://github.com/wilinz/froom/tree/develop/example) 和 [test](https://github.com/wilinz/froom/tree/develop/froom/test/integration) 目录。

## 命名

该库的名称来源如下。
*Froom* 作为 [Room](https://developer.android.com/topic/libraries/architecture/room) 的*底层*，这指向了数据库层是大多数应用程序的底部和基础层的类比。
其中 *fl* 也给出了该库在 Flutter 上下文中使用的指示。

## Bug、想法和反馈
如有 bug 请使用 [GitHub Issues](https://github.com/wilinz/froom/issues)。
如有问题、想法和讨论请使用 [GitHub Discussions](https://github.com/wilinz/froom/discussions)。

## 许可证
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