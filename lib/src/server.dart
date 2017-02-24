library dartnet;

import 'dart:io';
import 'package:jaguar/jaguar.dart';

import 'config.dart';
import 'handler.dart';

start({String configPath: dartnetConfigurationFile}) async {
  try {
    dartnetConfiguration = new DartnetConfiguration(configFileName: configPath);
  } catch (e, s) {
    print(e);
    print(s);
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
    configuration.addApi(new PathRedirectionHandler.toUri(
        path, dartnetConfiguration.redirections[path]));
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
    configFile.createSync(recursive: true);
    configFile.writeAsStringSync(_defaultConfig);
  }
}

dockerize({String filename: dartnetConfigurationFile}) {
  File configFile = new File(filename);

  if (configFile.existsSync() == false) {
    stderr.writeln("ERROR: File '$filename' does not exist.");
  } else {
    DartnetConfiguration config =
        new DartnetConfiguration(configFileName: filename);
    File dockerFile = new File("Dockerfile");
    if (dockerFile.existsSync() == false) {
      dockerFile.createSync();
    }
    dockerFile.writeAsStringSync(_dockerFileContent(
        filename, dartnetConfiguration.rootDirectoryPath, config.port));
  }
}

String _dockerFileContent(String configFile, String rootDirectory, int port) =>
    'FROM google/dart\n\n'
    'RUN pub global activate dartnet\n'
    'ENV PATH \$PATH:~/.pub-cache/bin\n\n'
    'WORKDIR /dartnet\n\n'
    'RUN cp ~/.pub-cache/bin/dartnet ./\n'
    'ADD $rootDirectory /dartnet/$rootDirectory\n'
    'ADD $configFile /dartnet/\n\n'
    'EXPOSE $port\n\n'
    'ENTRYPOINT ["./dartnet", "-c", "$configFile"]';

String get _defaultConfig => 'address: "0.0.0.0"\n'
    'port: 8080\n'
    'log: "INFO"\n'
    'log_file: "dartnet.log"\n'
    'root_directory: "./"\n'
    'list_directory: false\n'
    'multithread: false\n'
    'gzip: true\n'
    'redirections:\n'
    '  #404: "error.html"\n'
    '  path:\n'
    '    #/: "index.html" #default behavior\n'
    'https:\n'
    '  #cert: "ssl/cert.pem"\n'
    '  #key: "ssl/key.pem"\n'
    '  #password_key: "<PASSWORD>"\n';
