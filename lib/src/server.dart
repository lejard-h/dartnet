library dartnet;

import 'dart:io';
import 'package:jaguar/jaguar.dart';
import 'package:yamlicious/yamlicious.dart' as yamlicious;

import 'config.dart';
import 'handler.dart';

start({String configPath: dartnetConfigurationFile}) async {
  DartnetConfiguration serverConfiguration;
  SecurityContext security;

  try {
    serverConfiguration = new DartnetConfiguration(configFileName: configPath);
  } catch (e) {
    print(e);
  }

  if (serverConfiguration != null) {
    if (serverConfiguration.https.isValid) {
      security = new SecurityContext()
        ..useCertificateChain(serverConfiguration.https.certPath)
        ..usePrivateKey(serverConfiguration.https.keyPath,
            password: serverConfiguration.https.passwordKey);
    }

    Jaguar configuration = new Jaguar(
        multiThread: serverConfiguration.isMultithread,
        port: serverConfiguration.port,
        address: serverConfiguration.address,
        securityContext: security,
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
      "#404": "404.html",
      "#500": "500.html",
      "#${RedirectionConfig.defaultKey}": "index.html"
    };

    config[HttpsConfig.httpsKey] = {
      "#${HttpsConfig.certKey}": "ssl/cert.pem",
      "#${HttpsConfig.keyKey}": "ssl/key.pem",
      "#${HttpsConfig.keyPasswordKey}": "<PASSWORD>"
    };

    configFile.writeAsStringSync(yamlicious.toYamlString(config));
  }
}