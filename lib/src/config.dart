import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:logging/logging.dart';
import 'logger.dart';
import 'compression.dart';

const String dartnetConfigurationFile = "dartnet.yaml";
const String dartnetLogFile = "dartnet.log";

dynamic _getFromMap(Map map, dynamic key) =>
    map != null ? (map[key] ?? null) : null;

class DartnetConfiguration {
  Logger _log;
  Logger get log => _log;

  RedirectionConfig _redirections;
  HttpsConfig _https;

  Map _config;

  DartnetConfiguration({String configFileName: dartnetConfigurationFile}) {
    _log = new Logger("dartnet");
    initLogger(logLevel, new File(logFile));

    File configFile = new File(configFileName);
    if (configFile?.existsSync() != true) {
      throw "No Configuration File found at '$configFileName'";
    }

    _config = loadYaml(configFile.readAsStringSync());

    _redirections = new RedirectionConfig(
        _getFromMap(_config, RedirectionConfig.redirectionsKey));
    _https = new HttpsConfig(_getFromMap(_config, HttpsConfig.httpsKey));
  }

  static const String portKey = "port";
  static const String addressKey = "address";
  static const String multithreadKey = "multithread";
  static const String rootDirectoryKey = "root_directory";
  static const String logKey = "log";
  static const String logFileKey = "log_file";
  static const String listDirectoryKey = "list_directory";
  static const String compressionKey = "compression";

  RedirectionConfig get redirections => _redirections;
  HttpsConfig get https => _https;

  num get port => _getFromMap(_config, portKey) ?? 8080;
  String get address => _getFromMap(_config, addressKey) ?? "0.0.0.0";
  bool get isMultithread => _getFromMap(_config, multithreadKey) ?? false;
  String get rootDirectory => _getFromMap(_config, rootDirectoryKey) ?? "./";
  String get logFile => _getFromMap(_config, logFileKey) ?? dartnetLogFile;
  Level get logLevel =>
      logLevels[_getFromMap(_config, logKey)?.toUpperCase()] ?? Level.INFO;
  bool get listDirectory => _getFromMap(_config, listDirectoryKey) ?? false;
  Compression get compression =>
      compressionMapper[_getFromMap(_config, compressionKey)?.toUpperCase()] ??
      Compression.Gzip;
}

class RedirectionConfig {
  Map _config;

  static const String redirectionsKey = "redirections";
  static const String defaultKey = "default";

  RedirectionConfig(this._config);

  String get redirectionDefault => redirectionFor(defaultKey);
  String redirectionFor(dynamic key) => _getFromMap(_config, key);
}

class HttpsConfig {
  Map _config;

  static const String httpsKey = "https";
  static const String certKey = "cert";
  static const String keyKey = "key";
  static const String keyPasswordKey = "password_key";

  HttpsConfig(this._config);

  String get certPath => _getFromMap(_config, certKey);
  String get keyPath => _getFromMap(_config, keyKey);
  String get passwordKey => _getFromMap(_config, keyPasswordKey);

  bool get isValid => certPath != null && certKey != null;
}
