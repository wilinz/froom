import 'package:collection/collection.dart';
import 'package:froom_generator/misc/extension/string_extension.dart';

abstract class Fts {
  String get usingOption;

  String tableCreateOption();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fts &&
          runtimeType == other.runtimeType &&
          usingOption == other.usingOption &&
          tableCreateOption() == other.tableCreateOption();

  @override
  int get hashCode => usingOption.hashCode ^ tableCreateOption().hashCode;

  @override
  String toString() {
    return 'Fts{type: $usingOption, tokenizer: ${tableCreateOption()}}';
  }
}

class Fts3 extends Fts {
  final String tokenizer;
  final List<String> tokenizerArgs;

  Fts3(
    this.tokenizer,
    this.tokenizerArgs,
  );

  @override
  String get usingOption => 'USING fts3';

  @override
  String tableCreateOption() {
    final StringBuffer stringBuffer = StringBuffer();
    stringBuffer.write('tokenize=$tokenizer ');
    if (tokenizerArgs.isNotEmpty) {
      stringBuffer.write(tokenizerArgs.join(' '));
    }

    return stringBuffer.toString();
  }
}

class Fts4 extends Fts {
  final String tokenizer;
  final List<String> tokenizerArgs;

  Fts4(
    this.tokenizer,
    this.tokenizerArgs,
  );

  @override
  String get usingOption => 'USING fts4';

  @override
  String tableCreateOption() {
    final StringBuffer stringBuffer = StringBuffer();
    stringBuffer.write('tokenize=$tokenizer ');
    if (tokenizerArgs.isNotEmpty) {
      stringBuffer.write(tokenizerArgs.join(' '));
    }
    return stringBuffer.toString();
  }
}

class Fts5 extends Fts {
  /// The column name of the row id, which is the primary key of FTS5 entities
  /// and isn't declared as a column of their tables.
  static const rowidColumnName = 'rowid';

  final String tokenizer;
  final List<String> tokenizerArgs;
  final List<int> prefixes;
  final List<String> notIndexed;

  Fts5(
    this.tokenizer,
    this.tokenizerArgs,
    this.prefixes,
    this.notIndexed,
  );

  @override
  String get usingOption => 'USING fts5';

  @override
  String tableCreateOption() {
    // FTS5 options are string literals, the tokenizer arguments separated by
    // spaces and quoted unless they are barewords, e.g. tokenchars '-_'
    String quote(final String argument) =>
        RegExp(r"^(\w+|'([^']|'')*')$").hasMatch(argument)
            ? argument
            : "'${argument.replaceAll("'", "''")}'";
    final tokenize = [tokenizer, ...tokenizerArgs.map(quote)].join(' ');
    return [
      'tokenize = ${tokenize.toSqlLiteral()}',
      if (prefixes.isNotEmpty) 'prefix = ${prefixes.join(' ').toSqlLiteral()}',
    ].join(', ');
  }

  @override
  bool operator ==(Object other) =>
      super == other &&
      other is Fts5 &&
      const ListEquality<String>().equals(notIndexed, other.notIndexed);

  @override
  int get hashCode =>
      super.hashCode ^ const ListEquality<String>().hash(notIndexed);
}
