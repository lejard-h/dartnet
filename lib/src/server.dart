library dartnet;

import 'dart:io';
import 'package:jaguar/jaguar.dart';
import 'package:yamlicious/yamlicious.dart' as yamlicious;

import 'config.dart';
import 'handler.dart';

start({String configPath: dartnetConfigurationFile}) async {
  try {
    dartnetConfiguration = new DartnetConfiguration(configFileName: configPath);
  } catch (e) {
    print(e);
    return;
  }

  Jaguar configuration = new Jaguar(
      multiThread: dartnetConfiguration.isMultithread,
      port: dartnetConfiguration.port,
      address: dartnetConfiguration.address,
      securityContext: dartnetConfiguration.security,
      autoCompress: dartnetConfiguration.gzip);

  configuration.addApi(new CacheHandler());
  for (String path in dartnetConfiguration.redirections.paths) {
    configuration.addApi(new PathRedirectionHandler.toUri(path, dartnetConfiguration.redirections[path]));
  }
  configuration.addApi(new PathRedirectionHandler("/", "index.html"));
  configuration.addApi(new DartnetHandler());

  dartnetConfiguration.log.warning("Start ${configuration.resourceName}");
  await configuration.serve();
}

initConfigFile({String filename: dartnetConfigurationFile}) {
  File configFile = new File(filename);

  if (configFile.existsSync() == true) {
    stderr.writeln("ERROR: File '$filename' already exist.");
  } else {
    configFile.createSync();
    DartnetConfiguration serverConfiguration = new DartnetConfiguration(configFileName: filename);

    Map config = serverConfiguration.toMap();
    config[RedirectionConfig.redirectionsKey] = {
      "${RedirectionConfig.redirectionsKey}": {"#/": '"index.html" #default behavior'},
      "#${RedirectionConfig.notFoundCodeKey}": "error.html"
    };

    config[HttpsConfig.httpsKey] = {
      "#${HttpsConfig.certKey}": "ssl/cert.pem",
      "#${HttpsConfig.keyKey}": "ssl/key.pem",
      "#${HttpsConfig.keyPasswordKey}": "<PASSWORD>"
    };

    configFile.writeAsStringSync(yamlicious.toYamlString(config));
  }
}

dockerize({String filename: dartnetConfigurationFile}) {
  File configFile = new File(filename);

  if (configFile.existsSync() == false) {
    stderr.writeln("ERROR: File '$filename' does not exist.");
  } else {
    DartnetConfiguration config = new DartnetConfiguration(configFileName: filename);
    File dockerFile = new File("Dockerfile");
    if (dockerFile.existsSync() == false) {
      dockerFile.createSync();
    }
    dockerFile.writeAsStringSync(_dockerFileContent(filename, dartnetConfiguration.rootDirectoryPath, config.port));
  }
}

String _dockerFileContent(String configFile, String rootDirectory, int port) => 'FROM google/dart\n\n'
    'RUN pub global activate dartnet\n'
    'ENV PATH \$PATH:~/.pub-cache/bin\n\n'
    'WORKDIR /dartnet\n\n'
    'RUN cp ~/.pub-cache/bin/dartnet ./\n'
    'ADD $rootDirectory /dartnet/$rootDirectory\n'
    'ADD $configFile /dartnet/\n\n'
    'EXPOSE $port\n\n'
    'ENTRYPOINT ["./dartnet", "-c", "$configFile"]';
