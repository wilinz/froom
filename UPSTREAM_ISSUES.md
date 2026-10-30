# Upstream floor issues

Tracks the open issues of the upstream [floor](https://github.com/pinchbv/floor/issues) repository and their status in Froom.
Bugs and small features are verified against Froom and fixed in number order, each with a mirrored Froom issue.

| Status | Count | Meaning |
|---|---|---|
| ✅ Fixed | 21 | Fixed in Froom, see the linked Froom issue |
| ✔️ Already resolved | 15 | Not an issue in Froom (anymore) |
| 🔁 Duplicate | 17 | Duplicate of another upstream issue |
| ⏳ Planned | 13 | Bug or small feature to be fixed |
| 🧩 Large feature | 31 | Large feature, not scheduled yet |
| ➖ Not planned | 35 | Question, support request or not applicable |

| Upstream | Title | Status | Froom | Notes |
|---|---|---|---|---|
| [floor#9](https://github.com/pinchbv/floor/issues/9) | Support embedded objects | 🧩 Large feature |  |  |
| [floor#47](https://github.com/pinchbv/floor/issues/47) | Support relations with @Relation annotation | 🧩 Large feature |  |  |
| [floor#58](https://github.com/pinchbv/floor/issues/58) | Provide more query validation | 🧩 Large feature |  |  |
| [floor#81](https://github.com/pinchbv/floor/issues/81) | Keep current database version when migration fails | ✔️ Already resolved |  | Migrations run in a transaction: version and statements are rolled back on failure (verified) |
| [floor#91](https://github.com/pinchbv/floor/issues/91) | Replace the direct sqflite dependecies with a wrapper around them | 🧩 Large feature |  |  |
| [floor#94](https://github.com/pinchbv/floor/issues/94) | Parse queries into objects | 🧩 Large feature |  |  |
| [floor#97](https://github.com/pinchbv/floor/issues/97) | Support for built_value immutable value types | 🧩 Large feature |  |  |
| [floor#134](https://github.com/pinchbv/floor/issues/134) | Autogenerate query entity by primary key | 🧩 Large feature |  |  |
| [floor#166](https://github.com/pinchbv/floor/issues/166) | Reset database without deleting database file | ✅ Fixed | [#163](https://github.com/wilinz/froom/issues/163) | `clearAllTables()` |
| [floor#175](https://github.com/pinchbv/floor/issues/175) | Positional optional parameters of entities constructor | ✅ Fixed | [#164](https://github.com/wilinz/froom/issues/164) | Positional optional parameters already worked; fields not in the constructor are assigned via setters |
| [floor#205](https://github.com/pinchbv/floor/issues/205) | Add changeListener to queryAdapter event if there are no stream return types in dao | ➖ Not planned |  | `changeListener` is internal; observe changes with stream queries |
| [floor#255](https://github.com/pinchbv/floor/issues/255) | Prepopulated Database | 🧩 Large feature |  |  |
| [floor#256](https://github.com/pinchbv/floor/issues/256) | Support for defaultValue in @ColumnInfo | ✅ Fixed | [#165](https://github.com/wilinz/froom/issues/165) | `@ColumnInfo(defaultValue: ...)` |
| [floor#275](https://github.com/pinchbv/floor/issues/275) | Mapper defaults to the first constructor | ✅ Fixed | [#166](https://github.com/wilinz/froom/issues/166) | Unnamed constructor preferred, named ones called by name |
| [floor#310](https://github.com/pinchbv/floor/issues/310) | Limit DAO inheritance overrides to abstract classes | ✔️ Already resolved |  | Not reproducible: unannotated concrete inherited methods are not overridden |
| [floor#321](https://github.com/pinchbv/floor/issues/321) | Add a query parser | 🧩 Large feature |  |  |
| [floor#340](https://github.com/pinchbv/floor/issues/340) | [feature] Dao independent transactions | 🧩 Large feature |  |  |
| [floor#348](https://github.com/pinchbv/floor/issues/348) | information | 🧩 Large feature |  |  |
| [floor#356](https://github.com/pinchbv/floor/issues/356) | Destructive migration | ✅ Fixed | [#167](https://github.com/wilinz/froom/issues/167) | `fallbackToDestructiveMigration()` |
| [floor#357](https://github.com/pinchbv/floor/issues/357) | Does floor support JSON1 Extensions? | ➖ Not planned |  | Question, support or not applicable |
| [floor#360](https://github.com/pinchbv/floor/issues/360) | handle changeListener inputs in transactions correctly | 🧩 Large feature |  |  |
| [floor#370](https://github.com/pinchbv/floor/issues/370) | Deleting the whole database file | ➖ Not planned |  | Question, support or not applicable |
| [floor#371](https://github.com/pinchbv/floor/issues/371) | Allow named/optional parameters for dao methods | ✅ Fixed | [#168](https://github.com/wilinz/froom/issues/168) | Optional and named DAO method parameters |
| [floor#373](https://github.com/pinchbv/floor/issues/373) | Feature: Update streams even less often | 🧩 Large feature |  |  |
| [floor#374](https://github.com/pinchbv/floor/issues/374) | NoSuchMethodError: The getter 'name' was called on null. Receiver: null Tried calling: name | ✔️ Already resolved |  | Scalar queries work (verified) |
| [floor#383](https://github.com/pinchbv/floor/issues/383) | Emit stream value after calling a method annotated with @Query(...) | ✅ Fixed | [#169](https://github.com/wilinz/froom/issues/169) | `@Query` changes notify streams of other DAOs |
| [floor#386](https://github.com/pinchbv/floor/issues/386) | Add option for renaming table and column names | 🧩 Large feature |  |  |
| [floor#388](https://github.com/pinchbv/floor/issues/388) | Could not use on linux | ✔️ Already resolved |  | Froom selects the FFI factory on desktop |
| [floor#395](https://github.com/pinchbv/floor/issues/395) | Is auto-creation of tables safe? | ➖ Not planned |  | Question, support or not applicable |
| [floor#400](https://github.com/pinchbv/floor/issues/400) | Migrate (update) database view query | ✅ Fixed | [#170](https://github.com/wilinz/froom/issues/170) | Views are recreated after migrations |
| [floor#403](https://github.com/pinchbv/floor/issues/403) | Support list type converters | ✔️ Already resolved |  | List type converters work (verified) |
| [floor#424](https://github.com/pinchbv/floor/issues/424) | Stream methods fails if a DB changed in another Isolate | 🧩 Large feature |  |  |
| [floor#437](https://github.com/pinchbv/floor/issues/437) | Object from table with foreign key is dropped when the original table is updated | ✔️ Already resolved |  | Use `@upsert` instead of `OnConflictStrategy.replace` to keep dependent rows |
| [floor#445](https://github.com/pinchbv/floor/issues/445) | Custom Query string | 🧩 Large feature |  |  |
| [floor#460](https://github.com/pinchbv/floor/issues/460) | findById and constant fields of the table | 🧩 Large feature |  |  |
| [floor#483](https://github.com/pinchbv/floor/issues/483) | Relationship with entities and queries | 🧩 Large feature |  |  |
| [floor#495](https://github.com/pinchbv/floor/issues/495) | Allow Mixins | ✅ Fixed | [#171](https://github.com/wilinz/froom/issues/171) | Mixins allowed on entities and views |
| [floor#497](https://github.com/pinchbv/floor/issues/497) | Support for CREATE INDEX WHERE expr (partial indexes) | ✅ Fixed | [#172](https://github.com/wilinz/froom/issues/172) | `Index.where` for partial indices |
| [floor#507](https://github.com/pinchbv/floor/issues/507) | Query method parameters have to be non-nullable | ✅ Fixed | [#173](https://github.com/wilinz/froom/issues/173) | Nullable query parameters bound as `NULL` |
| [floor#508](https://github.com/pinchbv/floor/issues/508) | Feature: use the same TypeConverter for nullable and not-nullable variant of a type | ✅ Fixed | [#174](https://github.com/wilinz/froom/issues/174) | Converters of non-nullable types convert nullable values |
| [floor#514](https://github.com/pinchbv/floor/issues/514) | Change Query with the name of the return type table | ➖ Not planned |  | Question, support or not applicable |
| [floor#515](https://github.com/pinchbv/floor/issues/515) | Method is generated twice if you override the method in a base class | ✅ Fixed | [#175](https://github.com/wilinz/froom/issues/175) | Overridden DAO methods are generated once |
| [floor#516](https://github.com/pinchbv/floor/issues/516) | [floor_generator]-  Null check operator used on a null value | ➖ Not planned |  | Question, support or not applicable |
| [floor#522](https://github.com/pinchbv/floor/issues/522) | Duplicate fields are added when an entity `implements` a class | ✅ Fixed | [#176](https://github.com/wilinz/froom/issues/176) | Overridden fields are columns once |
| [floor#527](https://github.com/pinchbv/floor/issues/527) | How do I tell floor that the primary key is unset and should be generated? | ✅ Fixed | [#177](https://github.com/wilinz/froom/issues/177) | `0` of non-nullable auto generated keys means unset, like Room |
| [floor#534](https://github.com/pinchbv/floor/issues/534) | Cannot set PRAGMA foreign_keys = OFF on migration | ✅ Fixed | [#178](https://github.com/wilinz/froom/issues/178) | Migrations run with foreign keys disabled, checked afterwards |
| [floor#545](https://github.com/pinchbv/floor/issues/545) | Transfer package to verified publisher | ➖ Not planned |  | Question, support or not applicable |
| [floor#558](https://github.com/pinchbv/floor/issues/558) | [Floor 1.1.0] Impossible to generate database dart file since latest update | ➖ Not planned |  | Question, support or not applicable |
| [floor#566](https://github.com/pinchbv/floor/issues/566) | Since there is no fallback to destructive migration can we atleast create tables via the annotated entities? | 🔁 Duplicate | [#167](https://github.com/wilinz/froom/issues/167) | Same as floor#356 |
| [floor#567](https://github.com/pinchbv/floor/issues/567) | Inject of one DAO to other DAO | 🧩 Large feature |  |  |
| [floor#568](https://github.com/pinchbv/floor/issues/568) | Support for private fields with getters | 🧩 Large feature |  |  |
| [floor#570](https://github.com/pinchbv/floor/issues/570) | Integrate "In Memory Database" | ➖ Not planned |  | Question, support or not applicable |
| [floor#571](https://github.com/pinchbv/floor/issues/571) | Autoincrement primary key example is wrong | ✅ Fixed | [#177](https://github.com/wilinz/froom/issues/177) | The example is valid now, as `0` means unset; the docs explain both ways |
| [floor#576](https://github.com/pinchbv/floor/issues/576) | Return null on  scalar queries such as "Select count(*) from ..." | ✔️ Already resolved |  | Scalar queries return values (verified) |
| [floor#582](https://github.com/pinchbv/floor/issues/582) | Can I ask for “ATTACH DATABASE” support？ | ➖ Not planned |  | Question, support or not applicable |
| [floor#584](https://github.com/pinchbv/floor/issues/584) | How to fetch data from a databse placed in the assets? | 🧩 Large feature |  |  |
| [floor#588](https://github.com/pinchbv/floor/issues/588) | GENERATED CODE _$AppDatabaseBuilder support database path | ✅ Fixed | [#179](https://github.com/wilinz/froom/issues/179) | Absolute paths are supported and documented |
| [floor#590](https://github.com/pinchbv/floor/issues/590) | Nullable image list insert bug | ✔️ Already resolved |  | Converters of `List<Uint8List>?` work (verified) |
| [floor#593](https://github.com/pinchbv/floor/issues/593) | XDG path for Linux database | ➖ Not planned |  | Changing the default path would move existing databases; pass an absolute path instead (floor#588) |
| [floor#595](https://github.com/pinchbv/floor/issues/595) | Left join doesn't return List<Object> instead returns null | ➖ Not planned |  | Question, support or not applicable |
| [floor#596](https://github.com/pinchbv/floor/issues/596) | when app use the floor version of 1.1.0 it flash back and report errors FMDatabase executeUpdate:error:withArgumentsInArray:orDictionary:orVAList | ➖ Not planned |  | Question, support or not applicable |
| [floor#597](https://github.com/pinchbv/floor/issues/597) | Can you add sqflite_sqlcipher support? | 🧩 Large feature |  |  |
| [floor#603](https://github.com/pinchbv/floor/issues/603) | Change listener not notified about custom DELETE statement | 🔁 Duplicate | [#169](https://github.com/wilinz/froom/issues/169) | Same as floor#383 |
| [floor#604](https://github.com/pinchbv/floor/issues/604) | auto migration db | 🧩 Large feature |  |  |
| [floor#605](https://github.com/pinchbv/floor/issues/605) | Can the "TypeConverter" support data of type "Future<T>"? | 🧩 Large feature |  |  |
| [floor#611](https://github.com/pinchbv/floor/issues/611) | Add Column with a default value not working or not possible? | 🔁 Duplicate | [#165](https://github.com/wilinz/froom/issues/165) | Same as floor#256 |
| [floor#614](https://github.com/pinchbv/floor/issues/614) | Is there a way to fallbackToDestructiveMigration? | 🔁 Duplicate | [#167](https://github.com/wilinz/froom/issues/167) | Same as floor#356 |
| [floor#617](https://github.com/pinchbv/floor/issues/617) | Current validation of list sql parameter blocks valid syntax `(name, id) > (:keySet)`, where :keySet is a list | ✅ Fixed | [#180](https://github.com/wilinz/froom/issues/180) | List parameters can be row values `(:list)` |
| [floor#618](https://github.com/pinchbv/floor/issues/618) | query parameter usage | ➖ Not planned |  | Question, support or not applicable |
| [floor#643](https://github.com/pinchbv/floor/issues/643) | integer type ID can be negative? | ➖ Not planned |  | Question, support or not applicable |
| [floor#644](https://github.com/pinchbv/floor/issues/644) | Generated code mishandles named constructors | 🔁 Duplicate | [#166](https://github.com/wilinz/froom/issues/166) | Same as floor#275 |
| [floor#645](https://github.com/pinchbv/floor/issues/645) | Example code in the README needs to import also entity into dao | ✅ Fixed | [#181](https://github.com/wilinz/froom/issues/181) | The DAO example imports the entity |
| [floor#648](https://github.com/pinchbv/floor/issues/648) | SqfliteDatabaseException (DatabaseException(no such table: featurings (code 1 SQLITE_ERROR): , while compiling: select * from featurings) sql 'select * from featurings' args []) | ➖ Not planned |  | Question, support or not applicable |
| [floor#670](https://github.com/pinchbv/floor/issues/670) | enforce TypeConverter implementation test rather than inheritence in floor generator | ✅ Fixed | [#182](https://github.com/wilinz/froom/issues/182) | Converters may implement `TypeConverter` or extend it indirectly |
| [floor#729](https://github.com/pinchbv/floor/issues/729) | Upsert | ✔️ Already resolved | [#2](https://github.com/wilinz/froom/issues/2) | `@upsert` like Room |
| [floor#738](https://github.com/pinchbv/floor/issues/738) | Floor Batches | 🧩 Large feature |  |  |
| [floor#741](https://github.com/pinchbv/floor/issues/741) | Join query | ➖ Not planned |  | Question, support or not applicable |
| [floor#742](https://github.com/pinchbv/floor/issues/742) | Invalid use of a private type | ✔️ Already resolved |  | Generated code suppresses lints (`type=lint`) |
| [floor#744](https://github.com/pinchbv/floor/issues/744) | Make the method return a Future of a nullable type | ⏳ Planned |  | Nullable single return error message |
| [floor#745](https://github.com/pinchbv/floor/issues/745) | Unhandled Exception: DatabaseException(error database_closed) | ⏳ Planned |  | Streams re-query a closed database |
| [floor#746](https://github.com/pinchbv/floor/issues/746) | There's a lot of duplicate code | ➖ Not planned |  | Internal refactoring, partially done while fixing other issues |
| [floor#747](https://github.com/pinchbv/floor/issues/747) | Query with IF | ➖ Not planned |  | Question, support or not applicable |
| [floor#748](https://github.com/pinchbv/floor/issues/748) | Generating duplicated definitions with @transaction | ⏳ Planned |  | `@insert` with `@transaction` generated twice (verified) |
| [floor#758](https://github.com/pinchbv/floor/issues/758) | Unique | ➖ Not planned |  | Question, support or not applicable |
| [floor#763](https://github.com/pinchbv/floor/issues/763) | In the example, a task is created with status: null instead of open | ⏳ Planned |  | Example creates tasks with status `null` |
| [floor#766](https://github.com/pinchbv/floor/issues/766) | Support TypeConversions from Entities | 🧩 Large feature |  |  |
| [floor#768](https://github.com/pinchbv/floor/issues/768) | database can not encryption | 🧩 Large feature |  |  |
| [floor#770](https://github.com/pinchbv/floor/issues/770) | Cannot use a variable for table name | ➖ Not planned |  | Question, support or not applicable |
| [floor#775](https://github.com/pinchbv/floor/issues/775) | Creating new tables within an existing DB | ⏳ Planned |  | `CREATE INDEX IF NOT EXISTS` |
| [floor#778](https://github.com/pinchbv/floor/issues/778) | Issue when try to get insert primary key as String | ➖ Not planned |  | Question, support or not applicable |
| [floor#783](https://github.com/pinchbv/floor/issues/783) | Error in code generation with @transaction method with return of nullable variable | ⏳ Planned |  | `@transaction` with nullable return type (verified) |
| [floor#785](https://github.com/pinchbv/floor/issues/785) | DatabaseView from Entities | ➖ Not planned |  | Question, support or not applicable |
| [floor#786](https://github.com/pinchbv/floor/issues/786) | Access database in isolates | ➖ Not planned |  | Question, support or not applicable |
| [floor#787](https://github.com/pinchbv/floor/issues/787) | can not generate code without @ignore metadata | 🧩 Large feature |  |  |
| [floor#788](https://github.com/pinchbv/floor/issues/788) | #775 still an issue | 🔁 Duplicate |  | Same as floor#775 |
| [floor#789](https://github.com/pinchbv/floor/issues/789) | No warning when one of multiple primary keys is missing | ⏳ Planned |  | No error for misspelled `primaryKeys` (verified) |
| [floor#792](https://github.com/pinchbv/floor/issues/792) | Improve FTS documentation and add some examples | ⏳ Planned |  | Docs: FTS |
| [floor#798](https://github.com/pinchbv/floor/issues/798) | Dumplicate field name when entity implement form abstract class | 🔁 Duplicate | [#176](https://github.com/wilinz/froom/issues/176) | Same as floor#522 |
| [floor#799](https://github.com/pinchbv/floor/issues/799) | duplicate field name when entity implement form abstract class | 🔁 Duplicate | [#176](https://github.com/wilinz/froom/issues/176) | Same as floor#522 |
| [floor#802](https://github.com/pinchbv/floor/issues/802) | trying to get a SUM of a field with floor. | ⏳ Planned |  | Casting `int` values to `double` fails (verified) |
| [floor#803](https://github.com/pinchbv/floor/issues/803) | Custom Database File Path | 🔁 Duplicate | [#179](https://github.com/wilinz/froom/issues/179) | Same as floor#588 |
| [floor#804](https://github.com/pinchbv/floor/issues/804) | sqlite wal | ➖ Not planned |  | Question, support or not applicable |
| [floor#805](https://github.com/pinchbv/floor/issues/805) | How to update a List of an object as field of entity into table in Floor | ➖ Not planned |  | Question, support or not applicable |
| [floor#810](https://github.com/pinchbv/floor/issues/810) | Are there any plans to adapt HarmonyOS | ➖ Not planned |  | Question, support or not applicable |
| [floor#814](https://github.com/pinchbv/floor/issues/814) | #802 still an issue. any help? | 🔁 Duplicate |  | Same as floor#802 |
| [floor#816](https://github.com/pinchbv/floor/issues/816) | Casting to double might not work; | 🔁 Duplicate |  | Same as floor#802 |
| [floor#820](https://github.com/pinchbv/floor/issues/820) | Invalid query (failing to parse) does not throw an error | ⏳ Planned |  | Invalid query not reported by the generator (verified) |
| [floor#823](https://github.com/pinchbv/floor/issues/823) | onCreate callback is not being called, "tbl not found" exception | ➖ Not planned |  | Question, support or not applicable |
| [floor#828](https://github.com/pinchbv/floor/issues/828) | type missmatch int <-> double | 🔁 Duplicate |  | Same as floor#802 |
| [floor#833](https://github.com/pinchbv/floor/issues/833) | No stream updates with quoted table name | ⏳ Planned |  | No stream updates with double quoted table names (verified) |
| [floor#834](https://github.com/pinchbv/floor/issues/834) | Feature Request: Add clearAllTables Function | 🔁 Duplicate | [#163](https://github.com/wilinz/froom/issues/163) | Same as floor#166, also resets `sqlite_sequence` |
| [floor#835](https://github.com/pinchbv/floor/issues/835) | Feature request: Indexes on Expressions | ⏳ Planned |  | Indices on expressions |
| [floor#837](https://github.com/pinchbv/floor/issues/837) | [ERROR] Queries returning single elements might return null. | 🔁 Duplicate |  | Same as floor#744 |
| [floor#838](https://github.com/pinchbv/floor/issues/838) | Need to set null for sqflite database instance when close database. Otherwise it will always return the old instance. | ➖ Not planned |  | Question, support or not applicable |
| [floor#839](https://github.com/pinchbv/floor/issues/839) | when the Constructor has no params , dart run build_runner build cannot build the correct query result | 🔁 Duplicate | [#164](https://github.com/wilinz/froom/issues/164) | Same as floor#175 |
| [floor#840](https://github.com/pinchbv/floor/issues/840) | [Bug]  Test directory referenced by the `Testing` documentation not found | ⏳ Planned |  | Docs: broken link to the tests |
| [floor#842](https://github.com/pinchbv/floor/issues/842) | Can I customize the parameter queryableName in the method queryListStream? | 🧩 Large feature |  |  |
| [floor#843](https://github.com/pinchbv/floor/issues/843) | How can i do encryption for Secure DB? | 🧩 Large feature |  |  |
| [floor#844](https://github.com/pinchbv/floor/issues/844) | Testing in package | ➖ Not planned |  | Question, support or not applicable |
| [floor#845](https://github.com/pinchbv/floor/issues/845) | Search query problem with russian symbols | ➖ Not planned |  | Question, support or not applicable |
| [floor#847](https://github.com/pinchbv/floor/issues/847) | Not able to add nested list of object | ➖ Not planned |  | Question, support or not applicable |
| [floor#849](https://github.com/pinchbv/floor/issues/849) | [Request] To add Annotation for default value | 🔁 Duplicate | [#165](https://github.com/wilinz/froom/issues/165) | Same as floor#256 |
| [floor#850](https://github.com/pinchbv/floor/issues/850) | Is the project dead? | ➖ Not planned |  | Question, support or not applicable |
| [floor#851](https://github.com/pinchbv/floor/issues/851) | Generic type is not support in entity? | 🧩 Large feature |  |  |
| [floor#852](https://github.com/pinchbv/floor/issues/852) | New version of source_gen | ✔️ Already resolved |  | Froom supports current analyzer, source_gen and build versions |
| [floor#853](https://github.com/pinchbv/floor/issues/853) | I need need to clear all my data on the version increase instead of writing migrations. | 🔁 Duplicate | [#167](https://github.com/wilinz/froom/issues/167) | Same as floor#356 |
| [floor#856](https://github.com/pinchbv/floor/issues/856) | floor 1.5.0 is not compatible with flutter 3.29.3. | ✔️ Already resolved |  | Froom supports current analyzer, source_gen and build versions |
| [floor#859](https://github.com/pinchbv/floor/issues/859) | Forked version Froom for continued maintenance and updates | ➖ Not planned |  | Question, support or not applicable |
| [floor#861](https://github.com/pinchbv/floor/issues/861) | Floor is not compatible with Flutter 3.35 | ✔️ Already resolved |  | Froom supports current analyzer, source_gen and build versions |
| [floor#864](https://github.com/pinchbv/floor/issues/864) | Migrating from Floor to Drift ORM with floor2drift | ➖ Not planned |  | Question, support or not applicable |
| [floor#865](https://github.com/pinchbv/floor/issues/865) | Incompatibility with source_gen 4.x (Generator ecosystem upgrade) | ✔️ Already resolved |  | Froom supports current analyzer, source_gen and build versions |
| [floor#866](https://github.com/pinchbv/floor/issues/866) | Issue: Dependency Conflict between source_gen and floor_generator | ✔️ Already resolved |  | Froom supports current analyzer, source_gen and build versions |
