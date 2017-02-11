import 'dart:io';
import 'package:jaguar_generator_config/jaguar_generator_config.dart';
import 'package:logging/logging.dart';
import 'logger.dart';

const String jaguarServerConfigurationFile = "dartnet.yaml";

class JaguarServerConfiguration extends GeneratorConfig {
  Logger _log;
  Logger get log => _log;

  JaguarServerConfiguration({String configFileName: jaguarServerConfigurationFile})
      : super(configFileName: configFileName) {
    _log = new Logger(pubspec.projectName);
    initLogger(logLevel, new File(logFile));
  }

  static const String serverKey = "server";
  static const String portKey = "port";
  static const String addressKey = "address";
  static const String multithreadKey = "multithread";
  static const String rootDirectoryKey = "root_directory";
  static const String redirectionsKey = "redirections";
  static const String logKey = "log";
  static const String logFileKey = "log_file";
  static const String listDirectoryKey = "list_directory";

  Map get server => config[serverKey];
  Map get redirections => getFromMap(server, redirectionsKey);

  num get port => getFromMap(server, portKey) ?? 8080;
  String get address => getFromMap(server, addressKey) ?? "0.0.0.0";
  bool get isMultithread => getFromMap(server, multithreadKey) ?? false;
  String get rootDirectory => getFromMap(server, rootDirectoryKey) ?? "./";
  String get logFile => getFromMap(server, logFileKey) ?? "dartnet.log";
  Level get logLevel => _logLevels[getFromMap(server, logKey)?.toUpperCase()] ?? Level.INFO;
  String get redirectionDefault => getFromMap(redirections, "default");
  bool get listDirectory => getFromMap(server, listDirectoryKey) ?? false;
 }

dynamic getFromMap(Map map, String key) => map != null ? (map[key] ?? null) : null;

const Map<String, Level> _logLevels = const {
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
