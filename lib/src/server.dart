library dartnet;

import 'dart:io';
import 'package:jaguar/jaguar.dart';
import 'package:yamlicious/yamlicious.dart' as yamlicious;

import 'config.dart';
import 'handler.dart';

start({String configPath: dartnetConfigurationFile}) async {
  DartnetConfiguration serverConfiguration;

  try {
    serverConfiguration = new DartnetConfiguration(configFileName: configPath);
  } catch (e) {
    print(e);
    return;
  }

  if (serverConfiguration != null) {
    Jaguar configuration = new Jaguar(
        multiThread: serverConfiguration.isMultithread,
        port: serverConfiguration.port,
        address: serverConfiguration.address,
        securityContext: serverConfiguration.security,
        autoCompress: serverConfiguration.gzip);

    configuration.addApi(new ServeRoot(serverConfiguration));
    serverConfiguration.log.warning("Start ${configuration.resourceName}");
    await configuration.serve();
  }
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
      ErrorsRedirectionConfig.errorsRedirectionsKey: {
        "#404": "404.html",
        "#500": "500.html",
      }
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
    dockerFile.writeAsStringSync(_dockerFileContent(filename, config.rootDirectory, config.port));
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















