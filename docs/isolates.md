# Isolates

Froom accesses SQLite through a sqflite `DatabaseFactory`, which determines where the queries run:

- The sqflite plugin, the default on Android and iOS for apps depending on `sqflite`, runs them on a native background thread.
- The FFI factory `databaseFactoryFfi`, the default on the other native platforms, runs them on a background isolate.
  Pass `databaseFactoryFfiNoIsolate` to `databaseFactory()` of the database builder to run them on the current isolate instead.
- On the web, they run in a shared worker.

Changes are only reported to the streams of the database instance that made them.
Writes of other isolates, processes or browser tabs to the same database don't update the streams.

You can do some further reading on sqflite's background work mechanisms [here](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/usage_recommendations.md).
