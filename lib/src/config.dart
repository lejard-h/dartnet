import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:mustache/mustache.dart';
import 'package:logging/logging.dart';
import 'package:resource/resource.dart';
import 'logger.dart';

const String dartnetConfigurationFile = "dartnet.yaml";
const String dartnetLogFile = "dartnet.log";
const String dartnetLoggerName = "dartnet";

dynamic _getFromMap(Map map, dynamic key) =>
    map != null ? (map[key] ?? null) : null;

class DartnetConfiguration {
  Logger _log;
  Logger get log => _log;

  Map _config;
  RedirectionConfig _redirections;
  HttpsConfig _https;

  Template _listTmpl;
  Template _errorTmpl;

  Template get listTmpl => _listTmpl;
  Template get errorTmpl => _errorTmpl;

  SecurityContext _security;
  SecurityContext get security => _security;

  Directory _rootDirectory;
  Directory get rootDirectory => _rootDirectory;

  final Map<String, dynamic> cache = {};

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
        ..usePrivateKey(_https.keyPath, password: _https.passwordKey);
    }

    _rootDirectory = new Directory(rootDirectoryPath);

    Resource resourceList =
        new Resource("package:dartnet/src/template/list.html");
    resourceList.readAsString().then((template) {
      _listTmpl = new Template(template);
    });
    Resource resource404 =
        new Resource("package:dartnet/src/template/error.html");
    resource404.readAsString().then((template) {
      _errorTmpl = new Template(template);
    });
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
  String get rootDirectoryPath =>
      _getFromMap(_config, rootDirectoryKey) ?? "./";
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
        rootDirectoryKey: rootDirectoryPath,
        logFileKey: logFile,
        logLevelKey: _correspondingLogString(logLevel),
        listDirectoryKey: listDirectory,
        gzipKey: gzip
      };
}

class RedirectionConfig {
  Map _config;
  Map<String, dynamic> _pathConfig;

  static const redirectionsKey = "redirections";
  static const notFoundCodeKey = 404;
  static const pathRedirectionsKey = "path";

  RedirectionConfig(this._config) {
    if (_config != null) {
      _pathConfig = new Map.from(
          _getFromMap(_config, RedirectionConfig.pathRedirectionsKey) ?? {});
    }
  }

  Iterable<String> get paths => _pathConfig.keys;
  String get onNotFound => _getFromMap(_config, notFoundCodeKey);

  Uri operator [](String path) {
    if (_pathConfig.containsKey(path)) {
      if (_pathConfig[path] is String) {
        var redirect = _pathConfig[path];
        while (redirect is String && _pathConfig.containsKey(redirect)) {
          redirect = _pathConfig[redirect];
        }
        _pathConfig[path] = redirect is Uri ? redirect : Uri.parse(redirect);
      }
      return _pathConfig[path];
    }
    return null;
  }
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
