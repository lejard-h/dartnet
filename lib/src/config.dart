import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:logging/logging.dart';
import 'package:glob/glob.dart';
import 'logger.dart';


const String dartnetConfigurationFile = "dartnet.yaml";
const String dartnetLogFile = "dartnet.log";
const String dartnetLoggerName = "dartnet";

dynamic _getFromMap(Map map, dynamic key) =>
    map != null ? (map[key] ?? null) : null;

class DartnetConfiguration {
  Logger _log;
  Logger get log => _log;

  RedirectionConfig _redirections;
  HttpsConfig _https;
  SecurityContext _security;

  SecurityContext get security => _security;

  Map _config;

  DartnetConfiguration({String configFileName: dartnetConfigurationFile}) {
    _log = new Logger(dartnetLoggerName);
    initLogger(logLevel, new File(logFile));

    File configFile = new File(configFileName);
    if (configFile.existsSync() != true) {
      throw "No Configuration File found at '$configFileName'";
    }

    _config = loadYaml(configFile.readAsStringSync());

    _redirections = new RedirectionConfig(
        _getFromMap(_config, RedirectionConfig.redirectionsKey));
    _https = new HttpsConfig(_getFromMap(_config, HttpsConfig.httpsKey));

    if (_https.isValid) {
      _security = new SecurityContext()
        ..useCertificateChain(_https.certPath)
        ..usePrivateKey(_https.keyPath,
            password: _https.passwordKey);
    }
  }

  static const String portKey = "port";
  static const String addressKey = "address";
  static const String multithreadKey = "multithread";
  static const String rootDirectoryKey = "root_directory";
  static const String logLevelKey = "log";
  static const String logFileKey = "log_file";
  static const String listDirectoryKey = "list_directory";
  static const String gzipKey = "gzip";

  RedirectionConfig get redirections => _redirections;

  num get port => _getFromMap(_config, portKey) ?? 8080;
  String get address => _getFromMap(_config, addressKey) ?? "0.0.0.0";
  bool get isMultithread => _getFromMap(_config, multithreadKey) ?? false;
  String get rootDirectory => _getFromMap(_config, rootDirectoryKey) ?? "./";
  String get logFile => _getFromMap(_config, logFileKey) ?? dartnetLogFile;
  Level get logLevel =>
      logLevels[_getFromMap(_config, logLevelKey)?.toUpperCase()] ?? Level.INFO;
  bool get listDirectory => _getFromMap(_config, listDirectoryKey) ?? false;
  bool get gzip => _getFromMap(_config, gzipKey) ?? true;

  String _correspondingLogString(Level level) => logLevels.keys
      .firstWhere((String key) => logLevels[key] == level, orElse: () => null);

  Map toMap() => {
        addressKey: address,
        portKey: port,
        multithreadKey: isMultithread,
        rootDirectoryKey: rootDirectory,
        logFileKey: logFile,
        logLevelKey: _correspondingLogString(logLevel),
        listDirectoryKey: listDirectory,
        gzipKey: gzip
      };
}

class RedirectionConfig {
  Map _config;
  PathRedirectionConfig _pathConfig;
  ErrorsRedirectionConfig _errorsConfig;

  static const String redirectionsKey = "redirections";

  RedirectionConfig(this._config) {
    _pathConfig = new PathRedirectionConfig(_getFromMap(_config, PathRedirectionConfig.pathRedirectionsKey));
    _errorsConfig = new ErrorsRedirectionConfig(_getFromMap(_config, ErrorsRedirectionConfig.errorsRedirectionsKey));
  }

  PathRedirectionConfig get path => _pathConfig;
  ErrorsRedirectionConfig get onError => _errorsConfig;
}

class PathRedirectionConfig {
  Map _config;

  static const String pathRedirectionsKey = "path";

  PathRedirectionConfig(Map config) {
    _config = new Map.from(config);
  }

  PathRedirection match(String path) {
    if (_config.containsKey(path)) {
      if (_config[path] is String) {
        var redirect = _config[path];
        while (redirect is String && _config.containsKey(redirect)) {
          redirect = _config[redirect];
        }
        _config[path] = redirect is PathRedirection ? redirect : new PathRedirection(path, Uri.parse(redirect));
      }
      return _config[path];
    }
    Iterable targets = _config.keys;
    for (String target in targets) {
      Glob matcher = new Glob(target);
      if (matcher.allMatches(path).isNotEmpty) {
        var redirect = _config[target];
        _config[path] = redirect is PathRedirection ? redirect : new PathRedirection(path, Uri.parse(redirect));
        return _config[path];
      }
    }
    return null;
  }

  PathRedirection operator[](String path) {
    if (_config.containsKey(path)) {
      if (_config[path] is String) {
        var redirect = _config[path];
        while (redirect is String && _config.containsKey(redirect)) {
          redirect = _config[redirect];
        }
        _config[path] = redirect is PathRedirection ? redirect : new PathRedirection(path, Uri.parse(redirect));
      }
      return _config[path];
    }
    return null;
  }
}

class PathRedirection {
  final String from;
  final Uri to;
  PathRedirection(this.from, this.to);

  bool get isOutside => to.scheme.startsWith("http");
}

class ErrorsRedirectionConfig {
  Map _config;

  static const String errorsRedirectionsKey = "error";

  ErrorsRedirectionConfig(this._config);

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
