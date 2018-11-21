import 'dart:io';
import 'package:logging/logging.dart';
import 'package:ansicolor/ansicolor.dart';

void initLogger(Level logLevel, File logFile) {
  if (logFile?.existsSync() == false) {
    logFile.createSync(recursive: true);
  }
  Logger.root.onRecord.listen((LogRecord record) {
    if (record.loggerName != "J") {
      String log =
          "${record.time} (${record.level.toString()}) ${record.loggerName} -";
      log +=
          " ${record.error ?? ""}${record.message ?? ""}${record.stackTrace ?? ""}";
      if (record.level >= logLevel) {
        print(log);
      }
      logFile?.writeAsString("$log\n", mode: FileMode.APPEND);
    }
  });
}

const Map<String, Level> logLevels = const {
  'ALL': Level.ALL,
  'OFF': Level.OFF,
  'FINEST': Level.FINEST,
  'FINER': Level.FINER,
  'FINE': Level.FINE,
  'CONFIG': Level.CONFIG,
  'INFO': Level.INFO,
  'WARNING': Level.WARNING,
  'SEVERE': Level.SEVERE,
  'SHOUT': Level.SHOUT
};

final AnsiPen red = new AnsiPen()..red(bold: true);
final AnsiPen green = new AnsiPen()..green(bold: true);
final AnsiPen yellow = new AnsiPen()..yellow(bold: true);
final AnsiPen blue = new AnsiPen()..blue(bold: true);
