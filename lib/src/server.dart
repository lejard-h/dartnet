library dartnet;

import 'dart:io';
import 'package:jaguar/jaguar.dart';

import 'config.dart';
import 'handler.dart';

Future<void> start({String configPath: dartnetConfigurationFile}) async {
  try {
    dartnet = new DartnetConfiguration(configFileName: configPath);
  } catch (e, s) {
    print(e);
    print(s);
    return;
  }

  final server = new Jaguar(
    multiThread: dartnet.isMultithread,
    port: dartnet.port,
    address: dartnet.address,
    securityContext: dartnet.security,
    autoCompress: dartnet.gzip,
  );

  server.get('/*', cacheHandler);

  for (final path in dartnet.redirections.paths) {
    final redirection = dartnet.redirections[path];
    server.get(
      path,
      pathRedirectionHandler(redirection),
    );
  }

  server.get('/', pathRedirectionHandler(Uri.parse('/index.html')));
  server.get('/*', dartnetHandler);

  dartnet.log.info("Start on ${dartnet.address}:${dartnet.port}");
  await server.serve();
}

void initConfigFile({String filename: dartnetConfigurationFile}) {
  File configFile = new File(filename);

  if (configFile.existsSync() == true) {
    stderr.writeln("ERROR: File '$filename' already exist.");
  } else {
    configFile.createSync(recursive: true);
    configFile.writeAsStringSync(_defaultConfig);
  }
}

void dockerize({String filename: dartnetConfigurationFile}) {
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
    dockerFile.writeAsStringSync(
      _dockerFileContent(filename, dartnet.rootDirectoryPath, config.port),
    );
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
