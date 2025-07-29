import 'dart:async';

import 'package:froom_common/froom_common.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite;

import '../../test_util/database_factory.dart';
import 'mail.dart';
import 'mail_dao.dart';

part 'mail_database.g.dart';

@Database(version: 1, entities: [Mail])
abstract class MailDatabase extends FroomDatabase {
  MailDao get mailDao;
}
