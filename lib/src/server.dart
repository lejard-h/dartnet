library dartnet;

import 'dart:io';
import 'package:jaguar/jaguar.dart' as jaguar;

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

    jaguar.Configuration configuration = new jaguar.Configuration(
        multiThread: serverConfiguration.isMultithread,
        port: serverConfiguration.port,
        address: serverConfiguration.address,
        securityContext: security);

    configuration.addApi(new ServeRoot(serverConfiguration));
    serverConfiguration.log.warning("Start ${configuration.baseUrl}");
    await jaguar.serve(configuration);
  }
}
