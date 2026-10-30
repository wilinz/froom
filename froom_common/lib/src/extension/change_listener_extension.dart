import 'dart:async';

extension ChangeListenerExtension on StreamController<String> {
  /// Notifies the streams of the [tableName] about changes, unless the
  /// database has been closed meanwhile.
  void notifyChange(final String tableName) {
    if (!isClosed) add(tableName);
  }
}
