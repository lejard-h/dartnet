library jaguar_server;

import 'package:jaguar/jaguar.dart';

import 'config.dart';
import 'handler.dart';

start({String configPath: jaguarServerConfigurationFile}) async {
  JaguarServerConfiguration serverConfiguration = new JaguarServerConfiguration(configFileName: configPath);

  Configuration configuration = new Configuration(
      multiThread: serverConfiguration.isMultithread,
      port: serverConfiguration.port,
      address: serverConfiguration.address);

  configuration.addApi(new ServeRoot(serverConfiguration));
  serverConfiguration.log.warning("Start ${configuration.baseUrl}");
  await serve(configuration);
}
